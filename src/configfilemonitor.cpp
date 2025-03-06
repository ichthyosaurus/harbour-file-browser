/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2023 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "configfilemonitor.h"

#include <QDebug>
#include <QFileSystemWatcher>
#include <QFile>
#include <QFileInfo>

#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>


/***********************************************************************
 * Private class
 ***********************************************************************/

class ConfigFileMonitorPrivate {
    Q_DISABLE_COPY(ConfigFileMonitorPrivate)
    Q_DECLARE_PUBLIC(ConfigFileMonitor)
    ConfigFileMonitor* const q_ptr;

public:
    ConfigFileMonitorPrivate(ConfigFileMonitor* q);
    ~ConfigFileMonitorPrivate();

public slots:
    void handleFilesystemEvent(bool notify = true);
    void clearWatcherPaths();

public:
    QString m_file {};
    QString m_parentDir {};
    ConfigFileMonitor::ConfigFileMonitorOptions m_options {0};
    QFileSystemWatcher m_watcher;

    const int m_defaultMaximumFileSize {200*1024};     // 200 KiB: no noticable delay when loading
    const int m_absoluteMaximumFileSize {1*1024*1024}; //   1 MiB: annoying delay when loading
    int m_maximumFileSize {m_defaultMaximumFileSize};
};


/***********************************************************************
 * Implementation
 ***********************************************************************/

ConfigFileMonitorPrivate::ConfigFileMonitorPrivate(ConfigFileMonitor* q) :
    q_ptr(q), m_watcher(q)
{
    //
}

ConfigFileMonitorPrivate::~ConfigFileMonitorPrivate()
{
    //
}

void ConfigFileMonitorPrivate::handleFilesystemEvent(bool notify)
{
    qDebug() << "checking monitored config file:" << m_file
             << ", blocked:" << m_watcher.signalsBlocked()
             << ", notify:" << notify
             << ", files:" << m_watcher.files()
             << ", dirs:" << m_watcher.directories();

    if (QFile::exists(m_file)) {
        // config file exists
        // -> watch it for changes
        // -> notify

        if (!m_watcher.files().contains(m_file)) {
            clearWatcherPaths();
            qDebug() << "-> switching to watch file";

            if (!m_watcher.addPath(m_file)) {
                qWarning() << "failed to watch config file for changes at" << m_file;
                qWarning() << "data might be lost when using multiple app windows";
            }
        }

        if (notify) {
            // notify, then wait for changes
            emit q_ptr->configChanged();
        }
    } else {
        // config file does not exist:
        // -> watch directory to catch when the file is created
        // -> then watch it for changes when this method gets called again

        if (!m_watcher.directories().contains(m_parentDir)) {
            clearWatcherPaths();
            qDebug() << "-> switching to watch directory";

            if (!m_watcher.addPath(m_parentDir)) {
                qWarning() << "failed to watch config directory for changes at" << m_parentDir;
                qWarning() << "data might be lost when using multiple app windows";
            }
        }

        if (m_options.testFlag(ConfigFileMonitor::NotifyWhenRemoved)) {
            if (notify) {
                emit q_ptr->configChanged();
            }
        } else {
            // abort and wait for changes, there is nothing to notify yet
            return;
        }
    }
}

void ConfigFileMonitorPrivate::clearWatcherPaths()
{
    const auto& dirs = m_watcher.directories();
    if (!dirs.isEmpty()) {
        m_watcher.removePaths(dirs);
    }

    const auto& files = m_watcher.files();
    if (!files.isEmpty()) {
        m_watcher.removePaths(files);
    }
}

ConfigFileMonitor::ConfigFileMonitor(QObject* parent) :
    QObject(parent),
    d_ptr(new ConfigFileMonitorPrivate(this))
{
    //
}

ConfigFileMonitor::~ConfigFileMonitor()
{
    //
}

void ConfigFileMonitor::reset(const QString& configFile, const ConfigFileMonitorOptions& options, int maximumSize)
{
    Q_D(ConfigFileMonitor);
    auto info = QFileInfo(configFile);

    if (configFile.isEmpty() || info.filePath().isEmpty()) {
        // abort without setting up any connections
        qWarning() << "cannot monitor invalid path" << configFile;
        d->clearWatcherPaths();
        return;
    }

    if (maximumSize > 0 && maximumSize < d->m_absoluteMaximumFileSize) {
        d->m_maximumFileSize = maximumSize;
    } else {
        d->m_maximumFileSize = d->m_defaultMaximumFileSize;
    }

    d->m_file = info.absoluteFilePath();
    d->m_parentDir = info.absolutePath();
    d->m_options = options;

    if (options.testFlag(ConfigFileMonitor::InitiallyPaused)) {
        pause();
    } else {
        d->m_watcher.blockSignals(false);
    }

    d->m_watcher.disconnect();
    connect(&d->m_watcher, &QFileSystemWatcher::fileChanged,
            this, [&](){
        Q_D(ConfigFileMonitor);
        d->handleFilesystemEvent();
    });
    connect(&d->m_watcher, &QFileSystemWatcher::directoryChanged,
            this, [&](){
        Q_D(ConfigFileMonitor);
        d->handleFilesystemEvent();
    });

    if (!options.testFlag(ConfigFileMonitor::InitiallyPaused)) {
        d->handleFilesystemEvent();
    }
}

QString ConfigFileMonitor::file() const
{
    Q_D(const ConfigFileMonitor);
    return d->m_file;
}

bool ConfigFileMonitor::fileExists() const
{
    Q_D(const ConfigFileMonitor);
    return !d->m_file.isEmpty() && QFileInfo::exists(d->m_file);
}

ConfigFileMonitor::ConfigFileMonitorOptions ConfigFileMonitor::options() const
{
    Q_D(const ConfigFileMonitor);
    return d->m_options;
}

bool ConfigFileMonitor::isRunning() const
{
    Q_D(const ConfigFileMonitor);
    return d->m_watcher.signalsBlocked();
}

QString ConfigFileMonitor::readFile(ReadErrorState& state) const
{
    Q_D(const ConfigFileMonitor);

    if (d->m_file.isEmpty()) {
        state = ReadErrorState::FileNotDefined;
        qDebug() << "cannot read file without filename";
        return {};
    }

    QFile file(d->m_file);

    if (!file.exists()) {
        state = ReadErrorState::FileNotFound;
        qDebug() << "config file" << d->m_file << "not found";
        return {};
    }

    if (!file.open(QFile::ReadOnly)) {
        qWarning() << "cannot open config file at" << d->m_file;
        state = ReadErrorState::FailedToOpen;
        return {};
    }

    if (file.size() > d->m_maximumFileSize) {
        qWarning() << "config file at" << d->m_file << "is unreasonably large:" <<
                      file.size() / 1024 << "KiB, maximum is" << d->m_maximumFileSize / 1024 << "KiB";
        state = ReadErrorState::FileTooLarge;
        return {};
    }

    QTextStream stream(&file);
    QString read = file.readAll();
    file.close();

    state = ReadErrorState::NoError;
    return read;
}

QString ConfigFileMonitor::readFile() const
{
    ReadErrorState state;
    return readFile(state);
}

int ConfigFileMonitor::maximumFileSize() const
{
    Q_D(const ConfigFileMonitor);
    return d->m_maximumFileSize;
}

QJsonValue ConfigFileMonitor::readJson(QString expectedVersion, QJsonValue fallback) const
{
    Q_D(const ConfigFileMonitor);

    std::string configString = readFile().toStdString();
    auto doc = QJsonDocument::fromJson(QByteArray::fromStdString(configString));

    if (!doc.isObject()) {
        qDebug() << "failed to load config file: not a JSON object" << d->m_file;
        return fallback;
    }

    const auto obj = doc.object();
    QString version = obj.value(QStringLiteral("version")).toString(QLatin1Literal(""));
    const auto data = obj.value(QStringLiteral("data"));

    if (version != expectedVersion) {
        qWarning() << "unsupported config file version in" << d->m_file << version;
        return fallback;
    }

    return data;
}

bool ConfigFileMonitor::writeJson(QJsonValue data, QString version)
{
    Q_D(ConfigFileMonitor);

    ConfigFileMonitorBlocker blocker(this);

    qDebug() << "saving config file" << d->m_file;
    QSaveFile outFile(d->m_file);

    if (!outFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Unbuffered)) {
        qWarning() << "failed to open a temporary file for saving configuration to" << d->m_file;
        qWarning() << "dataloss is possible!";
        return false;
    }

    QJsonDocument doc;
    QJsonObject obj;

    obj.insert(QStringLiteral("version"), version);
    obj.insert(QStringLiteral("data"), data);

    doc.setObject(obj);
    outFile.write(doc.toJson(QJsonDocument::Indented));

    if (!outFile.commit()) {
        qWarning() << "failed to save config to" << d->m_file;
        qWarning() << "dataloss is possible!";
        return false;
    }

    qDebug() << "config saved to" << d->m_file;
    return true;
}

void ConfigFileMonitor::pause()
{
    Q_D(ConfigFileMonitor);
    qDebug() << "pausing monitor for" << d->m_file;
    d->m_watcher.blockSignals(true);
    d->clearWatcherPaths();
}

void ConfigFileMonitor::resume()
{
    Q_D(ConfigFileMonitor);

    if (d->m_file.isEmpty()) {
        qWarning() << "cannot resume without being initialized with a valid file";
        pause();
        return;
    } else if (!d->m_watcher.signalsBlocked()) {
        qDebug() << "cannot resume without being paused";
        return;
    }

    qDebug() << "resuming monitor for" << d->m_file;
    d->handleFilesystemEvent(false);
    d->m_watcher.blockSignals(false);
}

void ConfigFileMonitor::setRunning(bool running)
{
    if (running == isRunning()) {
        return;
    }

    if (running) {
        resume();
    } else {
        pause();
    }
}

/***********************************************************************
 * Blocker implementation
 ***********************************************************************/

ConfigFileMonitorBlocker::ConfigFileMonitorBlocker(ConfigFileMonitor* monitor) noexcept :
    m_monitor(monitor)
{
    if (m_monitor) {
        m_monitor->pause();
        qDebug() << "blocker started for" << m_monitor->file();
    } else {
        qDebug() << "blocker created for invalid monitor";
    }
}

ConfigFileMonitorBlocker::~ConfigFileMonitorBlocker()
{
    if (m_monitor) {
        m_monitor->resume();
        qDebug() << "blocker finished for" << m_monitor->file() << ", resuming";
    } else {
        qDebug() << "blocker finished for invalid monitor";
    }
}
