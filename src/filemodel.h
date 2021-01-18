/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
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

#ifndef FILEMODEL_H
#define FILEMODEL_H

#include <functional>
#include <QAbstractListModel>
#include <QDir>
#include <QFileSystemWatcher>
#include "statfileinfo.h"
#include "filemodelworker.h"

class Settings;

/**
 * @brief The FileModel class can be used as a model in a ListView to display a list of files
 * in the current directory. It has methods to change the current directory and to access
 * file info.
 * It also actively monitors the directory. If the directory changes, then the model is
 * updated automatically if active is true. If active is false, then the directory is
 * updated when active becomes true.
 */
class FileModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString dir READ dir() WRITE setDir(QString) NOTIFY dirChanged())
    Q_PROPERTY(int fileCount READ fileCount() NOTIFY fileCountChanged())
    Q_PROPERTY(int filteredFileCount READ filteredFileCount() NOTIFY filteredFileCountChanged())
    Q_PROPERTY(QString errorMessage READ errorMessage() NOTIFY errorMessageChanged())
    Q_PROPERTY(bool active READ active() WRITE setActive(bool) NOTIFY activeChanged())
    Q_PROPERTY(int selectedFileCount READ selectedFileCount() NOTIFY selectedFileCountChanged())
    Q_PROPERTY(QString filterString READ filterString() WRITE setFilterString(QString) NOTIFY filterStringChanged())
    Q_PROPERTY(bool busy READ busy() NOTIFY busyChanged())
    Q_PROPERTY(bool partlyBusy READ partlyBusy() NOTIFY partlyBusyChanged())

public:
    explicit FileModel(QObject *parent = nullptr);
    ~FileModel();

    // methods needed by ListView
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    // property accessors
    QString dir() const { return m_dir; }
    void setDir(QString dir);
    int fileCount() const;
    int filteredFileCount() const;
    QString errorMessage() const;
    bool active() const { return m_active; }
    void setActive(bool active);
    int selectedFileCount() const { return m_selectedFileCount; }
    QString filterString() const { return m_filterString; }
    void setFilterString(QString newFilter);
    bool busy() const { return m_busy; }
    bool partlyBusy() const { return m_partlyBusy; }

    // methods accessible from QML
    Q_INVOKABLE QString appendPath(QString dirName);
    Q_INVOKABLE QString parentPath();
    Q_INVOKABLE QString fileNameAt(int fileIndex);
    Q_INVOKABLE QString mimeTypeAt(int fileIndex);

    // file selection
    Q_INVOKABLE void toggleSelectedFile(int fileIndex);
    Q_INVOKABLE void clearSelectedFiles();
    Q_INVOKABLE void selectAllFiles();
    Q_INVOKABLE void selectRange(int firstIndex, int lastIndex, bool selected = true);
    Q_INVOKABLE QStringList selectedFiles() const;
    Q_INVOKABLE void markSelectedAsDoomed();
    Q_INVOKABLE void markAsDoomed(QStringList absoluteFilePaths);

public slots:
    // reads the directory and inserts/removes model items as needed
    Q_INVOKABLE void refresh();
    // reads the directory and sets all model items
    Q_INVOKABLE void refreshFull(QString localPath = QString());

signals:
    void dirChanged();
    void fileCountChanged();
    void filteredFileCountChanged();
    void errorMessageChanged();
    void activeChanged();
    void selectedFileCountChanged();
    void filterStringChanged();
    void busyChanged();
    void partlyBusyChanged();

private slots:
    void applyFilterString();
    void workerDone(FileModelWorker::Mode mode, QList<StatFileInfo> files);
    void workerErrorOccurred(QString message);
    void workerAddedEntry(int index, StatFileInfo file);
    void workerRemovedEntry(int index, StatFileInfo file);

private:
    /**
     * @brief (Re-)Reads all directory contents and rebuilds the model.
     * The model will be cleared and completely rebuilt.
     * This method is called when doing a full refresh,
     * changin active mode, or changing the current directory.
     */
    void doUpdateAllEntries();

    /**
     * @brief Rereads directory contents and updates the model.
     * All contents will be read but only changed entries will
     * be updated in the model.
     * This method is called when normally refreshing a view.
     */
    void doUpdateChangedEntries();
    void doMarkAsDoomed(QList<StatFileInfo>& files, std::function<bool(StatFileInfo&)> checker);

    void updateFileCounts();
    void clearModel();
    void setBusy(bool busy, bool partlyBusy);
    void setBusy(bool busy);

    QString m_dir;
    QString m_filterString = {""};
    QString m_oldFilterString = {""};
    QList<StatFileInfo> m_files;
    int m_selectedFileCount;
    int m_matchedFileCount;
    QString m_errorMessage;
    bool m_active;
    QFileSystemWatcher *m_watcher;
    Settings* m_settings;
    FileModelWorker* m_worker;
    FileModelWorker::Mode m_scheduledRefresh = {FileModelWorker::Mode::NoneMode};
    bool m_busy = {false};
    bool m_partlyBusy = {false};
};

#endif // FILEMODEL_H
