/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2021 Mirian Margiani
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

#include <QSettings>
#include <QByteArray>
#include <QDebug>
#include "filemodelworker.h"
#include "statfileinfo.h"
#include "settingshandler.h"

FileModelWorker::FileModelWorker(QObject *parent) : QThread(parent) {
    connect(this, &FileModelWorker::error, this, &FileModelWorker::logError);
    connect(this, &FileModelWorker::alreadyRunning, this,
            [&](){ logError("operation already running"); });
}

FileModelWorker::~FileModelWorker()
{
    quit();
    requestInterruption();
    wait();
}

void FileModelWorker::cancel()
{
    m_cancelled.storeRelease(Cancelled);
}

void FileModelWorker::startReadFull(QString dir, QString nameFilter, Settings* settings)
{
    logMessage("note: requested full directory listing");
    doStartThread(FullMode, {}, dir, nameFilter, settings);
}

void FileModelWorker::startReadChanged(QList<StatFileInfo> oldEntries,
                                       QString dir, QString nameFilter, Settings *settings)
{
    logMessage("note: requested partial directory listing");
    doStartThread(DiffMode, oldEntries, dir, nameFilter, settings);
}

void FileModelWorker::run()
{
    if (!verifyOrAbort()) return; // invalid directory

    QDir newDir(m_dir);
    if (m_cachedDir.canonicalPath() != newDir.canonicalPath()) {
        m_cachedDir = newDir;
    }

    if (m_mode == FullMode) {
        logMessage("note: started with FullMode");
        doReadFull();
    } else if (m_mode == DiffMode) {
        logMessage("note: started with DiffMode");
        doReadDiff();
    } else if (m_mode == NoneMode) {
        logMessage("note: started with NoneMode");
        return;
    }
}

void FileModelWorker::logMessage(QString message, bool markSilent)
{
    qDebug() << "[FileModelWorker]" << message << (markSilent ? "[silent]" : "");
    qDebug() << "[FileModelWorker] state:" << m_dir << m_mode;
}

void FileModelWorker::logError(QString message)
{
    logMessage("error: "+message, false);
}

void FileModelWorker::doStartThread(FileModelWorker::Mode mode, QList<StatFileInfo> oldEntries,
                                    QString dir, QString nameFilter, Settings* settings)
{
    if (isRunning()) {
        emit alreadyRunning(); // we hope everything works out
        return;
    }

    m_settings = settings;
    m_mode = mode;
    m_finalEntries = {};
    m_oldEntries = oldEntries;
    m_dir = dir;
    m_nameFilter = nameFilter;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileModelWorker::doReadFull()
{
    if (!applySettings()) return; // cancelled
    QStringList fileList = m_cachedDir.entryList();
    for (auto filename : fileList) {
        QString fullpath = m_cachedDir.absoluteFilePath(filename);
        StatFileInfo info(fullpath);
        m_finalEntries.append(info);
        if (cancelIfCancelled()) return;
    }

    emit done(m_mode, m_finalEntries);
}

void FileModelWorker::doReadDiff()
{
    if (!applySettings()) return; // cancelled

    // Algorithm: notify which files were removed, then
    // notify which files were added.
    // Complexity without lookup tables: circa 2*O(n^2).
    // With lookup tables, this gets reduced to around 4*O(n) or even 4*O(1).
    // This saves multiple seconds in directories with >1000 entries.

    QSet<uint> oldLookup;    QSet<uint> newLookup;
    QList<uint> oldHashes;   QList<uint> newHashes;
    /* + m_oldEntries */     QList<StatFileInfo> newEntries;

    QStringList fileList = m_cachedDir.entryList(); // read all files

    auto oldEntriesSize = m_oldEntries.size();
    oldLookup.reserve(oldEntriesSize);
    oldHashes.reserve(oldEntriesSize);

    auto newFileListSize = fileList.size(); // newEntries isn't populated yet
    newLookup.reserve(newFileListSize);
    newHashes.reserve(newFileListSize);
    newEntries.reserve(newFileListSize);

    m_finalEntries = m_oldEntries;
    m_finalEntries.reserve(std::max(oldEntriesSize, newFileListSize));

    // populate new file list and lookup table
    for (const auto& filename : fileList) {
        StatFileInfo info(m_cachedDir.absoluteFilePath(filename));
        newEntries.append(info);
        newHashes.append(hashInfo(info));
        newLookup.insert(newHashes.last());
        if (cancelIfCancelled()) return;
    }

    // populate old list lookup table
    for (const auto& info : m_oldEntries) {
        oldHashes.append(hashInfo(info));
        oldLookup.insert(oldHashes.last());
    }

    // compare old and new files and do removes if needed
    // Go from the bottom through all old entries, check if
    // each entry is anywhere in the new list, emit if not.
    // After a signal is emitted, all indices higher than the
    // current one will become invalid.
    for (int i = m_oldEntries.count()-1; i >= 0; --i) {
        StatFileInfo data = m_oldEntries.at(i);
        if (!newLookup.contains(oldHashes.at(i))) {
            emit entryRemoved(i, data);
            m_finalEntries.removeAt(i);
            if (cancelIfCancelled()) return;
        }
    }

    // compare old and new files and do inserts if needed
    // Go from the top through all new entries, check if
    // each entry is anywhere in the old list, emit if not.
    // After a signal is emitted, all indices lower than the
    // current one will become valid. Higher indices might be
    // invalid until we checked them.
    for (int i = 0; i < newEntries.count(); ++i) {
        StatFileInfo data = newEntries.at(i);
        if (!oldLookup.contains(newHashes.at(i))) {
            emit entryAdded(i, data);
            m_finalEntries.insert(i, data);
            if (cancelIfCancelled()) return;
        }
    }

    if (cancelIfCancelled()) return;
    emit done(m_mode, m_finalEntries);
}

bool FileModelWorker::verifyOrAbort()
{
    if (m_dir.isEmpty()) {
        // not translated
        emit error("Internal worker error: empty directory name");
        return false;
    }

    QDir dir(m_dir);
    if (!dir.exists()) {
        emit error(tr("Folder does not exist"));
        return false;
    }

    if (!dir.isReadable()) {
        emit error(tr("No permission to read the folder"));
        return false;
    }

    return true;
}

// see SETTINGS for details
bool FileModelWorker::applySettings() {
    if (cancelIfCancelled()) return false;
    bool settingsChanged = false;

    // TODO make sure the keyboard doesn't loose focus
    /* QString nameFilter = "*"+m_nameFilter+"*";
    if (m_cachedDir.nameFilters().first() != nameFilter) {
        m_cachedDir.setNameFilters({nameFilter});
        settingsChanged = true;
    } */

    // there are no settings to apply
    if (!m_settings) {
        m_cachedDir.refresh();
        return true;
    }

    QString localPath = m_cachedDir.absoluteFilePath(".directory");
    bool useLocal = m_settings->readVariant("View/UseLocalSettings", true).toBool();

    // filters
    bool hidden = m_settings->readVariant("View/HiddenFilesShown", false).toBool();
    if (useLocal) hidden = m_settings->readVariant("Settings/HiddenFilesShown", hidden, localPath).toBool();
    QDir::Filter hiddenFilter = hidden ? QDir::Hidden : static_cast<QDir::Filter>(0);

    auto newFilters = (QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::System | hiddenFilter);
    if (m_cachedDir.filter() != newFilters) {
        m_cachedDir.setFilter(newFilters);
        settingsChanged = true;
    }

    if (cancelIfCancelled()) return false;

    // sorting
    bool dirsFirst = m_settings->readVariant("View/ShowDirectoriesFirst", true).toBool();
    if (useLocal) dirsFirst = m_settings->readVariant("Sailfish/ShowDirectoriesFirst", dirsFirst, localPath).toBool();
    QDir::SortFlag dirsFirstFlag = dirsFirst ? QDir::DirsFirst : static_cast<QDir::SortFlag>(0);

    QString sortSetting = m_settings->readVariant("View/SortRole", "name").toString();
    if (useLocal) sortSetting = m_settings->readVariant("Dolphin/SortRole", sortSetting, localPath).toString();
    QDir::SortFlag sortBy = QDir::Name;

    if (sortSetting == "name") {
        sortBy = QDir::Name;
    } else if (sortSetting == "size") {
        sortBy = QDir::Size;
    } else if (sortSetting == "modificationtime") {
        sortBy = QDir::Time;
    } else if (sortSetting == "type") {
        sortBy = QDir::Type;
    } else {
        sortBy = QDir::Name;
    }

    bool orderDefault = m_settings->readVariant("View/SortOrder", "default").toString() == "default";
    if (useLocal) orderDefault = m_settings->readVariant("Dolphin/SortOrder", 0, localPath) == 0 ? true : false;
    QDir::SortFlag orderFlag = orderDefault ? static_cast<QDir::SortFlag>(0) : QDir::Reversed;

    bool caseSensitive = m_settings->readVariant("View/SortCaseSensitively", false).toBool();
    if (useLocal) caseSensitive = m_settings->readVariant("Sailfish/SortCaseSensitively", caseSensitive, localPath).toBool();
    QDir::SortFlag caseSensitiveFlag = caseSensitive ? static_cast<QDir::SortFlag>(0) : QDir::IgnoreCase;

    auto newSorting = (sortBy | dirsFirstFlag | orderFlag | caseSensitiveFlag);
    if (m_cachedDir.sorting() != newSorting) {
        m_cachedDir.setSorting(newSorting);
        settingsChanged = true;
    }

    if (cancelIfCancelled()) return false;

    if (!settingsChanged) {
        // this happens e.g. when deleting or renaming files
        m_cachedDir.refresh();
    }

    return true;
}

bool FileModelWorker::filesContains(const QList<StatFileInfo> &files, const StatFileInfo &fileData) const
{
    // check if list contains fileData with relevant info
    for (const auto& f : files) {
        if (f.fileName() == fileData.fileName() &&
                f.size() == fileData.size() &&
                f.permissions() == fileData.permissions() &&
                f.lastModified() == fileData.lastModified() &&
                f.isSymLink() == fileData.isSymLink() &&
                f.isDirAtEnd() == fileData.isDirAtEnd()) {
            return true;
        }
    }
    return false;
}

uint FileModelWorker::hashInfo(const StatFileInfo& f)
{
    QByteArray result;
    result.reserve(45);
    result.append(QByteArray::number(qHash(f.fileName())));
    result.append('#');
    result.append(QByteArray::number(f.size()));
    result.append('#');
    result.append(QByteArray::number(qHash(f.permissions())));
    result.append('#');
    result.append(QByteArray::number(qHash(f.lastModified())));
    result.append('#');
    result.append(f.isSymLink());
    result.append('#');
    result.append(f.isDirAtEnd());
    // qDebug() << "hashed" << f.fileName() << "to" << result << "(" << result.size() << ")";
    return qHash(result);
}

bool FileModelWorker::cancelIfCancelled()
{
    if (m_cancelled.loadAcquire() == Cancelled) {
        logMessage("warning: directory listing cancelled");
        return true;
    }
    return false;
}
