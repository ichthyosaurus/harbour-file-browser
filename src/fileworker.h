/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014, 2019 Kari Pihkala
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

#ifndef FILEWORKER_H
#define FILEWORKER_H

#include <QThread>
#include <QDir>

/**
 * @brief FileWorker does delete, copy and move files in the background.
 */
class FileWorker : public QThread
{
    Q_OBJECT

public:
    explicit FileWorker(QObject *parent = nullptr);
    ~FileWorker();

    // call these to start the thread, returns false if start failed
    void startDeleteFiles(QStringList filenames);
    void startCopyFiles(QStringList filenames, QString destDirectory);
    void startMoveFiles(QStringList filenames, QString destDirectory);
    void startSymlinkFiles(QStringList filenames, QString destDirectory);

    void cancel();

signals: // signals, can be connected from a thread to another
    void progressChanged(int progress, QString filename);

    // one of these is emitted when thread ends
    void done();
    void errorOccurred(QString message, QString filename);

    void fileDeleted(QString fullname);

protected:
    void run() Q_DECL_OVERRIDE;

private:
    enum Mode {
        DeleteMode, CopyMode, MoveMode, SymlinkMode
    };
    enum CancelStatus {
        Cancelled = 0, KeepRunning = 1
    };

    bool validateFilenames(const QStringList &filenames);

    QString deleteFile(QString filename);
    void deleteFiles();
    void copyOrMoveFiles();
    void symlinkFiles();
    QString copyDirRecursively(QString srcDirectory, QString destDirectory);
    QString copyOverwrite(QString src, QString dest);

    FileWorker::Mode m_mode;
    QStringList m_filenames;
    QString m_destDirectory;
    QAtomicInt m_cancelled; // atomic so no locks needed
    int m_progress;
};

#endif // FILEWORKER_H
