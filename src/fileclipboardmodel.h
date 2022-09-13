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

#ifndef FILECLIPBOARDMODEL_H
#define FILECLIPBOARDMODEL_H

#include <QAbstractListModel>
#include <QHash>
#include "filedata.h"

class FileClipMode {
    Q_GADGET
public:
    enum Mode { Copy, Cut };
    Q_ENUM(Mode) // using "FileClipMode::Mode" would make it "undefined" in QML
};

class FileClipboardModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int historyCount READ rowCount NOTIFY historyCountChanged)
    Q_PROPERTY(int currentCount READ currentCount NOTIFY currentCountChanged)
    Q_PROPERTY(FileClipMode::Mode currentMode READ currentMode WRITE setCurrentMode NOTIFY currentModeChanged)
    Q_PROPERTY(QStringList currentPaths READ currentPaths WRITE setCurrentPaths NOTIFY currentPathsChanged)

public:
    explicit FileClipboardModel(QObject *parent = nullptr);
    ~FileClipboardModel();

    // methods needed by ListView
    int rowCount(const QModelIndex& parent = QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    int currentCount() const;
    FileClipMode::Mode currentMode() const;
    void setCurrentMode(FileClipMode::Mode newCurrentMode);
    const QStringList& currentPaths() const;
    void setCurrentPaths(QStringList newPaths);

    // methods callable from QML
    Q_INVOKABLE void forgetPath(int groupIndex, QString path);
    Q_INVOKABLE void forgetGroup(int groupIndex);
    Q_INVOKABLE void selectGroup(int groupIndex);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void clearCurrent();

    Q_INVOKABLE QStringList listExistingFiles(QString destDirectory, bool ignoreInCurrentDir = true, bool getNamesOnly = true);

signals:
    void historyCountChanged();
    void currentCountChanged();
    void currentModeChanged();
    void currentPathsChanged();

private:
    class ClipboardGroup {
    public:
        bool forgetEntry(int index);
        bool forgetEntry(QString path);

        bool setEntries(const QStringList& paths);
        const QStringList& paths() const { return m_paths; }
        int count() const { return m_count; }

        FileClipMode::Mode mode() const;
        bool setMode(FileClipMode::Mode newMode); // return true if changed

    private:
        int m_count {0};
        QStringList m_paths {};
        FileClipMode::Mode m_mode {FileClipMode::Copy};
    };

    int m_historyCount {};
    QList<ClipboardGroup> m_entries {};
    const QStringList m_emptyList {};
};

class FileClipboard : public QObject
{
    Q_OBJECT
    Q_PROPERTY(FileClipboardModel* model READ model CONSTANT)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(FileClipMode::Mode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(QStringList paths READ paths WRITE setPaths NOTIFY pathsChanged)
    Q_DISABLE_COPY(FileClipboard)

public:
    FileClipboard(QObject* parent = nullptr);
    ~FileClipboard();

    // methods callable from QML
    Q_INVOKABLE void forgetPath(QString path);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QStringList listExistingFiles(QString destDirectory, bool ignoreInCurrentDir = true, bool getNamesOnly = true);

    FileClipboardModel* model() const;
    int count() const;
    FileClipMode::Mode mode() const;
    void setMode(FileClipMode::Mode newMode);
    const QStringList &paths() const;
    void setPaths(const QStringList &newPaths);

signals:
    void countChanged();
    void modeChanged();
    void pathsChanged();

private:
    FileClipboardModel* m_model;
};

#endif // FILECLIPBOARDMODEL_H
