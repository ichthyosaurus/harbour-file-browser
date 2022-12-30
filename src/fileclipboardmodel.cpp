/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
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

#include <QDebug>
#include "fileclipboardmodel.h"
#include "statfileinfo.h"

DEFINE_ENUM_REGISTRATION_FUNCTION(FileClipboard) {
    REGISTER_ENUM_CONTAINER(FileClipMode)
}

enum {
    ModeRole =            Qt::UserRole +  1,
    PathsRole =           Qt::UserRole +  2,
    CountRole =           Qt::UserRole +  3,
    PathsModelRole =      Qt::UserRole +  4,
};

enum {
    FullPathRole =        Qt::DisplayRole,
    DirRole =             Qt::UserRole + 10,
};

FileClipboardModel::FileClipboardModel(QObject *parent) :
    QAbstractListModel(parent), m_currentPathsModel(new PathsModel(this))
{
    connect(this, &FileClipboardModel::currentPathsChanged, this, [&](){
        m_currentPathsModel->setStringList(currentPaths());
        emit currentPathsModelChanged();
    });
}

FileClipboardModel::~FileClipboardModel()
{
    //
}

int FileClipboardModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_historyCount;
}

QVariant FileClipboardModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= rowCount()) {
        return QVariant();
    }

    const auto& entry = m_entries.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
    case CountRole:
        return entry.count();

    case ModeRole:
        return entry.mode();

    case PathsRole:
        return entry.paths();

    case PathsModelRole:
        return QVariant::fromValue(entry.pathsModel().data());

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FileClipboardModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(CountRole, QByteArray("count"));
    roles.insert(ModeRole, QByteArray("mode"));
    roles.insert(PathsRole, QByteArray("paths"));
    roles.insert(PathsModelRole, QByteArray("pathsModel"));
    return roles;
}

int FileClipboardModel::currentCount() const
{
    if (m_historyCount > 0) return m_entries.at(0).count();
    else return 0;
}

FileClipMode::Enum FileClipboardModel::currentMode() const
{
    if (m_historyCount > 0) return m_entries.at(0).mode();
    else return FileClipMode::Copy;
}

void FileClipboardModel::setCurrentMode(FileClipMode::Enum newCurrentMode)
{
    if (m_historyCount == 0) return;
    auto& current = m_entries[0];

    if (current.mode() == newCurrentMode) {
        return;
    } else {
        if (current.setMode(newCurrentMode)) {
            QModelIndex topLeft = index(0, 0);
            QModelIndex bottomRight = index(0, 0);
            emit dataChanged(topLeft, bottomRight, {ModeRole});
        }

        emit currentModeChanged();
    }
}

const QStringList &FileClipboardModel::currentPaths() const
{
    if (m_historyCount > 0) return m_entries.at(0).paths();
    else return m_emptyList;
}

void FileClipboardModel::setCurrentPaths(QStringList newPaths)
{
    // - if the current clipboard is empty, insert paths there
    // - otherwise, create a new group and push it onto the stack
    if (m_historyCount > 0 && m_entries[0].count() == 0) {
        qDebug() << "updating current group" << newPaths;
        m_entries[0].setEntries(newPaths);
        QModelIndex topLeft = index(0, 0);
        QModelIndex bottomRight = index(0, 0);
        emit dataChanged(topLeft, bottomRight, {PathsRole, CountRole});
    } else {
        beginInsertRows(QModelIndex(), 0, 0);
        qDebug() << "adding new group" << newPaths;
        m_entries.prepend(ClipboardGroup());
        m_entries[0].setEntries(newPaths);
        m_historyCount++;
        endInsertRows();

        emit historyCountChanged();
    }

    emit currentCountChanged();
    emit currentPathsChanged();
}

void FileClipboardModel::forgetPath(int groupIndex, QString path)
{
    if (groupIndex >= m_historyCount) return;

    if (m_entries[groupIndex].forgetEntry(path)) {
        QModelIndex topLeft = index(groupIndex, 0);
        QModelIndex bottomRight = index(groupIndex, 0);
        emit dataChanged(topLeft, bottomRight, {PathsRole, CountRole});

        if (groupIndex == 0) {
            emit currentCountChanged();
            emit currentPathsChanged();
        }
    }
}

void FileClipboardModel::appendPath(int groupIndex, QString path)
{
    if (groupIndex >= m_historyCount) return;

    if (m_entries[groupIndex].appendEntry(path)) {
        QModelIndex topLeft = index(groupIndex, 0);
        QModelIndex bottomRight = index(groupIndex, 0);
        emit dataChanged(topLeft, bottomRight, {PathsRole, CountRole});

        if (groupIndex == 0) {
            emit currentCountChanged();
            emit currentPathsChanged();
        }
    }
}

bool FileClipboardModel::isPathInGroup(int groupIndex, QString path)
{
    if (groupIndex >= m_historyCount) return false;
    return m_entries[groupIndex].paths().contains(path);
}

void FileClipboardModel::forgetGroup(int groupIndex)
{
    if (groupIndex >= m_historyCount) return;

    beginRemoveRows(QModelIndex(), groupIndex, groupIndex);
    m_entries.removeAt(groupIndex);
    m_historyCount--;
    endRemoveRows();

    emit historyCountChanged();

    if (groupIndex == 0) {
        emit currentCountChanged();
        emit currentModeChanged();
        emit currentPathsChanged();
    }
}

void FileClipboardModel::selectGroup(int groupIndex, FileClipMode::Enum mode)
{
    if (groupIndex >= m_historyCount) return;

    const auto& oldGroup = m_entries.at(groupIndex);

    if (m_historyCount > 0 && m_entries[0].count() == 0) {
        // current selection is empty - copy everything into the current selection
        m_entries[0].setEntries(oldGroup.paths());
        m_entries[0].setMode(mode);

        QModelIndex topLeft = index(0, 0);
        QModelIndex bottomRight = index(0, 0);
        emit dataChanged(topLeft, bottomRight, {PathsRole, CountRole, ModeRole});
    } else {
        // current selection is not empty - push a new group onto the stack
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(ClipboardGroup());
        m_entries[0].setEntries(oldGroup.paths());
        m_entries[0].setMode(mode);
        groupIndex++; // we added an entry at the front, so the old group gets pushed to the back
        m_historyCount++;
        endInsertRows();
    }

    beginRemoveRows(QModelIndex(), groupIndex, groupIndex);
    m_entries.removeAt(groupIndex);
    m_historyCount--;
    endRemoveRows();

    emit historyCountChanged();
    emit currentCountChanged();
    emit currentModeChanged();
    emit currentPathsChanged();
}

void FileClipboardModel::clearCurrent()
{
    // Instead of actually clearing the contents of the current group,
    // we insert an emtpy group that becomes the current selection,
    // thus pushing the previously selected group into the history list.
    beginInsertRows(QModelIndex(), 0, 0);
    m_entries.prepend(ClipboardGroup());
    m_historyCount++;
    endInsertRows();

    emit historyCountChanged();
    emit currentCountChanged();
    emit currentModeChanged();
    emit currentPathsChanged();
}

QStringList FileClipboardModel::listExistingFiles(QString destDirectory, bool ignoreInCurrentDir, bool getNamesOnly)
{
    const QStringList& currentFiles = currentPaths();

    if (currentFiles.isEmpty()) {
        return QStringList();
    }

    QDir destination(destDirectory);
    if (!destination.exists()) {
        return QStringList();
    }

    QStringList existingFiles;

    for (const auto& path : currentFiles) {
        QFileInfo fileInfo(path);
        QString newPath = destination.absoluteFilePath(fileInfo.fileName());

        // Are source and destination paths the same?
        // Note: Engine::pasteFiles() can create numbered copies.
        if (ignoreInCurrentDir && newPath == fileInfo.absoluteFilePath()) {
            continue;
        }

        // Is the destination directory inside the source directory?
        // Note: Engine::pasteFiles() will return an error.
        // FIXME: this is actually a safe operation and must be fixed in Engine::pasteFiles().
        if (fileInfo.isDir() && (newPath + QStringLiteral("/")).startsWith((path + QStringLiteral("/")))) {
            return QStringList();
        }

        if (QFile::exists(newPath)) {
            if (getNamesOnly) {
                existingFiles.append(fileInfo.fileName());
            } else {
                existingFiles.append(path);
            }
        }
    }

    return existingFiles;
}

void FileClipboardModel::clearAll()
{
    beginResetModel();
    m_historyCount = 0;
    emit historyCountChanged();
    m_entries.clear();
    endResetModel();
}

bool FileClipboardModel::ClipboardGroup::forgetEntry(int index)
{
    if (index >= m_count) return false;

    m_paths.removeAt(index);
    m_pathsModel->removeRow(index);
    m_count--;
    return true;
}

bool FileClipboardModel::ClipboardGroup::forgetEntry(QString path)
{
    int removed = m_paths.removeAll(path);
    m_count -= removed;

    if (removed > 0) {
        m_pathsModel->setStringList(m_paths);
        return true;
    }

    return false;
}

bool FileClipboardModel::ClipboardGroup::appendEntry(QString path)
{
    QString validated = validatePath(path);

    if (validated.isEmpty() || m_paths.contains(validated)) {
        return false;
    }

    m_paths.append(validated);
    m_pathsModel->setStringList(m_paths);
    m_count++;
    return true;
}

bool FileClipboardModel::ClipboardGroup::setEntries(const QStringList& paths)
{
    QStringList newPaths;
    newPaths.reserve(paths.length());

    for (auto& i : paths) {
        auto validated = validatePath(i);

        if (!validated.isEmpty()) {
            newPaths.append(i);
        }
    }

    newPaths.removeDuplicates();

    if (m_count != newPaths.length() || m_paths != newPaths) {
        m_paths = newPaths;
        m_count = newPaths.length();
        m_pathsModel->setStringList(m_paths);
        return true;
    }
    return false;
}

FileClipMode::Enum FileClipboardModel::ClipboardGroup::mode() const
{
    return m_mode;
}

bool FileClipboardModel::ClipboardGroup::setMode(FileClipMode::Enum newMode)
{
    if (newMode != m_mode) {
        m_mode = newMode;
        return true;
    }
    return false;
}

QString FileClipboardModel::ClipboardGroup::validatePath(QString path)
{
    // - never allow special files (char/block/fifo/socket) in the clipboard
    // - never allow non-existent files
    // - make sure all paths are absolute
    // - note: duplicates are not allowed but are not checked by this method

    StatFileInfo info(path);

    if (info.isSystem()) {
        qDebug() << "cannot put special files in the clipboard:" << path;
        return QLatin1Literal();
    } else if (!info.exists()) {
        qDebug() << "cannot put non-existent files in the clipboard:" << path;
        return QLatin1Literal();
    } else {
        return info.absoluteFilePath();
    }
}

FileClipboard::FileClipboard(QObject* parent)
    : QObject(parent), m_model(new FileClipboardModel(this))
{
    connect(m_model, &FileClipboardModel::currentCountChanged, this, &FileClipboard::countChanged);
    connect(m_model, &FileClipboardModel::currentModeChanged, this, &FileClipboard::modeChanged);
    connect(m_model, &FileClipboardModel::currentPathsChanged, this, &FileClipboard::pathsChanged);
}

FileClipboard::~FileClipboard()
{
    //
}

void FileClipboard::forgetPath(QString path)
{
    m_model->forgetPath(0, path);
}

void FileClipboard::appendPath(QString path)
{
    m_model->appendPath(0, path);
}

bool FileClipboard::isInCurrentSelection(QString path)
{
    return m_model->isPathInGroup(0, path);
}

void FileClipboard::clear()
{
    m_model->clearCurrent();
}

QStringList FileClipboard::listExistingFiles(QString destDirectory, bool ignoreInCurrentDir, bool getNamesOnly)
{
    return m_model->listExistingFiles(destDirectory, ignoreInCurrentDir, getNamesOnly);
}

FileClipboardModel* FileClipboard::model() const
{
    return m_model;
}

int FileClipboard::count() const
{
    return m_model->currentCount();
}

FileClipMode::Enum FileClipboard::mode() const
{
    return m_model->currentMode();
}

void FileClipboard::setMode(FileClipMode::Enum newMode)
{
    m_model->setCurrentMode(newMode);
}

const QStringList &FileClipboard::paths() const
{
    return m_model->currentPaths();
}

void FileClipboard::setPaths(const QStringList &newPaths)
{
    m_model->setCurrentPaths(newPaths);
}

PathsModel::PathsModel(QObject* parent) : QStringListModel(parent)
{
    connect(this, &PathsModel::dataChanged, this, [&](const QModelIndex& topLeft,
                                                      const QModelIndex& bottomRight,
                                                      const QVector<int>& roles){
        Q_UNUSED(roles)
        emit dataChanged(topLeft, bottomRight, {DirRole});
    });
}

QVariant PathsModel::data(const QModelIndex &index, int role) const
{
    const auto& entry = QStringListModel::data(index, Qt::DisplayRole);
    if (!entry.isValid()) return entry;

    switch (role) {
    case Qt::DisplayRole:
        return entry.toString();

    case DirRole:
        return QFileInfo(entry.toString()).path();

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PathsModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(FullPathRole, QByteArray("path"));
    roles.insert(DirRole, QByteArray("directory"));
    return roles;
}
