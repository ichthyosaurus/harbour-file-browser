/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022-2024 Mirian Margiani
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

#ifndef FILECLIPBOARDMODEL_H
#define FILECLIPBOARDMODEL_H

#include <QStringListModel>
#include <QByteArray>
#include <QHash>

#include "enumcontainer.h"
#include "filedata.h"

CREATE_ENUM(FileClipMode, Copy, Link, Cut)
DECLARE_ENUM_REGISTRATION_FUNCTION(FileClipboard)

class ConfigFileMonitor;
class DirectorySettings;

class PathsModel : public QStringListModel {
    Q_OBJECT

public:
    explicit PathsModel(QObject *parent = nullptr);
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;
};

class FileClipboard : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(FileClipMode::Enum mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(QStringList paths READ paths WRITE setPaths NOTIFY pathsChanged)
    Q_PROPERTY(PathsModel* pathsModel READ pathsModel CONSTANT)
    Q_DISABLE_COPY(FileClipboard)

public:
    FileClipboard(QObject* parent = nullptr);
    ~FileClipboard();

    // methods callable from QML
    Q_INVOKABLE void setPaths(const QStringList& paths, FileClipMode::Enum mode);
    void setPaths(const QStringList &newPaths);
    Q_INVOKABLE void forgetPath(QString path);
    Q_INVOKABLE void forgetIndex(int index);
    Q_INVOKABLE void validate();
    Q_INVOKABLE void appendPath(QString path);
    Q_INVOKABLE bool hasPath(QString path);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QStringList listExistingFiles(
            QString destDirectory, bool ignoreInCurrentDir = true, bool getNamesOnly = true);


    int count() const;
    FileClipMode::Enum mode() const;
    void setMode(FileClipMode::Enum newMode);
    const QStringList& paths() const;
    PathsModel* pathsModel() const;

signals:
    void countChanged();
    void modeChanged();
    void pathsChanged();

private slots:
    void reload();
    void saveToDisk();

private:
    void setPaths(const QStringList &newPaths, FileClipMode::Enum mode, bool doSave);
    QString validatePath(QString path);
    void refreshSharedState();

    int m_count {0};
    QStringList m_paths {};
    FileClipMode::Enum m_mode {FileClipMode::Copy};
    PathsModel* m_pathsModel;
    ConfigFileMonitor* m_monitor;
    DirectorySettings* m_settings = {nullptr};
};

#endif // FILECLIPBOARDMODEL_H
