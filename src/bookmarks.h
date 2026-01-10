/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2020-2026 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef BOOKMARKS_H
#define BOOKMARKS_H

#include <QVariant>
#include <QMap>
#include <QHash>
#include <QMutex>
#include <QSharedPointer>
#include <QPointer>
#include <QAbstractListModel>
#include <QObject>

#include <libs/opal/propertymacros/property_macros.h>

#include "configfilemonitor.h"
#include "enumcontainer.h"

// group Device includes everything that should show disk space info
// - it is *not* strictly limited to physical devices or partitions
CREATE_ENUM(BookmarkGroup, Temporary, Location, External, Bookmark, Device)
DECLARE_ENUM_REGISTRATION_FUNCTION(Bookmarks)


// Allows watching a single path, notifying when a bookmark
// is added, removed, or renamed.
//
// Changing the status manually is possible only through setMarked()
// and rename(), to avoid accidents.
class BookmarkWatcher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(bool marked READ marked NOTIFY markedChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)

public:
    explicit BookmarkWatcher(QObject* parent = nullptr);
    ~BookmarkWatcher();

    bool marked();
    QString path() const { return m_path; }
    void setPath(QString path);
    QString name();
    void refresh();

    Q_INVOKABLE void setMarked(bool active) const;
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void rename(QString newName) const;

signals:
    void markedChanged();
    void pathChanged();
    void nameChanged();

private:
    QString m_path;
};


class LocationAlternative {
    Q_GADGET
    RO_PROPERTY_GADGET(QString, name, "");
    RO_PROPERTY_GADGET(QString, path, "");
    RO_PROPERTY_GADGET(QString, device, "");

public:
    LocationAlternative() = default;
    LocationAlternative(QString name, QString path, QString device)
        : m_name(name), m_path(path), m_device(device) {}
    ~LocationAlternative() = default;

    static QVariantList makeVariantList(const QList<LocationAlternative>& list);
    static QStringList makeDevicesList(const QList<LocationAlternative>& list);
};


/**
 * @brief The BookmarksModel class provides a list of all currently configured bookmarks.
 *
 * Changes to the model are immediately stored on disk. The
 * model re-reads the file automatically if the file changes.
 *
 * This class should not be used directly. Instead, use the
 * "bookmarks" property on the GlobalSettings singleton in QML.
 */
class BookmarksModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit BookmarksModel(QObject *parent = nullptr);
    ~BookmarksModel();

    // methods needed by ListView
    Q_INVOKABLE int rowCount(const QModelIndex& parent = QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    // methods for handling user defined bookmarks from QML
    Q_INVOKABLE void add(QString path, QString name = QStringLiteral());
    Q_INVOKABLE void addTemporary(QString path, QString name = QStringLiteral());

    Q_INVOKABLE void remove(QString path);
    Q_INVOKABLE void removeTemporary(QString path);

    Q_INVOKABLE void clearTemporary();
    Q_INVOKABLE void sortFilter(QVariantList order); // list of BookmarkGroup::Enum
    Q_INVOKABLE void selectAlternative(const QModelIndex& idx, QString alternative);

    Q_INVOKABLE void move(int fromIndex, int toIndex, bool saveImmediately = true);
    Q_INVOKABLE void rename(QString path, QString newName, bool saveImmediately = true);
    Q_INVOKABLE void reset(QString path, QString newPath, bool saveImmediately = true);
    Q_INVOKABLE bool hasBookmark(QString path) const;
    Q_INVOKABLE int findUserDefinedIndex(QString path) const;
    Q_INVOKABLE void save();

    Q_INVOKABLE QStringList pathsForIndexes(const QModelIndexList& indexes);

    void registerWatcher(QString path, QPointer<BookmarkWatcher> mark);
    void unregisterWatcher(QString path, QPointer<BookmarkWatcher> mark);
    QString getBookmarkName(QString path) const;

    static BookmarksModel* instance() {
        if (s_globalInstance.isNull()) s_globalInstance.reset(new BookmarksModel());
        return s_globalInstance.data();
    }

signals:
    void temporaryAdded(QModelIndex modelIndex, int row);

public slots:
    void reload(bool keepTemporary = false);

private slots:
    void updateExternalDevices();
    void updateStandardLocations(const QList<LocationAlternative>& newExternalPaths, const uint& lostPathsCount);
    void reloadIgnoredMounts();

private:
    void notifyWatchers(const QString& path);

    void addUserDefined(QString path, QString name, bool permanent);
    void removeUserDefined(QString path, bool permanent);

    struct BookmarkItem {
        BookmarkItem(
            BookmarkGroup::Enum group,
            QString name,
            QString icon,
            QString path,
            QList<LocationAlternative> alternatives,
            bool showSize,
            bool userDefined)
        :
            group(group),
            name(name),
            thumbnail(icon),
            defaultPath(path),
            path(path),
            alternatives(alternatives),
            showSize(showSize),
            userDefined(userDefined) {};

        BookmarkGroup::Enum group {BookmarkGroup::Temporary};
        QString name {QStringLiteral()};
        QString thumbnail {QStringLiteral("icon-m-favorite")};
        QString defaultPath {QStringLiteral()};
        QString path {QStringLiteral()};
        QList<LocationAlternative> alternatives {};
        QStringList devices {};  // note: this is empty if alternatives is empty
        bool showSize {false};
        bool userDefined {false};
    };

    QList<BookmarkItem> m_entries;
    QList<BookmarkGroup::Enum> m_groupsOrder;
    QList<BookmarkItem> getStandardLocations();

    int m_firstUserDefinedIndex {-1};
    int m_lastUserDefinedIndex {-1};
    int m_firstExternalIndex {-1};

    // maps paths of custom bookmarks to indices in the entries list
    QHash<QString, BookmarkItem*> m_userDefinedLookup;

    // holds registered bookmark watchers
    // Bookmark watchers can be created from QML to monitor a single
    // path. They are registered here so that they can be directly notified of
    // any changes, without having to handle change signals for all paths
    // every time in all watchers.
    QMap<QString, QList<QPointer<BookmarkWatcher>>> m_watchers;

    QTimer* m_mountsPollingTimer {nullptr};
    QSet<int> m_ignoredMounts {};
    QStringList m_ignoredMountBases {};

    bool m_showOnlyDevices {false};
    bool m_haveAndroidPath {false};
    QMap<QStandardPaths::StandardLocation, QString> m_standardLocations;
    // BookmarkItem* m_documentsItem {nullptr};
    // BookmarkItem* m_downloadsItem {nullptr};
    // BookmarkItem* m_picturesItem {nullptr};
    // BookmarkItem* m_videosItem {nullptr};
    // BookmarkItem* m_musicItem {nullptr};

    // We monitor the bookmarks file except while saving entries.
    ConfigFileMonitor* m_bookmarksMonitor;
    ConfigFileMonitor* m_ignoredMountsMonitor;

    QMutex m_mutex;
    static QSharedPointer<BookmarksModel> s_globalInstance;

    friend uint qHash(const BookmarksModel::BookmarkItem& key, uint seed);
};

inline uint qHash(const BookmarksModel::BookmarkItem& key, uint seed=10)
{
    QByteArray result;
    result.reserve(24);
    result.append(QByteArray::number(qHash(key.path, seed)));
    result.append('#');
    result.append(QByteArray::number(qHash(key.name, seed)));
    result.append('#');
    result.append(QByteArray::number(qHash(key.userDefined, seed)));
    // qDebug() << (result.size() > 24) << "hashed" << key.path << "to" << result << "(" << result.size() << ")";
    return qHash(result, seed);
}

#endif // BOOKMARKS_H
