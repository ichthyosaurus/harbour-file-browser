/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
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

#ifndef FILEOPERATIONS_H
#define FILEOPERATIONS_H

#include <QThread>
#include <QHash>
#include <QSharedPointer>
#include <QAbstractListModel>

class FileOperationsHandler;
class FileWorker2 : public QObject {
    Q_OBJECT

public:
    enum Mode { Delete, Copy, Move, Symlink, Compress };
    enum ErrorType { None, FileExists, FileNotFound, Unknown };
    enum ErrorAction { Ask, Abort, Overwrite, Skip, OverwriteAll, SkipAll };
    enum Status { Enqueued = 0, Running, WaitingForFeedback, Paused, Cancelled, Finished };

    explicit FileWorker2(Mode mode, QStringList files, QStringList targets);
    ~FileWorker2();

    Q_ENUM(FileWorker2::Mode)
    Q_ENUM(FileWorker2::ErrorType)
    Q_ENUM(FileWorker2::ErrorAction)
    Q_ENUM(FileWorker2::Status)

    static void registerMetaTypes();

signals:
    void statusChanged(FileWorker2::Status status);
    void progressChanged(int current, int of);
    void errorOccurred(FileWorker2::ErrorType type, QString message, QString file = QLatin1String(""));
    void finished(bool success);

public slots:
    void cancel();
    void pause();
    void carryOn(FileWorker2::ErrorAction feedback = FileWorker2::ErrorAction::Abort);

private slots:
    void process();

private:
    bool checkContinue();

    QAtomicInt m_status {Status::Enqueued};
    QAtomicInt m_errorAction {ErrorAction::Ask};

    Mode m_mode;
    QStringList m_files;
    QStringList m_targets;

    friend FileOperationsHandler;
};

class FileOperationsHandler : QObject {
    Q_OBJECT

public:
    explicit FileOperationsHandler(QObject* parent = nullptr);
    virtual ~FileOperationsHandler();

    class Task {
    public:
        explicit Task(int handle, QSharedPointer<QThread> thread, QSharedPointer<FileWorker2> worker,
                      FileWorker2::Mode mode, QStringList files, QStringList targets) :
            m_handle(handle), m_thread(thread), m_worker(worker),
            m_mode(mode), m_files(files), m_targets(targets) {}
        Task() : m_handle(-1), m_thread(nullptr), m_worker(nullptr),
            m_mode(FileWorker2::Mode::Copy), m_files({}), m_targets({}) {}

        int handle() const { return m_handle; }
        FileWorker2::Mode mode() const { return m_mode; }
        const QStringList& files() const { return m_files; }
        const QStringList& targets() const { return m_targets; }
        FileWorker2::Status status() const { return static_cast<FileWorker2::Status>(m_worker->m_status.loadAcquire()); }

        FileWorker2* get() { return m_worker.data(); }
        void run() {
            if (m_thread->isRunning()) return;
            m_thread->start();
        }

        // must be handled outside of this class using connections!
        int progressCurrent {0};
        int progressOf {0};
        FileWorker2::ErrorType errorType {FileWorker2::ErrorType::None};
        QString errorMessage {};
        QString errorFile {};

    private:
        int m_handle {-1};
        QSharedPointer<QThread> m_thread;
        QSharedPointer<FileWorker2> m_worker;

        FileWorker2::Mode m_mode;
        QStringList m_files;
        QStringList m_targets;

        friend FileOperationsHandler;
    };

    Task& makeTask(FileWorker2::Mode mode, QStringList files, QStringList targets, bool autoDelete);
    void forgetTask(int handle);
    const QList<int>& getTasks() const;

    bool haveTask(int handle);
    Task& getTask(int handle);

private:
    QAtomicInt m_count {0};

    QList<int> m_handles;
    QHash<int, Task> m_tasks;
};

class FileOperationsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit FileOperationsModel(QObject *parent = nullptr);
    ~FileOperationsModel();

    // methods needed by ListView
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    // methods accessible from QML
    Q_INVOKABLE int deleteFiles(QStringList files);
    Q_INVOKABLE int copyFiles(QStringList files, QStringList targetDirs);
    Q_INVOKABLE int moveFiles(QStringList files, QString targetDir);
    Q_INVOKABLE int symlinkFiles(QStringList files, QStringList targetDirs);
    Q_INVOKABLE int compressFiles(QStringList files, QString targetFile);

    Q_INVOKABLE void cancelTask(int handle);
    Q_INVOKABLE void pauseTask(int handle);
    Q_INVOKABLE void continueTask(int handle, FileWorker2::ErrorAction errorAction = FileWorker2::ErrorAction::Ask);
    Q_INVOKABLE void dismissTask(int handle); // to remove finished tasks from the list

private:
    int addTask(FileWorker2::Mode mode, QStringList files, QStringList targets);

    FileOperationsHandler* m_handler;
};


#endif // FILEOPERATIONS_H
