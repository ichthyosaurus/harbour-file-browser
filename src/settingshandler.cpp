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

#include <QSettings>
#include "settingshandler.h"

Settings::Settings(QObject *parent) : QObject(parent) {
    QSettings global;
    m_globalConfigPath = global.fileName();
}

Settings::~Settings() {
    //
}
QVariant Settings::readVariant(const QString &key, const QVariant &defaultValue, const QString &fileName) {
    if (fileName.isEmpty()) {
        // global settings
        QSettings settings;
        return settings.value(key, defaultValue);
    } else {
        // local settings
        QSettings settings(fileName, QSettings::IniFormat);
        return settings.value(key, defaultValue);
    }
}

QString Settings::read(QString key, QString defaultValue, QString fileName) {
    return readVariant(key, defaultValue, fileName).toString();
}

void Settings::writeVariant(const QString &key, const QVariant &value, const QString &fileName) {
    if (fileName.isEmpty()) {
        // global settings
        QSettings settings;
        if (settings.value(key) == value) return;
        settings.setValue(key, value);

        emit settingsChanged();
        if (key.startsWith("View/")) {
            emit viewSettingsChanged();
        }
    } else {
        // local settings
        QSettings settings(fileName, QSettings::IniFormat);
        if (settings.value(key) == value) return;
        settings.setValue(key, value);
        emit settingsChanged();
    }
}

void Settings::write(QString key, QString value, QString fileName) {
    writeVariant(key, value, fileName);
}

void Settings::remove(QString key, QString fileName) {
    if (fileName.isEmpty()) {
        // global settings
        QSettings settings;
        settings.remove(key);

        emit settingsChanged();
        if (key.startsWith("View/")) {
            emit viewSettingsChanged();
        }
    } else {
        // local settings
        QSettings settings(fileName, QSettings::IniFormat);
        settings.remove(key);
        emit settingsChanged();
    }
}
