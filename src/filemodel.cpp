/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2015 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Malte Veerman
 * SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
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

#include <unistd.h>
#include <time.h>

#include <QDateTime>
#include <QMimeType>
#include <QMimeDatabase>
#include <QSettings>
#include <QGuiApplication>
#include <QRegularExpression>
#include <QDebug>

#include "filemodel.h"
#include "filemodelworker.h"
#include "settingshandler.h"
#include "globals.h"

enum {
    FilenameRole = Qt::UserRole + 1,
    FileKindRole = Qt::UserRole + 2,
    FileTypeRole = Qt::UserRole + 13,
    FileIconRole = Qt::UserRole + 3,
    PermissionsRole = Qt::UserRole + 4,
    SizeRole = Qt::UserRole + 5,
    LastModifiedRole = Qt::UserRole + 6,
    CreatedRole = Qt::UserRole + 7,
    IsDirRole = Qt::UserRole + 8,
    IsLinkRole = Qt::UserRole + 9,
    SymLinkTargetRole = Qt::UserRole + 10,
    IsSelectedRole = Qt::UserRole + 11,
    IsDoomedRole = Qt::UserRole + 12,
};

FileModel::FileModel(QObject *parent) : QAbstractListModel(parent)
{
    m_worker = new FileModelWorker;
    updateLastRefreshedTimestamp();

    m_watcher = new QFileSystemWatcher(this);
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &FileModel::refresh);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &FileModel::refresh);

    // refresh model every time view settings are changed
    m_settings = RawSettingsHandler::instance();
    connect(m_settings, &RawSettingsHandler::viewSettingsChanged, this, &FileModel::refreshFull);
    connect(this, &FileModel::filterStringChanged, this, &FileModel::applyFilterString);

    // sync worker status
    connect(m_worker, &FileModelWorker::done, this, &FileModel::workerDone);
    connect(m_worker, &FileModelWorker::error, this, &FileModel::workerErrorOccurred);
    connect(m_worker, &FileModelWorker::entryAdded, this, &FileModel::workerAddedEntry);
    connect(m_worker, &FileModelWorker::entryRemoved, this, &FileModel::workerRemovedEntry);
    connect(m_worker, &FileModelWorker::entryChanged, this, &FileModel::workerChangedEntry);
}

FileModel::~FileModel()
{
    // stop and delete the worker
    m_worker->cancel();
    m_worker->wait();
    m_worker->deleteLater();
}

int FileModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_files.count();
}

QVariant FileModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() > m_files.size()-1)
        return QVariant();

    StatFileInfo info = m_files.at(index.row());
    switch (role) {

    case Qt::DisplayRole:
    case FilenameRole:
        return info.fileName();

    case FileKindRole:
        return info.kind();

    case FileTypeRole:
        if (info.isDir()) return tr("folder");
        if (!info.suffix().isEmpty()) return info.suffix().toLower();
        if (info.isSymLink()) return tr("link");
        return tr("file");

    case FileIconRole:
        return infoToIconName(info);

    case PermissionsRole:
        return permissionsToString(info.permissions());

    case SizeRole:
        if (info.isDir()) {
            uint size = info.dirSize();
            //: as in "this folder is empty", but as short as possible
            if (size == 0) return tr("empty");
            else return tr("%n item(s)", "", static_cast<int>(size));
        } else {
            return filesizeToString(info.size());
        }

    case LastModifiedRole:
        return datetimeToString(info.lastModified());

    case CreatedRole:
        return datetimeToString(info.created());

    case IsDirRole:
        return info.isDirAtEnd();

    case IsLinkRole:
        return info.isSymLink();

    case SymLinkTargetRole:
        return info.symLinkTarget();

    case IsSelectedRole:
        return info.isSelected();

    case IsDoomedRole:
        return info.isDoomed();

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FileModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(FilenameRole, QByteArray("filename"));
    roles.insert(FileKindRole, QByteArray("filekind"));
    roles.insert(FileTypeRole, QByteArray("fileType"));
    roles.insert(FileIconRole, QByteArray("fileIcon"));
    roles.insert(PermissionsRole, QByteArray("permissions"));
    roles.insert(SizeRole, QByteArray("size"));
    roles.insert(LastModifiedRole, QByteArray("modified"));
    roles.insert(CreatedRole, QByteArray("created"));
    roles.insert(IsDirRole, QByteArray("isDir"));
    roles.insert(IsLinkRole, QByteArray("isLink"));
    roles.insert(SymLinkTargetRole, QByteArray("symLinkTarget"));
    roles.insert(IsSelectedRole, QByteArray("isSelected"));
    roles.insert(IsDoomedRole, QByteArray("isDoomed"));
    return roles;
}

int FileModel::fileCount() const
{
    return m_files.count();
}

QString FileModel::errorMessage() const
{
    return m_errorMessage;
}

void FileModel::setDir(QString dir)
{
    if (m_dir == dir) {
        return;
    }

    // update watcher to watch the new directory
    if (!m_dir.isEmpty()) {
        m_watcher->removePath(m_dir);
    }

    if (!dir.isEmpty()) {
        m_watcher->addPath(dir);
    }

    m_initialFullRefreshDone = false;
    m_dir = dir;

    if (m_worker->isRunning()) m_worker->cancel();
    doUpdateAllEntries();

    emit dirChanged();
}

QString FileModel::appendPath(QString dirName)
{
    return QDir::cleanPath(QDir(m_dir).absoluteFilePath(dirName));
}

void FileModel::setActive(bool active)
{
    if (m_active == active) {
        return;
    }

    m_active = active;
    emit activeChanged();

    if (active) {
        switch (m_scheduledRefresh) {
        case FileModelWorker::Mode::NoneMode:
            // Always do a refresh after the model has been reactivated,
            // even if no refresh was requested by the file system watcher.
            // We do this to find changed files, as the watcher only picks
            // up if files were added/removed in the watched directory.
            [[fallthrough]];
        case FileModelWorker::Mode::DiffMode:
            doUpdateChangedEntries();
            break;
        case FileModelWorker::Mode::FullMode:
            doUpdateAllEntries();
            break;
        }

        m_scheduledRefresh = FileModelWorker::Mode::NoneMode;
    }
}

void FileModel::setFilterString(QString newFilter)
{
    // we change the filter and emit the proper signal,
    // but we will only refresh the model if anything changed
    m_oldFilterString = m_filterString;
    m_filterString = newFilter;
    emit filterStringChanged();
}

QString FileModel::parentPath()
{
    return QDir::cleanPath(QDir(m_dir).absoluteFilePath(".."));
}

QString FileModel::fileNameAt(int fileIndex)
{
    if (fileIndex < 0 || fileIndex >= m_files.count())
        return QString();

    return m_files.at(fileIndex).absoluteFilePath();
}

QString FileModel::mimeTypeAt(int fileIndex) {
    QString file = fileNameAt(fileIndex);

    if (file.isEmpty()) return QString();

    QMimeDatabase db;
    QMimeType type = db.mimeTypeForFile(file);
    return type.name();
}

void FileModel::toggleSelectedFile(int fileIndex)
{
    if (fileIndex >= m_files.length() || fileIndex < 0) return; // fail silently

    StatFileInfo info = m_files.at(fileIndex);

    if (!m_files.at(fileIndex).isSelected()) {
        info.setSelected(true);
        m_selectedFileCount++;
    } else {
        info.setSelected(false);
        m_selectedFileCount--;
    }

    m_files[fileIndex] = info;
    QModelIndex topLeft = index(fileIndex, 0);
    QModelIndex bottomRight = index(fileIndex, 0);
    emit dataChanged(topLeft, bottomRight, {IsSelectedRole});
    emit selectedFileCountChanged();
}

void FileModel::clearSelectedFiles()
{
    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0;
    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();
        info.setSelected(false);
        // emit signal for views
        QModelIndex topLeft = index(row, 0);
        QModelIndex bottomRight = index(row, 0);
        emit dataChanged(topLeft, bottomRight, {IsSelectedRole});
        row++;
    }
    m_selectedFileCount = 0;
    emit selectedFileCountChanged();
}

void FileModel::selectAllFiles()
{
    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0; int count = 0;

    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();
        info.setSelected(true);
        // emit signal for views
        QModelIndex topLeft = index(row, 0);
        QModelIndex bottomRight = index(row, 0);
        emit dataChanged(topLeft, bottomRight, {IsSelectedRole});
        row++; count++;
    }

    m_selectedFileCount = count;
    emit selectedFileCountChanged();
}

void FileModel::selectRange(int firstIndex, int lastIndex, bool selected)
{
    // fail silently if indices are invalid
    if (   firstIndex >= m_files.length()
        || firstIndex < 0
        || lastIndex >= m_files.length()
        || lastIndex < 0
       ) return;

    if (firstIndex > lastIndex) {
        std::swap(firstIndex, lastIndex);
    }

    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0; int count = 0;
    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();

        if (   row >= firstIndex
            && row <= lastIndex
            && info.isSelected() != selected) {
            info.setSelected(selected);
            // emit signal for views
            QModelIndex topLeft = index(row, 0);
            QModelIndex bottomRight = index(row, 0);
            emit dataChanged(topLeft, bottomRight, {IsSelectedRole});
        }

        if (info.isSelected()) count++;
        row++;
    }

    if (count != m_selectedFileCount) {
        m_selectedFileCount = count;
        emit selectedFileCountChanged();
    }
}

QStringList FileModel::selectedFiles() const
{
    if (m_selectedFileCount == 0)
        return QStringList();

    QStringList filenames;
    for (const StatFileInfo& info : std::as_const(m_files)) {
        if (info.isSelected())
            filenames.append(info.absoluteFilePath());
    }
    return filenames;
}

void FileModel::markSelectedAsDoomed()
{
    doMarkAsDoomed(m_files, [](StatFileInfo& info){
        if (info.isSelected()) return true;
        return false;
    });
}

void FileModel::markAsDoomed(QStringList absoluteFilePaths)
{
    doMarkAsDoomed(m_files, [&absoluteFilePaths](StatFileInfo& info){
        if (absoluteFilePaths.contains(info.absoluteFilePath())) return true;
        return false;
    });
}

void FileModel::doMarkAsDoomed(QList<StatFileInfo>& files, std::function<bool(StatFileInfo&)> checker) {
    // TODO this should save the affected paths in a
    // global (runtime) registry so it won't be lost when
    // refreshing the model and when changing directories
    for (int i = 0; i < files.size(); i++) {
        if (checker(files[i])) {
            files[i].setDoomed(true);
            files[i].setSelected(false); // doomed files can't be selected
            emit dataChanged(index(i, 0), index(i, 0), {IsDoomedRole, IsSelectedRole});
        }
    }
    updateFileCounts();
}

void FileModel::refresh()
{
    if (!m_active) {
        if (m_scheduledRefresh != FileModelWorker::Mode::FullMode) {
            // we don't want to do only a partial refresh when
            // a full refresh is already scheduled
            m_scheduledRefresh = FileModelWorker::Mode::DiffMode;
        }
        return;
    }

    doUpdateChangedEntries();
}

void FileModel::refreshFull(QString localPath)
{
    if (!localPath.isEmpty() && localPath != m_dir) {
        // ignore changes to local settings of a different directory
        return;
    }

    if (!m_active) {
        m_scheduledRefresh = FileModelWorker::Mode::FullMode;
        return;
    }

    doUpdateAllEntries();
}

void FileModel::applyFilterString()
{
    if (m_oldFilterString != m_filterString &&
            !m_dir.isEmpty()) refresh();
}

void FileModel::workerDone(FileModelWorker::Mode mode, QList<StatFileInfo> files)
{
    if (mode == FileModelWorker::Mode::DiffMode) {
        // main work is already handled in workerAddedEntry() and
        // workerRemovedEntry(), triggered by the resp. signals
        // TODO emit fileCountChanged();
    } else if (mode == FileModelWorker::Mode::FullMode) {
        setBusy(m_busy, false); // make sure we're busy
        beginResetModel();
        m_files.clear();
        m_files = files;
        endResetModel();
        emit fileCountChanged();

        m_initialFullRefreshDone = true;
    }

    updateFileCounts();
    m_errorMessage = ""; // worker finished successfully
    emit errorMessageChanged();
    setBusy(false, false);
}

void FileModel::workerErrorOccurred(QString message)
{
    m_errorMessage = message;
    clearModel();
    emit errorMessageChanged();
    updateFileCounts();
    setBusy(false, false);
}

void FileModel::workerAddedEntry(int index, StatFileInfo file)
{
    beginInsertRows(QModelIndex(), index, index);
    m_files.insert(index, file);
    endInsertRows();

    emit fileCountChanged();
    updateFileCounts();
}

void FileModel::workerRemovedEntry(int index, StatFileInfo file)
{
    if (index < 0 || index >= m_files.length()) return; // fail silently

    if (m_files.at(index).absoluteFilePath() != file.absoluteFilePath()) {
        // this case should not be possible
        auto path = file.absoluteFilePath();
        bool found = false;
        for (int i = 0; i < m_files.count(); i++) {
            if (m_files.at(index).absoluteFilePath() != path) {
                found = true;
                index = 0;
                break;
            }
        }
        if (!found) {
            qDebug() << "error: worker removed entry with invalid index";
            return;
        } else {
            qDebug() << "warning: worker removed entry with shifted index";
        }
    }

    beginRemoveRows(QModelIndex(), index, index);
    m_files.removeAt(index);
    endRemoveRows();

    emit fileCountChanged();
    updateFileCounts();
}

void FileModel::workerChangedEntry(int entryIndex, StatFileInfo file)
{
    if (entryIndex < 0 || entryIndex >= m_files.length()) {
        return; // fail silently
    }

    auto i = index(entryIndex, 0);

    if (!i.isValid() || m_files.at(entryIndex).absoluteFilePath() != file.absoluteFilePath()) {
        // this case should not be possible but if it happens, we can safely ignore it
        qDebug() << "warning: worker reported changed entry at invalid index:" <<
                    entryIndex << m_files.at(entryIndex).absoluteFilePath() <<
                    "vs." << file.absoluteFilePath();
        return;
    } else {
        m_files[entryIndex].refresh();
        emit dataChanged(i, i, {PermissionsRole, SizeRole, LastModifiedRole});
    }
}

void FileModel::doUpdateAllEntries()
{
    setBusy(true);
    m_worker->startReadFull(m_dir, m_filterString);
}

void FileModel::doUpdateChangedEntries()
{
    if (!m_initialFullRefreshDone) return;

    setBusy(false, true);
    m_worker->startReadChanged(m_files, m_dir, m_filterString, m_lastRefreshedTimestamp);
    updateLastRefreshedTimestamp();
}

void FileModel::updateFileCounts()
{
    int selectedCount = 0;

    for (const auto& info : std::as_const(m_files)) {
        if (info.isSelected()) selectedCount++;
    }

    if (m_selectedFileCount != selectedCount) {
        m_selectedFileCount = selectedCount;
        emit selectedFileCountChanged();
    }
}

void FileModel::updateLastRefreshedTimestamp()
{
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME_COARSE, &ts);
    m_lastRefreshedTimestamp = ts.tv_sec;
}

void FileModel::clearModel()
{
    beginResetModel();
    m_files.clear();
    endResetModel();
    emit fileCountChanged();
}

void FileModel::setBusy(bool busy, bool partlyBusy)
{
    m_busy = busy;
    m_partlyBusy = partlyBusy;
    emit busyChanged();
    emit partlyBusyChanged();
}

void FileModel::setBusy(bool busy)
{
    m_busy = busy;
    emit busyChanged();
}
