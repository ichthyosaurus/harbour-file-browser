/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2019 Mirian Margiani
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
    connect(m_searchWorker, SIGNAL(matchFound(QString)), this, SLOT(emitMatchFound(QString)));

    // pass worker end signals to QML
    connect(m_searchWorker, SIGNAL(progressChanged(QString)),
            this, SIGNAL(progressChanged(QString)));
    connect(m_searchWorker, SIGNAL(done()), this, SIGNAL(workerDone()));
    connect(m_searchWorker, SIGNAL(errorOccurred(QString, QString)),
            this, SIGNAL(workerErrorOccurred(QString, QString)));

    connect(m_searchWorker, SIGNAL(started()), this, SIGNAL(runningChanged()));
    connect(m_searchWorker, SIGNAL(finished()), this, SIGNAL(runningChanged()));
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
    // if search term is not empty, then restart search
    if (!searchTerm.isEmpty()) {
        m_searchWorker->cancel();
        m_searchWorker->wait();
        m_searchWorker->startSearch(m_dir, searchTerm);
    }
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
