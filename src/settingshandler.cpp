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

Settings::Settings(QObject *parent) : QObject(parent) {
    QSettings global;
    m_globalConfigPath = global.fileName();

    if (pathIsProtected(m_globalConfigPath) || !QDir("/").mkpath(QFileInfo(m_globalConfigPath).absolutePath())) {
        // TODO we should issue a warning that global settings cannot be saved
    }
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

    if (pathIsProtected(fileName) || !isWritable(fileInfo) || !hasRuntimeSettings(fileInfo)) {
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

bool Settings::isWritable(QFileInfo fileInfo) {
    // Check whether the file is writable. If it does not exist, check if
    // its parent directory can be written to.
    // Use this method instead of plain QFileInfo::isWritable!
    if (fileInfo.exists()) {
        if (fileInfo.isFile()) {
            return fileInfo.isWritable();
        } else {
            return false;
        }
    } else {
        return QFileInfo(fileInfo.absolutePath()).isWritable();
    }
}

QVariant Settings::readVariant(QString key, const QVariant &defaultValue, QString fileName) {
    sanitizeKey(key);
    if (fileName.isEmpty()) fileName = m_globalConfigPath;
    QFileInfo fileInfo = QFileInfo(fileName);

    if (!fileInfo.exists() || !fileInfo.isReadable() || pathIsProtected(fileName)) {
        QMutexLocker locker(&m_mutex);
        if (getRuntimeSettings(fileInfo).contains(key)) {
            return getRuntimeSettings(fileInfo)[key];
        }

        return defaultValue;
    }

    flushRuntimeSettings(fileName);
    QSettings settings(fileName, QSettings::IniFormat);
    return settings.value(key, defaultValue);
}

QString Settings::read(QString key, QString defaultValue, QString fileName) {
    return readVariant(key, defaultValue, fileName).toString();
}

void Settings::writeVariant(QString key, const QVariant &value, QString fileName) {
    sanitizeKey(key);
    bool usingLocalConfig = true;

    if (fileName.isEmpty()) {
        fileName = m_globalConfigPath;
        usingLocalConfig = false;
    }

    QFileInfo fileInfo = QFileInfo(fileName);

    if (pathIsProtected(fileName) || !isWritable(fileInfo)) {
        QMutexLocker locker(&m_mutex);
        getRuntimeSettings(fileInfo)[key] = value;
    } else {
        flushRuntimeSettings(fileName);
        QSettings settings(fileName, QSettings::IniFormat);
        if (settings.value(key) == value) return;
        settings.setValue(key, value);
    }

    emit settingsChanged();
    if (fileName != m_globalConfigPath || key.startsWith("View/")) {
        emit viewSettingsChanged(usingLocalConfig ? fileInfo.dir().absolutePath() : "");
    }
}

void Settings::sanitizeKey(QString& key) {
    // Replace all but the first occurrence of '/' by '#',
    // so '/' can appear without being treated as divider for sub-groups.
    // This is needed for saving paths as keys (eg. for bookmarks).

    if (key.indexOf('/') == -1) return;
    int pos = key.indexOf('/');
    key.replace(pos, 1, '&');
    key.replace('/', '#');
    key.replace(pos, 1, '/');
}

void Settings::write(QString key, QString value, QString fileName) {
    writeVariant(key, value, fileName);
}

void Settings::remove(QString key, QString fileName) {
    sanitizeKey(key);
    bool usingLocalConfig = true;
    if (fileName.isEmpty()) {
        fileName = m_globalConfigPath;
        usingLocalConfig = false;
    }

    QFileInfo fileInfo = QFileInfo(fileName);

    if (pathIsProtected(fileName) || !isWritable(fileInfo)) {
        QMutexLocker locker(&m_mutex);
        getRuntimeSettings(fileInfo).remove(key);
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

QStringList Settings::keys(QString group, QString fileName) {
    if (fileName.isEmpty()) fileName = m_globalConfigPath;
    QFileInfo fileInfo = QFileInfo(fileName);
    QStringList keys;

    if (!fileInfo.exists() || !fileInfo.isReadable() || pathIsProtected(fileName)) {
        QMutexLocker locker(&m_mutex);
        keys = getRuntimeSettings(fileInfo).uniqueKeys();
    } else {
        flushRuntimeSettings(fileName);
        QSettings settings(fileName, QSettings::IniFormat);
        if (!group.isEmpty()) settings.beginGroup(group);
        keys = settings.allKeys();
    }

    for (int i = 0; i < keys.length(); i++) {
        // Un-sanitize keys. FIXME: this is a dirty hack.
        keys[i] = keys[i].replace('#', '/');
    }

    return keys;
}
