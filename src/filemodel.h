/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
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

#ifndef FILEMODEL_H
#define FILEMODEL_H

#include <functional>
#include <QAbstractListModel>
#include <QDir>
#include <QFileSystemWatcher>
#include <QTimer>

#include <libs/opal/propertymacros/property_macros.h>

#include "statfileinfo.h"
#include "filemodelworker.h"


class RawSettingsHandler;

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
    RW_PROPERTY_CUSTOM(QString, dir, Dir, "")
    RO_PROPERTY_CUSTOM(int, fileCount, 0)
    RO_PROPERTY(QString, errorMessage, "")
    RW_PROPERTY_CUSTOM(bool, active, Active, false)
    RO_PROPERTY(int, selectedFileCount, 0)
    RW_PROPERTY_CUSTOM(QString, filterString, FilterString, "")
    RO_PROPERTY(bool, busy, false)
    RO_PROPERTY(bool, partlyBusy, false)

public:
    explicit FileModel(QObject *parent = nullptr);
    ~FileModel();

    // methods needed by ListView
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    // property accessors
    void setDir(QString dir);
    int fileCount() const { return m_files.count(); }
    void setActive(bool active);
    void setFilterString(QString newFilter);

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
    Q_INVOKABLE void refreshFull(QString localPath = QStringLiteral(""));

    void refreshChangedItem(const QString &path);

private slots:
    void applyFilterString();
    void workerDone(FileModelWorker::Mode mode, QList<StatFileInfo> files);
    void workerErrorOccurred(QString message);
    void workerAddedEntry(int index, StatFileInfo file);
    void workerRemovedEntry(int index, StatFileInfo file);
    void workerChangedEntry(int entryIndex, StatFileInfo file);

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
    void updateLastRefreshedTimestamp();
    void clearModel();
    void setBusy(bool busy, bool partlyBusy);
    void setBusy(bool busy);

    void updateWatchedPath(const QString& path);
    void resetContentsWatcher();
    void switchToWatching();
    void switchToPolling();

    // internal state
    QList<StatFileInfo> m_files {};
    QHash<QString, int> m_filesIndex {};
    QString m_oldFilterString {};
    qint64 m_lastRefreshedTimestamp {-1};

    FileModelWorker* m_worker {nullptr};
    RawSettingsHandler* m_settings {nullptr};

    FileModelWorker::Mode m_scheduledRefresh = {FileModelWorker::Mode::NoneMode};
    bool m_initialFullRefreshDone {false};

    // Refreshing the model on file system changes:
    //
    // The current directory (m_dir) is monitered by the main file system
    // watcher (m_watcher) using inotify. It will trigger a partial refresh
    // when the directory changes, i.e. when files are added or removed.
    // However, it does not detect changes to individual files inside the directory.
    //
    // We use a second watcher to refresh the file list when an entry changes.
    // If this fails due to hardware restrictions or lacking permissions,
    // we fall back to dumb polling, i.e. we refresh the file list every few
    // seconds (c_pollingIntervalSecs).
    QFileSystemWatcher* m_watcher {nullptr};
    QFileSystemWatcher* m_contentsWatcher {nullptr};
    enum WatcherMode { Watching, Polling };
    WatcherMode m_currentWatcherMode {WatcherMode::Watching};
    QTimer* m_pollingTimer {nullptr};

    // TODO: find the interval that strikes the best balance between
    //       energy efficiency and perceived performance, i.e.
    //       don't burn the battery but still make it feel like
    //       changes are properly reflected
    const int c_pollingIntervalSecs {5}; // seconds
    const int c_switchToPollingThreshold {1000};
};

#endif // FILEMODEL_H
