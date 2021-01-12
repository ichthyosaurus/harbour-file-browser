/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2015 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Malte Veerman
 * SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
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
#include <QDateTime>
#include <QMimeType>
#include <QMimeDatabase>
#include <QSettings>
#include <QGuiApplication>
#include <QRegularExpression>

#include "filemodel.h"
#include "filemodelworker.h"
#include "settingshandler.h"
#include "globals.h"

enum {
    FilenameRole = Qt::UserRole + 1,
    FileKindRole = Qt::UserRole + 2,
    FileIconRole = Qt::UserRole + 3,
    PermissionsRole = Qt::UserRole + 4,
    SizeRole = Qt::UserRole + 5,
    LastModifiedRole = Qt::UserRole + 6,
    CreatedRole = Qt::UserRole + 7,
    IsDirRole = Qt::UserRole + 8,
    IsLinkRole = Qt::UserRole + 9,
    SymLinkTargetRole = Qt::UserRole + 10,
    IsSelectedRole = Qt::UserRole + 11,
    IsMatchedRole = Qt::UserRole + 12,
    IsDoomedRole = Qt::UserRole + 13
};

FileModel::FileModel(QObject *parent) :
    QAbstractListModel(parent),
    m_selectedFileCount(0),
    m_matchedFileCount(0),
    m_active(false)
{
    m_worker = new FileModelWorker;
    m_dir = "";
    m_filterString = "";

    m_watcher = new QFileSystemWatcher(this);
    connect(m_watcher, SIGNAL(directoryChanged(const QString&)), this, SLOT(refresh()));
    connect(m_watcher, SIGNAL(fileChanged(const QString&)), this, SLOT(refresh()));

    // refresh model every time view settings are changed
    m_settings = qApp->property("settings").value<Settings*>();
    connect(m_settings, SIGNAL(viewSettingsChanged(QString)), this, SLOT(refreshFull(QString)));
    connect(this, SIGNAL(filterStringChanged()), this, SLOT(applyFilterString()));

    // sync worker status
    connect(m_worker, &FileModelWorker::done, this, &FileModel::workerDone);
    connect(m_worker, &FileModelWorker::error, this, &FileModel::workerErrorOccurred);
    connect(m_worker, &FileModelWorker::entryAdded, this, &FileModel::workerAddedEntry);
    connect(m_worker, &FileModelWorker::entryRemoved, this, &FileModel::workerRemovedEntry);
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

    case FileIconRole:
        return infoToIconName(info);

    case PermissionsRole:
        return permissionsToString(info.permissions());

    case SizeRole:
        if (info.isSymLink() && info.isDirAtEnd()) return tr("dir-link");
        if (info.isDir()) return tr("dir");
        return filesizeToString(info.size());

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

    case IsMatchedRole:
        return info.isMatched();

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
    roles.insert(FileIconRole, QByteArray("fileIcon"));
    roles.insert(PermissionsRole, QByteArray("permissions"));
    roles.insert(SizeRole, QByteArray("size"));
    roles.insert(LastModifiedRole, QByteArray("modified"));
    roles.insert(CreatedRole, QByteArray("created"));
    roles.insert(IsDirRole, QByteArray("isDir"));
    roles.insert(IsLinkRole, QByteArray("isLink"));
    roles.insert(SymLinkTargetRole, QByteArray("symLinkTarget"));
    roles.insert(IsSelectedRole, QByteArray("isSelected"));
    roles.insert(IsMatchedRole, QByteArray("isMatched"));
    roles.insert(IsDoomedRole, QByteArray("isDoomed"));
    return roles;
}

int FileModel::fileCount() const
{
    return m_files.count();
}

int FileModel::filteredFileCount() const
{
    return m_matchedFileCount;
}

QString FileModel::errorMessage() const
{
    return m_errorMessage;
}

void FileModel::setDir(QString dir)
{
    if (m_dir == dir)
        return;

    // update watcher to watch the new directory
    if (!m_dir.isEmpty())
        m_watcher->removePath(m_dir);
    if (!dir.isEmpty())
        m_watcher->addPath(dir);

    m_dir = dir;

    doUpdateAllEntries();

    emit dirChanged();
}

QString FileModel::appendPath(QString dirName)
{
    return QDir::cleanPath(QDir(m_dir).absoluteFilePath(dirName));
}

void FileModel::setActive(bool active)
{
    if (m_active == active)
        return;

    m_active = active;
    emit activeChanged();

    switch (m_scheduledRefresh) {
    case FileModelWorker::Mode::NoneMode:
        break; // nothing to refresh
    case FileModelWorker::Mode::DiffMode:
        doUpdateChangedEntries();
        break;
    case FileModelWorker::Mode::FullMode:
        doUpdateAllEntries();
        break;
    }

    m_scheduledRefresh = FileModelWorker::Mode::NoneMode;
}

void FileModel::setFilterString(QString newFilter)
{
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
    emit dataChanged(topLeft, bottomRight);
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
        emit dataChanged(topLeft, bottomRight);
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
        if (!info.isMatched()) {
            row++; continue;
        }

        info.setSelected(true);
        // emit signal for views
        QModelIndex topLeft = index(row, 0);
        QModelIndex bottomRight = index(row, 0);
        emit dataChanged(topLeft, bottomRight);
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
            && info.isMatched()
            && info.isSelected() != selected) {
            info.setSelected(selected);
            // emit signal for views
            QModelIndex topLeft = index(row, 0);
            QModelIndex bottomRight = index(row, 0);
            emit dataChanged(topLeft, bottomRight);
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
    foreach (const StatFileInfo &info, m_files) {
        if (info.isSelected())
            filenames.append(info.absoluteFilePath());
    }
    return filenames;
}

void FileModel::markSelectedAsDoomed()
{
    // TODO this should save the affected paths in a
    // global (runtime) registry so it won't be lost when
    // refreshing the model and when changing directories
    for (int i = 0; i < m_files.count(); i++) {
        if (m_files.at(i).isSelected()) {
            m_files[i].setDoomed(true);
            m_files[i].setSelected(false); // doomed files can't be selected
            emit dataChanged(index(i, 0), index(i, 0));
        }
    }
}

void FileModel::markAsDoomed(QStringList absoluteFilePaths)
{
    // Cf. markSelectedAsDoomed
    for (int i = 0; i < m_files.count(); i++) {
        if (absoluteFilePaths.contains(m_files.at(i).absoluteFilePath())) {
            m_files[i].setDoomed(true);
            m_files[i].setSelected(false); // doomed files can't be selected
            emit dataChanged(index(i, 0), index(i, 0));
        }
    }
}

void FileModel::refresh()
{
    if (!m_active) {
        m_scheduledRefresh = FileModelWorker::Mode::DiffMode;
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
    /* if (!m_dir.isEmpty()) doUpdateChangedEntries();
    return; */

    QRegularExpression filter(
                m_filterString.replace(".", "\\.").
                replace("?", ".").replace("*", ".*?"),
                QRegularExpression::CaseInsensitiveOption);
    if (m_filterString.isEmpty()) filter.setPattern(".*");

    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0; int count = 0;
    m_matchedFileCount = 0;
    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();
        bool match = filter.match(info.fileName()).hasMatch();
        if (match) m_matchedFileCount++;

        if (   info.isMatched() != match
            || (!match && info.isSelected())) {

            info.setFilterMatched(match);
            if (!match) info.setSelected(false);

            // emit signal for views
            QModelIndex topLeft = index(row, 0);
            QModelIndex bottomRight = index(row, 0);
            emit dataChanged(topLeft, bottomRight);
        }

        if (info.isSelected()) count++;
        row++;
    }

    if (count != m_selectedFileCount) {
        m_selectedFileCount = count;
        emit selectedFileCountChanged();
    }
}

void FileModel::workerDone(FileModelWorker::Mode mode, QList<StatFileInfo> files)
{
    if (mode == FileModelWorker::Mode::DiffMode) {
        // main work is already handled in workerAddedEntry() and
        // workerRemovedEntry(), triggered by the resp. signals
        // TODO emit fileCountChanged();
    } else if (mode == FileModelWorker::Mode::FullMode) {
        beginResetModel();
        m_files.clear();
        m_files = files;
        endResetModel();
        emit fileCountChanged();
    }

    updateFileCounts();
    m_errorMessage = ""; // worker finished successfully
    emit errorMessageChanged();
    setBusy(false, false);
    applyFilterString(); // TODO remove when filtering in worker
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
            return; // TODO log this problem
        }
    }

    beginRemoveRows(QModelIndex(), index, index);
    m_files.removeAt(index);
    endRemoveRows();

    emit fileCountChanged();
    updateFileCounts();
}

void FileModel::doUpdateAllEntries()
{
    setBusy(true);
    m_worker->startReadFull(m_dir, m_filterString, m_settings);
}

void FileModel::doUpdateChangedEntries()
{
    setBusy(false, true);
    m_worker->startReadChanged(m_files, m_dir, m_filterString, m_settings);
}

void FileModel::updateFileCounts()
{
    int selectedCount = 0;
    int matchedCount = 0;

    for (const auto& info : m_files) {
        if (info.isSelected()) selectedCount++;
        if (info.isMatched()) matchedCount++;
    }

    if (m_selectedFileCount != selectedCount) {
        m_selectedFileCount = selectedCount;
        emit selectedFileCountChanged();
    }
    if (m_matchedFileCount != matchedCount) {
        m_matchedFileCount = matchedCount;
        emit filteredFileCountChanged();
    }
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
