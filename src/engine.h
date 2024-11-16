/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014, 2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2019-2024 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef ENGINE_H
#define ENGINE_H

#include <functional>
#include <QDir>
#include <QVariant>

#include <QQmlEngine>
#include <QJSEngine>

#include "fileclipboardmodel.h"

class FileWorker;
template<typename T> class QFuture;
template<typename T> class QFutureWatcher;

/**
 * @brief Engine to handle file operations, settings and other generic functionality.
 */
class Engine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int progress READ progress() NOTIFY progressChanged())
    Q_PROPERTY(QString progressFilename READ progressFilename() NOTIFY progressFilenameChanged())

public:
    explicit Engine(QObject *parent = nullptr);
    ~Engine();

    // properties
    int progress() const { return m_progress; }
    QString progressFilename() const { return m_progressFilename; }

    // methods accessible from QML

    // async methods send signals when done or error occurs
    Q_INVOKABLE void deleteFiles(QStringList filenames);
    Q_INVOKABLE void pasteFiles(QStringList files, QString destDirectory, FileClipMode::Enum mode);

    /**
     * @brief Asynchronously calculate free/used disk space of a device.
     *
     * The function immediately returns a handle. Wait for the
     * diskSpaceInfoReady(handle, info) signal to get the actual information.
     *
     * @note The handle is only valid until the signal is sent.
     *
     * @param path Element used to identify the device.
     * @return signal handle
     */
    Q_INVOKABLE int requestDiskSpaceInfo(const QString& path);

    /**
     * @brief Asynchronously calculate size of files and folders.
     *
     * The function immediately returns a handle. Wait for the
     * fileSizeInfoReady(handle, info) signal to get the actual information.
     *
     * @note The handle is only valid until the signal is sent.
     *
     * @param paths Files and/or folders to process.
     * @return signal handle
     */
    Q_INVOKABLE int requestFileSizeInfo(const QStringList& paths);

    // cancel async methods
    Q_INVOKABLE void cancel();

    // returns error msg
    Q_INVOKABLE QString errorMessage() const { return m_errorMessage; }

    // synchronous methods
    Q_INVOKABLE bool exists(QString filename);
    Q_INVOKABLE QStringList readFile(QString filename);
    Q_INVOKABLE QString createDirectory(QString path, QString name);
    Q_INVOKABLE QString createFile(QString path, QString name);
    Q_INVOKABLE QStringList rename(QString fullOldFilename, QString newName);
    Q_INVOKABLE QString recreateLink(QString symlink, QString newTarget);
    Q_INVOKABLE QString chmod(QString path,
                              bool ownerRead, bool ownerWrite, bool ownerExecute,
                              bool groupRead, bool groupWrite, bool groupExecute,
                              bool othersRead, bool othersWrite, bool othersExecute);
    Q_INVOKABLE bool openNewWindow(QStringList arguments = QStringList()) const;
    Q_INVOKABLE bool pathIsDirectory(QString path) const;
    Q_INVOKABLE bool pathIsFile(QString path) const;
    Q_INVOKABLE bool pathIsFileOrDirectory(QString path) const;

    static QObject* qmlInstance(QQmlEngine* engine, QJSEngine* scriptEngine) {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);
        return new Engine;
    }

signals:
    void progressChanged();
    void progressFilenameChanged();
    void workerDone();
    void workerErrorOccurred(QString message, QString filename);
    void fileDeleted(QString fullname);

    /**
     * @brief Result of a requestDiskSpaceInfo(path) call.
     *
     * Info fields:
     *   1. success marker: not empty on success, empty on failure
     *   2. used percentage (e.g. "80" if the drive is 80% full)
     *   3. used to total ratio (e.g. "3.2 GiB/4 GiB")
     *   4. free space (e.g. "0.8 GiB")
     *
     * The result list always has four fields.
     * All fields are empty if the data could not be determined.
     *
     * @param handle
     * @param info
     */
    void diskSpaceInfoReady(int handle, QStringList info);

    /**
     * @brief Result of a requestFileSizeInfo(paths) call.
     *
     * Info fields:
     *   1. success marker: not empty on success, empty on failure
     *   2. combined disk usage (e.g. "2.1 GiB", falls back to "-")
     *   3. how many folders were counted? (e.g. "451", includes nested folders)
     *   4. how many files were counted? (e.g. "1984", includes nested files and symlinks)
     *
     * The result list always has four fields.
     * All fields are empty if the data could not be determined.
     *
     * @param handle
     * @param info
     */
    void fileSizeInfoReady(int handle, QStringList info);

private slots:
    void setProgress(int progress, QString filename);

private:
    QString createHexDump(char *buffer, int size, int bytesPerLine);
    QStringList makeStringList(QString msg, QString str = QString());

    int m_progress;
    QString m_progressFilename;
    QString m_errorMessage;
    FileWorker* m_fileWorker;

    int runDiskSpaceWorker(std::function<void(int, QStringList)> signal,
                           std::function<QStringList(void)> function);
    QList<QPair<QSharedPointer<QFutureWatcher<QStringList>>, QFuture<QStringList>>> m_diskSpaceWorkers;
};

#endif // ENGINE_H
