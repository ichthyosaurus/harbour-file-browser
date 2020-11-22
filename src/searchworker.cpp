/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2018 Marcin Mielniczuk
 * SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
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

#include "searchworker.h"
#include <QDateTime>
#include <QSettings>
#include "globals.h"

SearchWorker::SearchWorker(QObject *parent) :
    QThread(parent),
    m_cancelled(NotCancelled)
{
}

SearchWorker::~SearchWorker()
{
}

void SearchWorker::startSearch(QString directory, QString searchTerm, SearchType type, int maxResults)
{
    if (isRunning()) {
        emit errorOccurred(tr("Search already in progress"), "");
        return;
    }
    if (directory.isEmpty() ||
            (type == SearchType::FilesRecursive && searchTerm.isEmpty())) {
        emit errorOccurred(tr("Bad search parameters"), "");
        return;
    }

    m_maxResults = maxResults;
    m_type = type;
    m_directory = directory;
    m_searchTerm = searchTerm;
    m_currentDirectory = directory;
    m_cancelled.storeRelease(NotCancelled);
    start();
}

void SearchWorker::cancel()
{
    m_cancelled.storeRelease(Cancelled);
}

void SearchWorker::run()
{
    QString errMsg;
    switch (m_type) {
    case SearchType::FilesRecursive:
        errMsg = searchFilesRecursive(m_directory, m_searchTerm.toLower());
        break;
    case SearchType::DirectoriesShallow:
        errMsg = searchDirectoriesShallow(m_directory, m_searchTerm.toLower());
        break;
    }

    if (!errMsg.isEmpty()) emit errorOccurred(errMsg, m_currentDirectory);
    emit progressChanged("");
    emit done();
}

QString SearchWorker::searchFilesRecursive(QString directory, QString searchTerm, int lastCount)
{
    // skip some system folders - they don't really have any interesting stuff
    if (directory.startsWith("/proc") || directory.startsWith("/sys/block")) {
        return QString();
    }

    QDir dir(directory);
    if (!dir.exists()) return QString(); // skip "non-existent" directories (found in /dev)

    // update progress
    m_currentDirectory = directory;
    emit progressChanged(m_currentDirectory);

    QSettings settings;
    bool hiddenSetting = settings.value("View/HiddenFilesShown", false).toBool();
    QDir::Filter hidden = hiddenSetting ? QDir::Hidden : static_cast<QDir::Filter>(0);

    int count = 0;
    if (lastCount > 0) count = lastCount;
    if (m_maxResults > 0 && count >= m_maxResults)  return QString();

    // search dirs
    QStringList names = dir.entryList(QDir::NoDotAndDotDot | QDir::AllDirs | QDir::System | hidden);
    for (auto filename : names) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            return QString();
        }

        QString fullpath = dir.absoluteFilePath(filename);
        if (filename.contains(searchTerm, Qt::CaseInsensitive)) {
            count++;
            emit matchFound(fullpath);
            if (m_maxResults > 0 && count >= m_maxResults) return QString();
        }

        QFileInfo info(fullpath); // skip symlinks to prevent infinite loops
        if (info.isSymLink()) continue;

        QString errorMessage = searchFilesRecursive(fullpath, searchTerm, count);
        if (!errorMessage.isEmpty()) return errorMessage;
    }

    // search files
    names = dir.entryList(QDir::Files | hidden);
    for (auto filename : names) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            return QString();
        }

        QString fullpath = dir.absoluteFilePath(filename);
        if (filename.contains(searchTerm, Qt::CaseInsensitive)) {
            count++;
            emit matchFound(fullpath);
            if (m_maxResults > 0 && count >= m_maxResults) return QString();
        }
    }

    return QString();
}

QString SearchWorker::searchDirectoriesShallow(QString directory, QString searchTerm)
{
    QDir dir(directory);
    if (!dir.exists()) return QString(); // skip "non-existent" directories (found in /dev)

    // update progress
    m_currentDirectory = directory;
    emit progressChanged(m_currentDirectory);

    bool hiddenSetting;
    if (searchTerm.startsWith('.')) {
        // always include hidden directories if we explicitly search for one
        hiddenSetting = true;
    } else {
        QSettings settings;
        hiddenSetting = settings.value("View/HiddenFilesShown", false).toBool();
    }
    QDir::Filter hidden = hiddenSetting ? QDir::Hidden : static_cast<QDir::Filter>(0);

    // search dirs
    int count = 0;
    QStringList names = dir.entryList(QDir::NoDotAndDotDot | QDir::AllDirs | QDir::System | hidden);
    for (auto filename : names) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            return QString();
        }
        QString fullpath = dir.absoluteFilePath(filename);
        if (searchTerm.isEmpty() || filename.contains(searchTerm, Qt::CaseInsensitive)) {
            count++;
            emit matchFound(fullpath);
            if (m_maxResults > 0 && count >= m_maxResults) break; // we're not recursive
        }
    }

    return QString();
}
