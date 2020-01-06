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

#ifndef SETTINGSHANDLER_H
#define SETTINGSHANDLER_H

#include <QString>
#include <QSettings>

class Settings : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE QString read(QString key, QString defaultValue, QString fileName);
    Q_INVOKABLE QString read(QString key, QString defaultValue = QString());
    Q_INVOKABLE void write(QString key, QString value, QString fileName);
    Q_INVOKABLE void write(QString key, QString value);
    Q_INVOKABLE void remove(QString key, QString fileName);
    Q_INVOKABLE void remove(QString key);

signals:
    void settingsChanged();
    void viewSettingsChanged();
};

#endif // SETTINGSHANDLER_H
