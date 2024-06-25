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

#ifndef SEARCHENGINE_H
#define SEARCHENGINE_H

#include <QDir>

class SearchWorker;
enum class SearchType;

/**
 * @brief The SearchEngine is a front-end for the SearchWorker class.
 * These two classes could be merged, but it is clearer to keep the background thread
 * in its own class.
 */
class SearchEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString dir READ dir() WRITE setDir(QString) NOTIFY dirChanged())
    Q_PROPERTY(int maxResults MEMBER m_maxResults NOTIFY maxResultsChanged)
    Q_PROPERTY(bool running READ running() NOTIFY runningChanged())

public:
    explicit SearchEngine(QObject *parent = nullptr);
    ~SearchEngine();

    // property accessors
    QString dir() const { return m_dir; }
    void setDir(QString dir);
    bool running() const;

    // callable from QML
    Q_INVOKABLE void search(QString searchTerm);
    Q_INVOKABLE void filterDirectories(QString searchTerm);
    Q_INVOKABLE void filterEntries(QString searchTerm);
    Q_INVOKABLE void cancel();

signals:
    void dirChanged();
    void maxResultsChanged();
    void runningChanged();

    void progressChanged(QString directory);
    void matchFound(QString fullname, QString filename, QString absoluteDir,
                    QString fileIcon, QString fileKind, QString mimeType);
    void workerDone();
    void workerErrorOccurred(QString message, QString filename);

private slots:
    void emitMatchFound(QString fullpath);

private:
    void startSearch(QString searchTerm, SearchType type);
    int m_maxResults = {0}; // <= 0 for no restriction
    QString m_dir;
    QString m_errorMessage;
    SearchWorker *m_searchWorker;
};

#endif // SEARCHENGINE_H
