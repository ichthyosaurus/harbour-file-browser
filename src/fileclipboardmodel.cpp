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
};

FileClipboardModel::FileClipboardModel(QObject *parent) :
    QAbstractListModel(parent)
{
    //
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
    // - never allow special files (char/block/fifo/socket) in the clipboard
    // - never allow non-existent files
    // - make sure all paths are absolute
    QMutableStringListIterator iter(newPaths);

    while (iter.hasNext()) {
        StatFileInfo info(iter.next());

        if (info.isSystem()) {
            qDebug() << "cannot put special files in the clipboard:" << iter.value();
            iter.remove();
        } else if (!info.exists()) {
            qDebug() << "cannot put non-existent files in the clipboard:" << iter.value();
            iter.remove();
        } else {
            iter.setValue(info.absoluteFilePath());
        }
    }

    // - if the current clipboard is empty, insert paths there
    // - otherwise, create a new group and push it onto the stack
    if (m_historyCount > 0 && m_entries[0].count() == 0) {
        m_entries[0].setEntries(newPaths);

        QModelIndex topLeft = index(0, 0);
        QModelIndex bottomRight = index(0, 0);
        emit dataChanged(topLeft, bottomRight, {PathsRole, CountRole});
    } else {
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(ClipboardGroup());
        m_entries[0].setEntries(newPaths);
        m_historyCount++;
        qDebug() << "added new group" << newPaths;
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

void FileClipboardModel::selectGroup(int groupIndex)
{
    if (groupIndex >= m_historyCount) return;

    const auto& oldGroup = m_entries.at(groupIndex);

    if (m_historyCount > 0 && m_entries[0].count() == 0) {
        // current selection is empty - copy everything into the current selection
        m_entries[0].setEntries(oldGroup.paths());
        m_entries[0].setMode(oldGroup.mode());

        QModelIndex topLeft = index(0, 0);
        QModelIndex bottomRight = index(0, 0);
        emit dataChanged(topLeft, bottomRight, {PathsRole, CountRole, ModeRole});
    } else {
        // current selection is not empty - push a new group onto the stack
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(ClipboardGroup());
        m_entries[0].setEntries(oldGroup.paths());
        m_entries[0].setMode(oldGroup.mode());
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
    m_count--;
    return true;
}

bool FileClipboardModel::ClipboardGroup::forgetEntry(QString path)
{
    int removed = m_paths.removeAll(path);
    m_count -= removed;
    return (removed > 0) ? true : false;
}

bool FileClipboardModel::ClipboardGroup::setEntries(const QStringList &paths)
{
    if (m_count != m_paths.length() || m_paths != paths) {
        m_paths = paths;
        m_count = m_paths.length();
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
