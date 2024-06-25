/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
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

#include "searchengine.h"
#include <QMimeDatabase>
#include <QDateTime>
#include "searchworker.h"
#include "statfileinfo.h"
#include "globals.h"

SearchEngine::SearchEngine(QObject *parent) :
    QObject(parent)
{
    m_dir = "";
    m_searchWorker = new SearchWorker;
    connect(m_searchWorker, &SearchWorker::matchFound, this, &SearchEngine::emitMatchFound);

    // pass worker end signals to QML
    connect(m_searchWorker, &SearchWorker::progressChanged, this, &SearchEngine::progressChanged);
    connect(m_searchWorker, &SearchWorker::done, this, &SearchEngine::workerDone);
    connect(m_searchWorker, &SearchWorker::errorOccurred, this, &SearchEngine::workerErrorOccurred);

    connect(m_searchWorker, &QThread::started, this, &SearchEngine::runningChanged);
    connect(m_searchWorker, &QThread::finished, this, &SearchEngine::runningChanged);
}

SearchEngine::~SearchEngine()
{
    // is this the way to force stop the worker thread?
    m_searchWorker->cancel(); // stop possibly running background thread
    m_searchWorker->wait();   // wait until thread stops
    delete m_searchWorker;    // delete it
}

void SearchEngine::setDir(QString dir)
{
    if (m_dir == dir)
        return;

    m_dir = dir;

    emit dirChanged();
}

bool SearchEngine::running() const
{
    return m_searchWorker->isRunning();
}

void SearchEngine::search(QString searchTerm)
{
    startSearch(searchTerm, SearchType::FilesRecursive);
}

void SearchEngine::filterDirectories(QString searchTerm)
{
    startSearch(searchTerm, SearchType::DirectoriesShallow);
}

void SearchEngine::filterEntries(QString searchTerm)
{
    startSearch(searchTerm, SearchType::EntriesShallow);
}

void SearchEngine::cancel()
{
    m_searchWorker->cancel();
}

void SearchEngine::emitMatchFound(QString fullpath)
{
    StatFileInfo info(fullpath);
    QMimeDatabase db;
    QString mimeType = db.mimeTypeForFile(fullpath).name();
    emit matchFound(fullpath, info.fileName(), info.absoluteDir().absolutePath(),
                    infoToIconName(info), info.kind(), mimeType);
}

void SearchEngine::startSearch(QString searchTerm, SearchType type)
{
    // if search term is not empty or we are only filtering
    // entries, then restart search
    if (   type == SearchType::DirectoriesShallow
        || type == SearchType::EntriesShallow
        || !searchTerm.isEmpty()) {
        m_searchWorker->cancel();
        m_searchWorker->wait();
        m_searchWorker->startSearch(m_dir, searchTerm, type, m_maxResults);
    }
}
