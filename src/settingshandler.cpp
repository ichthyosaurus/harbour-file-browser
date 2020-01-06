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

#include "settingshandler.h"

QString Settings::readSetting(QString key, QString defaultValue, QString fileName) {
    QSettings settings(fileName, QSettings::IniFormat);
    return settings.value(key, defaultValue).toString();
}

QString Settings::readSetting(QString key, QString defaultValue) {
    QSettings settings;
    return settings.value(key, defaultValue).toString();
}

void Settings::writeSetting(QString key, QString value, QString fileName) {
    QSettings settings(fileName, QSettings::IniFormat);
    if (settings.value(key) == value) return;
    settings.setValue(key, value);
    emit settingsChanged();
}

void Settings::writeSetting(QString key, QString value) {
    QSettings settings;
    if (settings.value(key) == value) return;
    settings.setValue(key, value);

    emit settingsChanged();
    if (key.startsWith("View/")) {
        emit viewSettingsChanged();
    }
}

void Settings::removeSetting(QString key, QString fileName) {
    QSettings settings(fileName, QSettings::IniFormat);
    settings.remove(key);
    emit settingsChanged();
}

void Settings::removeSetting(QString key) {
    QSettings settings;
    settings.remove(key);

    emit settingsChanged();
    if (key.startsWith("View/")) {
        emit viewSettingsChanged();
    }
}
