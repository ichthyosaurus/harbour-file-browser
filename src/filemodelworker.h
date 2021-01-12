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

#ifndef FILEMODELWORKER_H
#define FILEMODELWORKER_H

#include <QThread>
#include <QDir>
#include <QList>
#include "statfileinfo.h"

class Settings;

/**
 * @brief This class loads filtered and sorted directory listings.
 */
class FileModelWorker : public QThread
{
    Q_OBJECT
    enum CancelStatus {
        Cancelled = 0, KeepRunning = 1
    };

public:
    enum Mode {
        NoneMode, FullMode, DiffMode
    };

    explicit FileModelWorker(QObject *parent = nullptr);
    ~FileModelWorker() override;
    void cancel();

    // call to start the thread
    void startReadFull(QString dir, QString nameFilter, Settings* settings);
    void startReadChanged(QList<StatFileInfo> oldEntries,
                          QString dir, QString nameFilter, Settings* settings);

signals:
    // one of these is emitted when thread ends
    void done(FileModelWorker::Mode mode, QList<StatFileInfo> entries);
    void error(QString message);
    void alreadyRunning();

    void entryAdded(int index, StatFileInfo file);
    void entryRemoved(int index, StatFileInfo file);

protected:
    void run() override;

private slots:
    void logError(QString message);
    void logMessage(QString message, bool markSilent = true);

private:
    void doStartThread(Mode mode, QList<StatFileInfo> oldEntries,
                       QString dir, QString nameFilter, Settings* settings);
    void doReadFull();
    void doReadDiff();

    bool verifyOrAbort();
    bool applySettings();
    bool filesContains(const QList<StatFileInfo> &files, const StatFileInfo &fileData) const;
    uint hashInfo(const StatFileInfo& f);
    void sortByModTime(QList<StatFileInfo>& files, bool reverse);

    // returns true if cancelled and emits an error
    bool cancelIfCancelled();

    QDir m_cachedDir = {""};
    bool m_cachedSortTime = {false};
    Settings* m_settings = {nullptr};
    FileModelWorker::Mode m_mode = {FullMode};
    QList<StatFileInfo> m_finalEntries = {};
    QList<StatFileInfo> m_oldEntries;
    QString m_dir = {""};
    QString m_nameFilter = {""};
    QAtomicInt m_cancelled = {KeepRunning}; // atomic so no locks needed
};

#endif // FILEMODELWORKER_H
