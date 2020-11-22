/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * File Browser is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * File Browser is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef SETTINGSHANDLER_H
#define SETTINGSHANDLER_H

#include <QVariant>
#include <QMap>
#include <QString>
#include <QMutex>

class QFileInfo;

class Settings : public QObject
{
    Q_OBJECT

public:
    explicit Settings(QObject *parent = nullptr);
    ~Settings();

    Q_INVOKABLE bool pathIsProtected(QString path) const;
    Q_INVOKABLE QString read(QString key, QString defaultValue = QString(), QString fileName = QString());
    Q_INVOKABLE void write(QString key, QString value, QString fileName = QString());
    Q_INVOKABLE void remove(QString key, QString fileName = QString());
    Q_INVOKABLE QStringList keys(QString group = QString(), QString fileName = QString());

    QVariant readVariant(QString key, const QVariant& defaultValue = QVariant(), QString fileName = QString());
    void writeVariant(QString key, const QVariant& value, QString fileName = QString());

signals:
    void settingsChanged(QString key, bool locally);
    void viewSettingsChanged(QString localPath);

private:
    void sanitizeKey(QString& key);
    void flushRuntimeSettings(QString fileName);
    bool hasRuntimeSettings(QFileInfo file);
    QMap<QString, QVariant>& getRuntimeSettings(QFileInfo file);
    bool isWritable(QFileInfo file);

    // in-memory settings to be used when local settings are not available
    // It is a QMap of QMap, combining file paths with their local settings QMaps.
    QMap<QString, QMap<QString, QVariant>> m_runtimeSettings;
    QString m_globalConfigPath;
    QMutex m_mutex;
};

#endif // SETTINGSHANDLER_H
