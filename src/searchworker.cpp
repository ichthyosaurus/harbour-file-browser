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

void SearchWorker::startSearch(QString directory, QString searchTerm)
{
    if (isRunning()) {
        emit errorOccurred(tr("Search already in progress"), "");
        return;
    }
    if (directory.isEmpty() || searchTerm.isEmpty()) {
        emit errorOccurred(tr("Bad search parameters"), "");
        return;
    }

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
    QString errMsg = searchRecursively(m_directory, m_searchTerm.toLower());
    if (!errMsg.isEmpty())
        emit errorOccurred(errMsg, m_currentDirectory);

    emit progressChanged("");
    emit done();
}

QString SearchWorker::searchRecursively(QString directory, QString searchTerm)
{
    // skip some system folders - they don't really have any interesting stuff
    if (directory.startsWith("/proc") ||
            directory.startsWith("/sys/block"))
        return QString();

    QDir dir(directory);
    if (!dir.exists())  // skip "non-existent" directories (found in /dev)
        return QString();

    // update progress
    m_currentDirectory = directory;
    emit progressChanged(m_currentDirectory);

    QSettings settings;
    bool hiddenSetting = settings.value("View/HiddenFilesShown", false).toBool();
    QDir::Filter hidden = hiddenSetting ? QDir::Hidden : static_cast<QDir::Filter>(0);

    // search dirs
    QStringList names = dir.entryList(QDir::NoDotAndDotDot | QDir::AllDirs | QDir::System | hidden);
    for (int i = 0 ; i < names.count() ; ++i) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled)
            return QString();

        QString filename = names.at(i);
        QString fullpath = dir.absoluteFilePath(filename);

        if (filename.toLower().indexOf(searchTerm) >= 0)
            emit matchFound(fullpath);

        QFileInfo info(fullpath); // skip symlinks to prevent infinite loops
        if (info.isSymLink())
            continue;

        QString errmsg = searchRecursively(fullpath, searchTerm);
        if (!errmsg.isEmpty())
            return errmsg;
    }

    // search files
    names = dir.entryList(QDir::Files | hidden);
    for (int i = 0 ; i < names.count() ; ++i) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled)
            return QString();

        QString filename = names.at(i);
        QString fullpath = dir.absoluteFilePath(filename);

        if (filename.toLower().indexOf(searchTerm) >= 0)
            emit matchFound(fullpath);
    }

    return QString();
}
