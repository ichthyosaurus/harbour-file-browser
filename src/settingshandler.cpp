/*
 * This file is part of File Browser.
 * Copyright (C) 2020  Mirian Margiani
 *
 * This part of File Browser is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * File Browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with File Browser.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <QMutexLocker>
#include <QSettings>
#include <QDir>
#include <QFileInfo>
#include "settingshandler.h"

#include <QDebug>

Settings::Settings(QObject *parent) : QObject(parent) {
    QSettings global;
    m_globalConfigPath = global.fileName();
}

Settings::~Settings() {
    //
}

bool Settings::pathIsProtected(QString path) const {
    QString absolutePath = QFileInfo(path).absoluteFilePath();

    if (   absolutePath.startsWith(QDir::home().absolutePath()) /* user's home directory */
        || absolutePath.startsWith(QString("/run/media/") +
                                   QDir::home().dirName()) /* below /run/media/USER */
       ) {
        return false; // unprotected
    }

    return true; // protected
}

void Settings::flushRuntimeSettings(QString fileName) {
    QFileInfo fileInfo = QFileInfo(fileName);
    QMutexLocker locker(&m_mutex);

    if (pathIsProtected(fileName) || !QFileInfo(fileName).isWritable() || !hasRuntimeSettings(fileInfo)) {
        return;
    }

    QMap<QString, QVariant> data = getRuntimeSettings(fileInfo);
    m_runtimeSettings.remove(fileInfo.absoluteFilePath());
    locker.unlock();

    QSettings settings(fileName, QSettings::IniFormat);

    for (QString key : data.keys()) {
        QVariant value = data[key];

        if (settings.value(key) == value) continue;
        settings.setValue(key, value);
    }
}

bool Settings::hasRuntimeSettings(QFileInfo file) {
    return m_runtimeSettings.contains(file.absoluteFilePath());
}

QMap<QString, QVariant>& Settings::getRuntimeSettings(QFileInfo file) {
    return m_runtimeSettings[file.absoluteFilePath()];
}

QVariant Settings::readVariant(const QString &key, const QVariant &defaultValue, const QString &fileName) {
    QString usedFile = fileName;
    if (fileName.isEmpty()) usedFile = m_globalConfigPath;
    QFileInfo fileInfo = QFileInfo(usedFile);

    if (!fileInfo.exists() || !fileInfo.isReadable() || pathIsProtected(usedFile)) {
        QMutexLocker locker(&m_mutex);
        qDebug() << "read runtime" << key;
        if (getRuntimeSettings(fileInfo).contains(key)) {
            return getRuntimeSettings(fileInfo)[key];
        }

        return defaultValue;
    }

    flushRuntimeSettings(usedFile);
    QSettings settings(usedFile, QSettings::IniFormat);
    return settings.value(key, defaultValue);
}

QString Settings::read(QString key, QString defaultValue, QString fileName) {
    return readVariant(key, defaultValue, fileName).toString();
}

void Settings::writeVariant(const QString &key, const QVariant &value, const QString &fileName) {
    QString usedFile = fileName;
    bool usingLocalConfig = true;

    if (fileName.isEmpty()) {
        usedFile = m_globalConfigPath;
        usingLocalConfig = false;
    }

    QFileInfo fileInfo = QFileInfo(usedFile);

    if (pathIsProtected(usedFile) || !fileInfo.isWritable()) {
        QMutexLocker locker(&m_mutex);
        getRuntimeSettings(fileInfo)[key] = value;
        qDebug() << "write runtime" << key;
    } else {
        flushRuntimeSettings(usedFile);
        QSettings settings(usedFile, QSettings::IniFormat);
        if (settings.value(key) == value) return;
        settings.setValue(key, value);
    }

    emit settingsChanged();
    if (usedFile != m_globalConfigPath || key.startsWith("View/")) {
        emit viewSettingsChanged(usingLocalConfig ? fileInfo.dir().absolutePath() : "");
    }
}

void Settings::write(QString key, QString value, QString fileName) {
    writeVariant(key, value, fileName);
}

void Settings::remove(QString key, QString fileName) {
    bool usingLocalConfig = true;
    if (fileName.isEmpty()) {
        fileName = m_globalConfigPath;
        usingLocalConfig = false;
    }

    QFileInfo fileInfo = QFileInfo(fileName);

    if (pathIsProtected(fileName) || !fileInfo.isWritable()) {
        QMutexLocker locker(&m_mutex);
        getRuntimeSettings(fileInfo).remove(key);
        qDebug() << "remove runtime" << key;
    } else {
        flushRuntimeSettings(fileName);
        QSettings settings(fileName, QSettings::IniFormat);
        settings.remove(key);
    }

    emit settingsChanged();
    if (usingLocalConfig || key.startsWith("View/")) {
        emit viewSettingsChanged(usingLocalConfig ? fileInfo.dir().absolutePath() : "");
    }
}
