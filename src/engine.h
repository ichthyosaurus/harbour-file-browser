/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014, 2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
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

#ifndef ENGINE_H
#define ENGINE_H

#include <QDir>
#include <QVariant>

class FileWorker;
template<typename T> class QFuture;
template<typename T> class QFutureWatcher;

/**
 * @brief Engine to handle file operations, settings and other generic functionality.
 */
class Engine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int clipboardCount READ clipboardCount() NOTIFY clipboardCountChanged())
    Q_PROPERTY(int clipboardContainsCopy READ clipboardContainsCopy WRITE setClipboardContainsCopy NOTIFY clipboardContainsCopyChanged)
    Q_PROPERTY(QStringList clipboardContents READ clipboardContents NOTIFY clipboardContentsChanged)
    Q_PROPERTY(int progress READ progress() NOTIFY progressChanged())
    Q_PROPERTY(QString progressFilename READ progressFilename() NOTIFY progressFilenameChanged())

public:
    explicit Engine(QObject *parent = nullptr);
    ~Engine();

    // properties
    int clipboardCount() const { return m_clipboardFiles.count(); }
    bool clipboardContainsCopy() const { return m_clipboardContainsCopy; }
    void setClipboardContainsCopy(bool newValue) { m_clipboardContainsCopy = newValue; emit clipboardContainsCopyChanged(); }
    QStringList clipboardContents() const { return m_clipboardFiles; }
    int progress() const { return m_progress; }
    QString progressFilename() const { return m_progressFilename; }

    // methods accessible from QML

    // async methods send signals when done or error occurs
    Q_INVOKABLE void deleteFiles(QStringList filenames);
    Q_INVOKABLE void cutFiles(QStringList filenames);
    Q_INVOKABLE void copyFiles(QStringList filenames);
    Q_INVOKABLE void clearClipboard();
    Q_INVOKABLE void forgetClipboardEntry(QString entry);
    // returns a list of existing files if clipboard files already exist
    // or an empty list if no existing files
    Q_INVOKABLE QStringList listExistingFiles(QString destDirectory);
    Q_INVOKABLE void pasteFiles(QString destDirectory, bool asSymlinks = false);

    // calculate disk space ansynchronously, sends diskSpaceInfoReady on success
    // use diskSpace(path) as a synchronous alternative
    Q_INVOKABLE void requestDiskSpaceInfo(QString path);

    // cancel async methods
    Q_INVOKABLE void cancel();

    // returns error msg
    Q_INVOKABLE QString errorMessage() const { return m_errorMessage; }

    // file paths
    Q_INVOKABLE QString androidDataPath() const;
    Q_INVOKABLE QVariantList externalDrives() const;
    Q_INVOKABLE QString storageSettingsPath(); // caching, thus non-const
    Q_INVOKABLE QString pdfViewerPath(); // caching, thus non-const

    // synchronous methods
    Q_INVOKABLE bool runningAsRoot();
    Q_INVOKABLE bool exists(QString filename);
    Q_INVOKABLE QStringList fileSizeInfo(QStringList paths);
    Q_INVOKABLE QStringList diskSpace(QString path);
    Q_INVOKABLE QStringList readFile(QString filename);
    Q_INVOKABLE QString mkdir(QString path, QString name);
    Q_INVOKABLE QStringList rename(QString fullOldFilename, QString newName);
    Q_INVOKABLE QString chmod(QString path,
                              bool ownerRead, bool ownerWrite, bool ownerExecute,
                              bool groupRead, bool groupWrite, bool groupExecute,
                              bool othersRead, bool othersWrite, bool othersExecute);
    Q_INVOKABLE bool openNewWindow(QStringList arguments = QStringList()) const;
    Q_INVOKABLE bool pathIsDirectory(QString path) const;
    Q_INVOKABLE bool pathIsFile(QString path) const;

signals:
    void clipboardCountChanged();
    void clipboardContainsCopyChanged();
    void clipboardContentsChanged();
    void progressChanged();
    void progressFilenameChanged();
    void workerDone();
    void workerErrorOccurred(QString message, QString filename);
    void fileDeleted(QString fullname);

    void diskSpaceInfoReady(QString path, QStringList info);

private slots:
    void setProgress(int progress, QString filename);

private:
    QMap<QString, QString> mountPoints() const;
    QString createHexDump(char *buffer, int size, int bytesPerLine);
    QStringList makeStringList(QString msg, QString str = QString());
    bool isUsingBusybox(QString forCommand);

    QStringList m_clipboardFiles;
    bool m_clipboardContainsCopy;
    int m_progress;
    QString m_progressFilename;
    QString m_errorMessage;
    FileWorker* m_fileWorker;

    QList<QPair<QSharedPointer<QFutureWatcher<QStringList>>, QFuture<QStringList>>> m_diskSpaceWorkers;

    // cached paths that we assume won't change during runtime
    QString m_storageSettingsPath = {QStringLiteral("")};
    QString m_pdfViewerPath = {QStringLiteral("")};

    // don't use these directly, use isUsingBusybox() instead
    QStringList m__isUsingBusybox;
    bool m__checkedBusybox;
};

#endif // ENGINE_H
