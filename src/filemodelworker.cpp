/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2021-2022 Mirian Margiani
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

#include <algorithm>
#include <QSettings>
#include <QByteArray>
#include <QDebug>
#include "filemodelworker.h"
#include "statfileinfo.h"
#include "settingshandler.h"

#ifndef FILEMODEL_SIGNAL_THRESHOLD
#define FILEMODEL_SIGNAL_THRESHOLD 200
#endif

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

void FileModelWorker::startReadFull(QString dir, QString nameFilter)
{
    logMessage("note: requested full directory listing");
    doStartThread(FullMode, {}, dir, nameFilter);
}

void FileModelWorker::startReadChanged(QList<StatFileInfo> oldEntries,
                                       QString dir, QString nameFilter)
{
    logMessage("note: requested partial directory listing");
    doStartThread(DiffMode, oldEntries, dir, nameFilter);
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
    qDebug() << message << (markSilent ? "[silent]" : "") << "| in:" << m_dir
             << "mode:" << m_mode << FILEMODEL_SIGNAL_THRESHOLD;
}

void FileModelWorker::logError(QString message)
{
    logMessage("error: "+message, false);
}

void FileModelWorker::doStartThread(FileModelWorker::Mode mode, QList<StatFileInfo> oldEntries,
                                    QString dir, QString nameFilter)
{
    if (isRunning()) {
        emit alreadyRunning(); // we hope everything works out
        return;
    }

    m_mode = mode;
    m_finalEntries = {};
    m_oldEntries = oldEntries;
    m_dir = dir;
    m_nameFilter = nameFilter;
    m_cancelled.storeRelease(KeepRunning);
    initSettings();
    start();
}

void FileModelWorker::doReadFull()
{
    if (!applySettings()) return; // cancelled
    emit done(m_mode, m_finalEntries);
}

void FileModelWorker::doReadDiff()
{
    if (!applySettings()) return; // cancelled

    // To reduce load on the main UI thread, we abort the process and
    // instead do a full refresh if there are too many changes.
    uint signalledChanges = 0;

    // Algorithm: notify which files were removed, then
    // notify which files were added.
    // Complexity without lookup tables: circa 2*O(n^2).
    // With lookup tables, this gets reduced to around 4*O(n) or even 4*O(1).
    // This saves multiple seconds in directories with >1000 entries.

    QSet<uint> oldLookup;    QSet<uint> newLookup;
    QList<uint> oldHashes;   QList<uint> newHashes;
    /* + m_oldEntries */     QList<StatFileInfo> newEntries = m_finalEntries;

    auto oldEntriesSize = m_oldEntries.size();
    oldLookup.reserve(oldEntriesSize);
    oldHashes.reserve(oldEntriesSize);

    auto newFileListSize = newEntries.size();
    newLookup.reserve(newFileListSize);
    newHashes.reserve(newFileListSize);

    if (thresholdAbort(size_t(std::abs(oldEntriesSize-newFileListSize)), newEntries)) {
        // threshold would be reached, so we can abort immediately
        return;
    }

    m_finalEntries = m_oldEntries;
    m_finalEntries.reserve(std::max(oldEntriesSize, newFileListSize));

    // populate new hashes and lookup table
    // NOTE If necessary we could merge this in the loop
    // where we initially load the new file list.
    for (const auto& info : std::as_const(newEntries)) {
        newHashes.append(qHash(info));
        newLookup.insert(newHashes.last());
        if (cancelIfCancelled()) return;
    }

    // populate old hashes and lookup table
    for (const auto& info : std::as_const(m_oldEntries)) {
        oldHashes.append(qHash(info));
        oldLookup.insert(oldHashes.last());
    }

    // compare old and new files and do removes if needed
    // Go from the bottom through all old entries, check if
    // each entry is anywhere in the new list, emit if not.
    // After a signal is emitted, all indices higher than the
    // current one will become invalid.
    for (int i = m_oldEntries.count()-1; i >= 0; --i) {
        const StatFileInfo& data = m_oldEntries.at(i);
        if (!newLookup.contains(oldHashes.at(i))) {
            if (thresholdAbort(signalledChanges, newEntries)) return;
            emit entryRemoved(i, data);
            signalledChanges++;
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
        const StatFileInfo& data = newEntries.at(i);
        if (!oldLookup.contains(newHashes.at(i))) {
            if (thresholdAbort(signalledChanges, newEntries)) return;
            emit entryAdded(i, data);
            signalledChanges++;
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

bool FileModelWorker::applySettings() {
    if (cancelIfCancelled()) return false;
    bool settingsChanged = false;
    QFlags<QDir::Filter> newFilters = (QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::System);
    QFlags<QDir::SortFlag> newSorting;

    bool sortTime = false;
    bool sortSize = false;

    // load settings, see SETTINGS.md for details
    initSettings();

    // filters: show hidden files and directories?
    bool hidden = false;

    if (m_nameFilter.startsWith(QLatin1Char('.'))) {
        hidden = true;
    } else {
        hidden = m_settings->get_viewHiddenFilesShown();
    }

    QDir::Filter hiddenFilter = hidden ? QDir::Hidden : static_cast<QDir::Filter>(0);
    newFilters |= hiddenFilter;

    // sorting: dirs first?
    if (m_settings->get_viewShowDirectoriesFirst()) newSorting |= QDir::DirsFirst;

    // sorting: sort by...?
    QString sortSetting = m_settings->get_viewSortRole();

    QDir::SortFlag sortBy = QDir::Name;
    if (sortSetting == "name") {
        sortBy = QDir::Name;
    } else if (sortSetting == "size") {
        // sortBy = QDir::Size; -- sorting manually improves accuracy
        sortSize = true;
    } else if (sortSetting == "modificationtime") {
        // sortBy = QDir::Time; -- sorting manually improves performance
        sortTime = true;
    } else if (sortSetting == "type") {
        sortBy = QDir::Type;
    }
    newSorting |= sortBy;

    // sorting: order reversed?
    if (m_settings->get_viewSortOrder() != QStringLiteral("default")) newSorting |= QDir::Reversed;

    // sorting: ignore case?
    if (!m_settings->get_viewSortCaseSensitively()) newSorting |= QDir::IgnoreCase;

    if (m_cachedDir.filter() != newFilters) {
        m_cachedDir.setFilter(newFilters);
        settingsChanged = true;
        if (cancelIfCancelled()) return false;
    }

    if (m_cachedDir.sorting() != newSorting ||
            m_cachedSortTime != sortTime) {
        m_cachedDir.setSorting(newSorting);
        m_cachedSortTime = sortTime;
        settingsChanged = true;
        if (cancelIfCancelled()) return false;
    }

    auto currentFilters = m_cachedDir.nameFilters();

    if (m_nameFilter.isEmpty()) {
        if (!currentFilters.isEmpty()) {
            m_cachedDir.setNameFilters({QStringLiteral("*")});
            settingsChanged = true;
            logMessage("note: name filter cleared");
        }
    } else {
        QString nameFilter = "*"+m_nameFilter+"*";

        if (currentFilters.first() != nameFilter) {
            m_cachedDir.setNameFilters({nameFilter});
            settingsChanged = true;
            logMessage("note: applied name filter '"+nameFilter+"'");
        }
    }

    if (cancelIfCancelled()) return false;

    if (!settingsChanged) {
        // this happens e.g. when deleting or renaming files
        m_cachedDir.refresh();
    }

    // load entries
    QStringList fileList = m_cachedDir.entryList();
    m_finalEntries.clear();
    m_finalEntries.reserve(fileList.size());
    int dirsCount = 0;
    for (const auto& filename : fileList) {
        m_finalEntries.append(StatFileInfo(m_cachedDir.absoluteFilePath(filename)));
        if (m_finalEntries.last().isDirAtEnd()) dirsCount++;
    }

    if (cancelIfCancelled()) return false;

    // apply manual sorting
    if (!newSorting.testFlag(QDir::DirsFirst)) {
        dirsCount = -1; // don't sort dirs separately
    }

    if (sortTime) {
        sortByModTime(m_finalEntries, newSorting.testFlag(QDir::Reversed), dirsCount);
    } else if (sortSize) {
        sortBySize(m_finalEntries, newSorting.testFlag(QDir::Reversed), dirsCount);
    }

    if (m_settings->get_viewShowHiddenLast()) {
        sortHiddenLast(m_finalEntries, dirsCount);
    }

    return true;
}

bool FileModelWorker::thresholdAbort(size_t currentChanges, const QList<StatFileInfo>& fullFiles)
{
    const size_t signalThreshold = FILEMODEL_SIGNAL_THRESHOLD;
    if (currentChanges >= signalThreshold) {
        logMessage("warning: partial refresh reached threshold, upgraded to full");
        emit done(Mode::FullMode, fullFiles);
        return true;
    }
    return false;
}

void FileModelWorker::initSettings()
{
    if (m_settings != nullptr) {
        m_settings->setPath(m_dir);
    } else {
        m_settings = new DirectorySettings(m_dir, this);
    }
}

void FileModelWorker::sortFileList(QList<StatFileInfo> &files, int dirsFirstCount,
                                   SorterFunction sorter, PartitionerFunction partitioner)
{
    if (dirsFirstCount > 0 && dirsFirstCount < files.length()) {
        // QDir placed dirs already at the beginning, so we can just sort
        // two ranges (dirs and files).
        if (sorter != nullptr) std::sort(files.begin(), files.begin()+dirsFirstCount, sorter);
        if (partitioner != nullptr) std::stable_partition(files.begin(), files.begin()+dirsFirstCount, partitioner);
        if (sorter != nullptr) std::sort(files.begin()+dirsFirstCount, files.end(), sorter);
        if (partitioner != nullptr) std::stable_partition(files.begin()+dirsFirstCount, files.end(), partitioner);
    } else {
        // we sort everything at once without taking care of dirs
        if (sorter != nullptr) std::sort(files.begin(), files.end(), sorter);
        if (partitioner != nullptr) std::stable_partition(files.begin(), files.end(), partitioner);
    }
}

void FileModelWorker::sortByModTime(QList<StatFileInfo> &files, bool reverse, int dirsFirstCount)
{
    sortFileList(files, dirsFirstCount,
                 [&](const StatFileInfo& a, const StatFileInfo& b) -> bool {
        // return true if a comes before b
        if (!reverse /* == default*/) {
            // STL sorts ascending (using operator<) by default.
            // We want newer dates first by default, i.e. descending.
            return a.lastModifiedStat() > b.lastModifiedStat();
        } else /* == reverse*/ {
            return a.lastModifiedStat() < b.lastModifiedStat();
        }
    });
}

void FileModelWorker::sortBySize(QList<StatFileInfo> &files, bool reverse, int dirsFirstCount)
{
    sortFileList(files, dirsFirstCount,
                 [&](const StatFileInfo& a, const StatFileInfo& b) -> bool {
        // return true if a comes before b
        if (!reverse /* == default*/) {
            // sort ascending (smallest files first) by default
            return (a.isDirAtEnd() ? a.dirSize() : a.size()) < (b.isDirAtEnd() ? b.dirSize() : b.size());
        } else /* == reverse*/ {
            return (a.isDirAtEnd() ? a.dirSize() : a.size()) > (b.isDirAtEnd() ? b.dirSize() : b.size());
        }
    });
}

void FileModelWorker::sortHiddenLast(QList<StatFileInfo> &files, int dirsFirstCount)
{
    sortFileList(files, dirsFirstCount, nullptr,
                 [&](const StatFileInfo& a) -> bool {
        return !a.getQFileInfo().isHidden();
    });
}

bool FileModelWorker::cancelIfCancelled()
{
    if (m_cancelled.loadAcquire() == Cancelled) {
        logMessage("warning: directory listing cancelled");
        return true;
    }
    return false;
}
