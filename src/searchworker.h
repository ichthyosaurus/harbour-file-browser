/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2018 Marcin Mielniczuk
 * SPDX-FileCopyrightText: 2020 Mirian Margiani
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

#ifndef SEARCHWORKER_H
#define SEARCHWORKER_H

#include <QThread>
#include <QDir>

/**
 * @brief The SearchType enum declares what kind of search will be started.
 *
 * @li FilesRecursive: search recursively for all files and folders
 * @li DirectoriesShallow: search for matching folders in the current directory
 */
enum class SearchType {
    FilesRecursive = 0, DirectoriesShallow
};

/**
 * @brief SearchWorker does searching in the background.
 */
class SearchWorker : public QThread
{
    Q_OBJECT

public:
    explicit SearchWorker(QObject *parent = nullptr);
    ~SearchWorker();

    void startSearch(QString directory, QString searchTerm, SearchType type);

    void cancel();

signals: // signals, can be connected from a thread to another
    void progressChanged(QString directory);
    void matchFound(QString fullname);

    // one of these is emitted when thread ends
    void done();
    void errorOccurred(QString message, QString filename);

protected:
    void run() Q_DECL_OVERRIDE;

private:
    enum CancelStatus {
        Cancelled = 0, NotCancelled = 1
    };

    QString searchFilesRecursive(QString directory, QString searchTerm);
    QString searchDirectoriesShallow(QString directory, QString searchTerm);

    SearchType m_type;
    QString m_directory;
    QString m_searchTerm;
    QAtomicInt m_cancelled; // atomic so no locks needed
    QString m_currentDirectory;
};

#endif // SEARCHWORKER_H
