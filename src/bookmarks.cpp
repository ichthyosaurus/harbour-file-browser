/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2020-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "bookmarks.h"

#include <QMutexLocker>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QStandardPaths>
#include <QJsonArray>
#include <QTimer>
#include <QStorageInfo>

// The lines below define which icons are used for the standard location
// bookmarks. Each bookmark must have a unique icon because the icon is
// used to identify the bookmark.
// Only locations that can appear on different devices need unique icons
// in this list. Other locations can use any icon.
// Using defines for this is not beautiful but it works.
#define DOCUMENTS_ICON QStringLiteral("icon-m-file-document-light")
#define DOWNLOADS_ICON QStringLiteral("icon-m-cloud-download")
#define MUSIC_ICON     QStringLiteral("icon-m-file-audio")
#define PICTURES_ICON  QStringLiteral("icon-m-file-image")
#define VIDEOS_ICON    QStringLiteral("icon-m-file-video")


QSharedPointer<BookmarksModel> \
    BookmarksModel::s_globalInstance = \
        QSharedPointer<BookmarksModel>(nullptr);


DEFINE_ENUM_REGISTRATION_FUNCTION(Bookmarks) {
    REGISTER_ENUM_CONTAINER(BookmarkGroup)
    qRegisterMetaType<QList<BookmarkGroup::Enum>>("QList<BookmarkGroup::Enum>");
}


// BOOKMARKS MODEL

BookmarkWatcher::BookmarkWatcher(QObject *parent) : QObject(parent)
{
    //
}

BookmarkWatcher::~BookmarkWatcher()
{
    // We don't have to unregister destroyed watchers from the model
    // because the model handles this already. (Pointers are stored
    // using QPointer, which sets itself to 0 if the pointed-to QObject
    // is destroyed.)
}

bool BookmarkWatcher::marked() {
    if (m_path.isEmpty()) return false;
    return BookmarksModel::instance()->hasBookmark(m_path);
}

void BookmarkWatcher::setMarked(bool active) const {
    if (active) {
        BookmarksModel::instance()->add(m_path);
    } else {
        BookmarksModel::instance()->remove(m_path);
    }
}

void BookmarkWatcher::toggle()
{
    setMarked(!marked());
}

void BookmarkWatcher::setPath(QString path) {
    if (path == m_path) return;

    if (!m_path.isEmpty()) {
        BookmarksModel::instance()->unregisterWatcher(m_path, this);
    }

    m_path = path;
    BookmarksModel::instance()->registerWatcher(m_path, this);
    emit pathChanged();
}

QString BookmarkWatcher::name() {
    if (marked()) {
        return BookmarksModel::instance()->getBookmarkName(m_path);
    } else {
        return QLatin1Literal();
    }
}

void BookmarkWatcher::rename(QString newName) const {
    BookmarksModel::instance()->rename(m_path, newName);
}

void BookmarkWatcher::refresh() {
    emit markedChanged();
    emit pathChanged();
    emit nameChanged();
}

QVariantList LocationAlternative::makeVariantList(const QList<LocationAlternative>& list) {
    QVariantList ret;

    for (const auto& i : list) {
        ret.append(QVariant::fromValue<LocationAlternative>(i));
    }

    return ret;
}

QStringList LocationAlternative::makeDevicesList(const QList<LocationAlternative> &list) {
    QStringList ret;

    for (const auto& alt : list) {
        ret.append(alt.device());
    }

    ret.removeDuplicates();
    return ret;
}

enum BookmarkRole {
    groupRole =         Qt::UserRole +  1,
    nameRole =          Qt::UserRole +  2,
    thumbnailRole =     Qt::UserRole +  3,
    pathRole =          Qt::UserRole +  4,
    alternativesRole =  Qt::UserRole +  5,
    devicesRole =       Qt::UserRole +  6,
    showSizeRole =      Qt::UserRole +  7,
    userDefinedRole =   Qt::UserRole +  8
};

BookmarksModel::BookmarksModel(QObject *parent) :
    QAbstractListModel(parent),
    m_mountsPollingTimer(new QTimer(this)),
    m_bookmarksMonitor(new ConfigFileMonitor(this)),
    m_ignoredMountsMonitor(new ConfigFileMonitor(this))
{
    m_standardLocations = {
        {QStandardPaths::HomeLocation, QStandardPaths::writableLocation(QStandardPaths::HomeLocation)},
        {QStandardPaths::DocumentsLocation, QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)},
        {QStandardPaths::DownloadLocation, QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)},
        {QStandardPaths::MusicLocation, QStandardPaths::writableLocation(QStandardPaths::MusicLocation)},
        {QStandardPaths::PicturesLocation, QStandardPaths::writableLocation(QStandardPaths::PicturesLocation)},
        {QStandardPaths::MoviesLocation, QStandardPaths::writableLocation(QStandardPaths::MoviesLocation)},

        // DataLocation is (ab)used here to indicate Android data
        {QStandardPaths::DataLocation, QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + QStringLiteral("/android_storage")},
    };

    QFileInfo androidInfo(m_standardLocations[QStandardPaths::DataLocation]);

    if (androidInfo.exists() && androidInfo.isDir()) {
        m_haveAndroidPath = true;
    }

    QString configDirectory = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QString bookmarksFile = configDirectory + "/bookmarks.json";

    if (!QDir("/").mkpath(configDirectory)) {
        qWarning() << "[bookmarks] cannot save bookmarks:" <<
                      "cannot create base directory at" <<
                      configDirectory;
    }

    QString ignoredMountsFile = configDirectory + "/ignored-mounts.json";
    m_ignoredMountsMonitor->reset(ignoredMountsFile);
    connect(m_ignoredMountsMonitor, &ConfigFileMonitor::configChanged, this, &BookmarksModel::reloadIgnoredMounts);
    reloadIgnoredMounts(); // must be called after m_ignoredMountsMonitor has a file

    m_bookmarksMonitor->reset(bookmarksFile);
    connect(m_bookmarksMonitor, &ConfigFileMonitor::configChanged, this, &BookmarksModel::reload);

    if (!QFile::exists(bookmarksFile)) {
        // must be called after m_bookmarksMonitor has a file
        save();
    }

    m_mountsPollingTimer->setInterval(5 * 1000);
    m_mountsPollingTimer->setTimerType(Qt::VeryCoarseTimer);
    m_mountsPollingTimer->setSingleShot(false);
    m_mountsPollingTimer->start();
    connect(m_mountsPollingTimer, &QTimer::timeout, this, &BookmarksModel::updateExternalDevices);

    reload();
}

BookmarksModel::~BookmarksModel()
{
    //
}

int BookmarksModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_entries.length();
}

QVariant BookmarksModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= rowCount()) {
        return QVariant();
    }

    const auto& entry = m_entries.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
    case BookmarkRole::nameRole:
        return entry.name;

    case BookmarkRole::groupRole: return entry.group;
    case BookmarkRole::thumbnailRole: return entry.thumbnail;
    case BookmarkRole::pathRole: return entry.path;
    case BookmarkRole::alternativesRole:
        return LocationAlternative::makeVariantList(entry.alternatives);
    case BookmarkRole::devicesRole: return entry.devices;
    case BookmarkRole::showSizeRole: return entry.showSize;
    case BookmarkRole::userDefinedRole: return entry.userDefined;

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> BookmarksModel::roleNames() const
{
#define ROLE(ENUM, NAME) { ENUM##Role::NAME##Role, QByteArrayLiteral(#NAME) },
    static const QHash<int, QByteArray> roles = {
        // QAbstractListModel::roleNames()
        ROLE(Bookmark, group)
        ROLE(Bookmark, name)
        ROLE(Bookmark, thumbnail)
        ROLE(Bookmark, path)
        ROLE(Bookmark, alternatives)
        ROLE(Bookmark, devices)
        ROLE(Bookmark, showSize)
        ROLE(Bookmark, userDefined)
    };
    return roles;
#undef ROLE
}

void BookmarksModel::add(QString path, QString name)
{
    addUserDefined(path, name, true);
}

void BookmarksModel::addTemporary(QString path, QString name)
{
    addUserDefined(path, name, false);
}

void BookmarksModel::remove(QString path)
{
    removeUserDefined(path, true);
}

void BookmarksModel::removeTemporary(QString path)
{
    removeUserDefined(path, false);
}

void BookmarksModel::clearTemporary()
{
    QStringList toRemove;
    toRemove.reserve(m_lastUserDefinedIndex);

    for (const auto& i : m_entries) {
        if (i.group == BookmarkGroup::Temporary) {
            toRemove.append(i.path);
        }
    }

    for (const auto& i : toRemove) {
        removeTemporary(i);
    }
}

void BookmarksModel::sortFilter(QVariantList order)
{
    m_showOnlyDevices = false;

    QList<BookmarkGroup::Enum> newOrder;
    for (const auto& i : std::as_const(order)) {
        if (i.isValid()) {
            auto group = i.value<BookmarkGroup::Enum>();

            if (group == BookmarkGroup::Device) {
                newOrder.append(BookmarkGroup::Location);
                newOrder.append(BookmarkGroup::External);
                m_showOnlyDevices = true;
            } else {
                newOrder.append(group);
            }
        }
    }

    if (newOrder == m_groupsOrder) return;
    m_groupsOrder = newOrder;
    reload();
}

void BookmarksModel::selectAlternative(const QModelIndex& idx, QString alternative)
{
    if (!idx.isValid()) {
        return;
    }

    if (idx.row() >= 0 && idx.row() < m_entries.length()) {
        auto& entry = m_entries[idx.row()];
        bool found = false;

        if (entry.path == alternative) {
            return;
        }

        for (const auto& i : entry.alternatives) {
            if (i.path() == alternative) {
                found = true;
            }
        }

        if (!found) {
            qDebug() << "warning: cannot select" << alternative << "as alternative for" <<
                        entry.defaultPath << "as it is not in" <<
                        LocationAlternative::makeVariantList(entry.alternatives);
            alternative = "";
        }

        m_entries[idx.row()].path = alternative;
        emit dataChanged(idx, idx, {BookmarkRole::pathRole});
    }
}

void BookmarksModel::rename(QString path, QString newName)
{
    if (newName.isEmpty()) return;
    int idx = findUserDefinedIndex(path);
    if (idx < 0) return;

    m_entries[idx].name = newName;
    QModelIndex topLeft = index(idx, 0);
    QModelIndex bottomRight = index(idx, 0);
    emit dataChanged(topLeft, bottomRight, {BookmarkRole::nameRole});

    save();
    notifyWatchers(path);
}

bool BookmarksModel::hasBookmark(QString path) const
{
    if (m_userDefinedLookup.contains(path)) {
        return true;
    }

    return false;
}

void BookmarksModel::registerWatcher(QString path, QPointer<BookmarkWatcher> mark)
{
    if (m_watchers.contains(path)) {
        if (!m_watchers.value(path).contains(mark)) {
            m_watchers[path].append(mark);
        }
    } else {
        m_watchers.insert(path, {mark});
    }
}

void BookmarksModel::unregisterWatcher(QString path, QPointer<BookmarkWatcher> mark)
{
    if (m_watchers.contains(path)) {
        m_watchers[path].removeAll(mark);
    }
}

QString BookmarksModel::getBookmarkName(QString path) const
{
    if (path.isEmpty() || !m_userDefinedLookup.contains(path)) {
        return QLatin1Literal();
    }

    return m_userDefinedLookup.value(path)->name;
}

enum DeviceType {
    SdCard, BindMount, Remote, Any
};

void BookmarksModel::updateExternalDevices()
{
    // qDebug() << "checking mounts...";

    if (!m_groupsOrder.contains(BookmarkGroup::External)) {
        return;
    }

    // currently visible list of mounts
    QSet<int> knownMounts;
    int nextExternalIndex = -1;
    int knownCount = m_entries.length();

    for (int i = m_firstExternalIndex; i < knownCount; ++i) {
        const auto& item = m_entries.at(i);

        if (item.group != BookmarkGroup::External) {
            continue;
        }

        knownMounts.insert(qHash(item.path));
        nextExternalIndex = i;
    }

    if (nextExternalIndex < 0) {
        nextExternalIndex = m_firstExternalIndex;
    } else {
        ++nextExternalIndex;
    }

    // currently active mounts reported by the system
    const auto activeMounts = QStorageInfo::mountedVolumes();
    QSet<int> activeHashes;

    QList<LocationAlternative> newDevices;
    newDevices.reserve(activeMounts.length());
    uint goneDevices = 0;

    for (const auto& i : activeMounts) {
        if (    i.isValid()
            &&  i.isReady()
            && !i.isRoot()
            &&  i.fileSystemType() != QStringLiteral("tmpfs")
        ) {
            const QString rootPath = i.rootPath();
            int pathHash = qHash(rootPath);

            if (!m_ignoredMounts.contains(pathHash)) {
                // TODO use QtConcurrent::filtered to filter mount points
                //      instead of the outer loop
                // auto startsWith = [&rootPath](const QString& base) -> bool {
                //     return rootPath.startsWith(base); };
                // auto any = [](bool& result, const bool& intermediate) -> void {
                //     result = result || intermediate; };
                //
                // if (QtConcurrent::blockingMappedReduced<bool>(m_ignoredMountBases, startsWith, any)) {
                //     continue;
                // }

                bool isIgnored = false;
                for (const auto& base : m_ignoredMountBases) {
                    if (rootPath.startsWith(base)) {
                        // qDebug() << "mount point ignored:" << rootPath << "is below" << base;
                        isIgnored = true;
                        break;
                    }
                }

                if (isIgnored) {
                    continue;
                } else {
                    activeHashes.insert(pathHash);
                }
            }

            if (m_ignoredMounts.contains(pathHash) || knownMounts.contains(pathHash)) {
                continue;
            } else {
                qDebug() << "new mount detected:"
                         << i.displayName()
                         << i.device()
                         << i.fileSystemType()
                         << i.rootPath()
                ;
            }

            DeviceType type = Any;
            QString icon;

            if (i.device().startsWith(QByteArray("/dev/mmc"))) {
                type = SdCard;
                icon = QStringLiteral("icon-m-sd-card");
            } else if (i.device().startsWith(QByteArray("/dev/mapper/sailfish-"))) {
                // Bind mounts have device == /dev/mapper/sailfish-{home,root}
                // but only /dev/mapper/sailfish-home is visible through QStorageInfo.
                // Note: bind mounts in /dev/mapper/sailfish-root don't show up
                // even if the app is running as root.
                type = BindMount;
                icon = QStringLiteral("icon-m-attach");
            } else if (i.fileSystemType() == QStringLiteral("cifs")) {
                type = Remote;
                icon = QStringLiteral("icon-m-website");
            } else {
                type = Any;
                icon = QStringLiteral("icon-m-usb");
            }

            QString title = i.displayName();
            if (title == i.rootPath()) {
                // TODO: find better, more informative titles.
                switch (type) {
                case SdCard:
                    title = tr("Memory card"); break;
                case BindMount:
                    title = tr("Attached folder"); break;
                case Remote:
                    title = tr("Remote folder"); break;
                case Any:
                default:
                    title = tr("Removable media");
                }
            }

            auto newEntry = BookmarkItem(
                BookmarkGroup::External,
                title, icon, i.rootPath(), {},
                true, false);

            beginInsertRows(QModelIndex(), nextExternalIndex, nextExternalIndex);
            newDevices.append({newEntry.name, newEntry.path, newEntry.name});
            m_entries.insert(nextExternalIndex, newEntry);
            if (m_firstExternalIndex <= m_firstUserDefinedIndex) {
                ++m_firstUserDefinedIndex;
                ++m_lastUserDefinedIndex;
            }
            endInsertRows();
        }
    }

    // remove currently visible mounts that are no longer active
    int currentCount = m_entries.length();

    for (int i = currentCount-1; i >= 0; --i) {
        if (m_entries.at(i).group != BookmarkGroup::External) {
            continue;
        }

        if (activeHashes.contains(qHash(m_entries.at(i).path))) {
            continue;
        }

        beginRemoveRows(QModelIndex(), i, i);
        goneDevices++;
        m_entries.removeAt(i);
        if (m_firstExternalIndex <= m_firstUserDefinedIndex) {
            --m_firstUserDefinedIndex;
            --m_lastUserDefinedIndex;
            qDebug() << "changingB:" << nextExternalIndex << m_firstExternalIndex << m_lastUserDefinedIndex;
        }
        endRemoveRows();
    }

    // update standard location alternatives
    updateStandardLocations(newDevices, goneDevices);
}

void BookmarksModel::updateStandardLocations(const QList<LocationAlternative>& newExternalPaths, const uint& lostPathsCount) {
    if (newExternalPaths.isEmpty() && lostPathsCount == 0) {
        return;
    }

    auto setAlternatives = [&](int idx, BookmarkItem& item, const QString& translatedName,
            QHash<QString, const LocationAlternative*>& existingAlternatives){
        bool changed = false;
        QString name = item.path.split("/").last();

        for (auto i = item.alternatives.length()-1; i >= 0; --i) {
            if (!QFileInfo::exists(item.alternatives.at(i).path())) {
                item.alternatives.removeAt(i);
                changed = true;
            }
        }

        QStringList checkNames {name};

        if (name != translatedName) {
            checkNames.append(translatedName);
        }

        for (const auto& i : newExternalPaths) {
            QList<QPair<QString, QString>> foundAlternatives;

            for (const auto& name : checkNames) {
                QString option = i.path() + QStringLiteral("/") + name;
                QFileInfo optionInfo(option);

                if (optionInfo.exists() && optionInfo.isDir() &&
                        !existingAlternatives.contains(option)) {
                    foundAlternatives.append({name, option});
                }
            }

            bool disambiguate = foundAlternatives.length() > 1;

            if (!foundAlternatives.isEmpty()) {
                if (item.alternatives.isEmpty()) {
                    item.alternatives.append({tr("Internal storage"), item.path, tr("Internal storage")});
                    existingAlternatives.insert(item.path, &item.alternatives.last());
                }

                for (const auto& newPath : foundAlternatives) {
                    item.alternatives.insert(1, {
                        disambiguate ?
                            //: as in "the folder “Music” on the storage named “SD Card”"
                            tr("“%1” on “%2”").arg(newPath.first, i.name()) :
                            i.name(),
                        newPath.second,
                        i.name()
                    });
                    existingAlternatives.insert(newPath.second, &item.alternatives.at(1));
                    changed = true;
                }
            }
        }

        // There are always at least two alternatives because the first alternative
        // is always the default path. If only one is left, all actual alternatives
        // have been removed, so the list can be cleared.
        if (item.alternatives.length() == 1) {
            item.alternatives = {};
            item.path = item.defaultPath;
            changed = true;
        }

        if (changed) {
            item.devices = LocationAlternative::makeDevicesList(item.alternatives);

            QModelIndex topLeft = index(idx, 0);
            QModelIndex bottomRight = index(idx, 0);
            emit dataChanged(topLeft, bottomRight, {
                BookmarkRole::alternativesRole,
                BookmarkRole::pathRole,
                BookmarkRole::devicesRole
            });
        }
    };

    QHash<QString, const LocationAlternative*> alternatives;

    for (auto i = 0; i < m_entries.length(); ++i) {
        if (m_entries.at(i).group != BookmarkGroup::Location) {
            continue;
        }

        auto& entry = m_entries[i];
        const auto& icon = entry.thumbnail;

        if (icon == DOCUMENTS_ICON
                || icon == DOWNLOADS_ICON
                || icon == PICTURES_ICON
                || icon == VIDEOS_ICON
                || icon == MUSIC_ICON) {
            alternatives.clear();

            for (const auto& alt : entry.alternatives) {
                alternatives.insert(alt.path(), &alt);
            }

            if (icon == DOCUMENTS_ICON) {
                setAlternatives(i, entry, tr("Documents"), alternatives);
            } else if (icon == DOWNLOADS_ICON) {
                setAlternatives(i, entry, tr("Downloads"), alternatives);
            } else if (icon == PICTURES_ICON) {
                setAlternatives(i, entry, tr("Pictures"), alternatives);
            } else if (icon == VIDEOS_ICON) {
                setAlternatives(i, entry, tr("Videos"), alternatives);
            } else if (icon == MUSIC_ICON) {
                setAlternatives(i, entry, tr("Music"), alternatives);
            }
        }
    }
}

void BookmarksModel::reload()
{
    m_mountsPollingTimer->stop();

    QHash<QString, BookmarkItem*> newUserDefinedLookup;
    QMap<BookmarkGroup::Enum, QList<BookmarkItem>> newEntries;
    newEntries.insert(BookmarkGroup::Location, getStandardLocations());
    newEntries.insert(BookmarkGroup::External, {}); // loaded when m_mountsPollingTimer triggers
    newEntries.insert(BookmarkGroup::Bookmark, {}); // loaded below
    newEntries.insert(BookmarkGroup::Temporary, {}); // reset on reload

    // load user defined bookmarks
    const auto value = m_bookmarksMonitor->readJson(QStringLiteral("1"), QJsonArray());

    if (value.isArray()) {
        const auto array = value.toArray();

        for (const auto& i : array) {
            if (!i.isObject()) {
                qWarning() << "invalid bookmarks entry in" << m_bookmarksMonitor->file() << i;
                continue;
            }

            auto obj = i.toObject();
            QString path = obj.value(QStringLiteral("path")).toString(QStringLiteral("/home"));
            QString name = obj.value(QStringLiteral("name")).toString(path.split("/").last());

            if (path.isEmpty()) {
                qWarning() << "invalid bookmarks entry in" << m_bookmarksMonitor->file() << i
                           << "- path must not be empty";
                continue;
            }

            newEntries[BookmarkGroup::Bookmark].append(BookmarkItem(
                BookmarkGroup::Bookmark,
                name,
                QStringLiteral("icon-m-favorite"),
                path, {},
                false, true));
            newUserDefinedLookup.insert(path, &newEntries[BookmarkGroup::Bookmark].last());
        }
    } else {
        qWarning() << "invalid bookmarks data in" << m_bookmarksMonitor->file() << value;
    }

    beginResetModel();
    m_entries.clear();
    for (const auto& i : std::as_const(m_groupsOrder)) {
        if (i == BookmarkGroup::Bookmark) m_firstUserDefinedIndex = m_entries.length();
        else if (i == BookmarkGroup::External) m_firstExternalIndex = m_entries.length();

        m_entries.append(newEntries[i]);

        if (i == BookmarkGroup::Bookmark) m_lastUserDefinedIndex = m_entries.length() - 1;
    }
    m_userDefinedLookup = newUserDefinedLookup;
    endResetModel();

    updateExternalDevices();
    m_mountsPollingTimer->start();
}

void BookmarksModel::reloadIgnoredMounts()
{
    if (m_ignoredMountsMonitor->file().isEmpty()) {
        qWarning() << "bug: reloadIgnoredMounts() called before monitor has file";
        return;
    }

    if (!QFile::exists(m_ignoredMountsMonitor->file())) {
        qDebug() << "mount point ignore list not found at" << m_ignoredMountsMonitor->file()
                 << "- creating file with default ignore list...";

        // All mount points that exactly match one of these paths are ignored.
        const static QJsonArray defaultIgnoredFullPaths {
            {QStringLiteral("/")},
            {QStringLiteral("/persist")},
            {QStringLiteral("/protect_s")},
            {QStringLiteral("/protect_f")},
            {QStringLiteral("/dsp")},
            {QStringLiteral("/odm")},
            {QStringLiteral("/opt")},
            {QStringLiteral("/home")},
            {QStringLiteral("/firmware")},
            {QStringLiteral("/bt_firmware")},
            {QStringLiteral("/firmware_mnt")},
            {QStringLiteral("/metadata")},
            {QStringLiteral("/blackbox")},
        };

        // All mount points below these paths are ignored.
        const static QJsonArray defaultIgnoredBasePaths {
            {QStringLiteral("/opt/alien/")},
            {QStringLiteral("/apex/")},
            {QStringLiteral("/opt/appsupport/")},
            {QStringLiteral("/vendor/")},
            {QStringLiteral("/home/")},
            {QStringLiteral("/dsp/")},
            {QStringLiteral("/firmware/")},
            {QStringLiteral("/bt_firmware/")},
            {QStringLiteral("/firmware_mnt/")},
            {QStringLiteral("/persist/")},
            {QStringLiteral("/mnt/vendor/")},
        };

        QJsonObject object;
        object.insert(QStringLiteral("fullPaths"), defaultIgnoredFullPaths);
        object.insert(QStringLiteral("basePaths"), defaultIgnoredBasePaths);
        m_ignoredMountsMonitor->writeJson(object, QStringLiteral("1"));

        qDebug() << "saved default ignore list:" << object;
    }

    const auto value = m_ignoredMountsMonitor->readJson(QStringLiteral("1"));

    if (value.isObject()) {
        const QJsonObject object = value.toObject();

        const auto fullArray = object.value(QStringLiteral("fullPaths")).toArray();
        const auto baseArray = object.value(QStringLiteral("basePaths")).toArray();

        qDebug() << "loading mount point ignore list:";
        qDebug() << "full paths:" << fullArray;
        qDebug() << "base paths:" << baseArray;

        m_ignoredMounts.clear();
        m_ignoredMountBases.clear();

        for (const auto& i : fullArray) {
            m_ignoredMounts.insert(qHash(i.toString(QStringLiteral("/"))));
        }

        for (const auto& i : baseArray) {
            if (i.isString()) {
                QString string = i.toString();
                string.remove(QRegExp(QStringLiteral(R"(/+$)")));

                if (string.isEmpty()) {
                    continue;
                }

                m_ignoredMountBases.append(string + QStringLiteral("/"));
            }
        }

        m_ignoredMountBases.removeDuplicates();
    } else {
        qWarning() << "invalid mount point ignore data in" << m_ignoredMountsMonitor->file() << value;
    }
}

void BookmarksModel::save()
{
    QMutexLocker locker(&m_mutex);
    QJsonArray array;

    for (const auto& i : std::as_const(m_entries)) {
        if (   !i.userDefined
            || i.path.isEmpty()) {
            continue;
        }

        QJsonObject item;
        item.insert(QStringLiteral("name"), i.name);
        item.insert(QStringLiteral("path"), i.path);
        array.append(item);
    }

    m_bookmarksMonitor->writeJson(array, QStringLiteral("1"));
}

QStringList BookmarksModel::pathsForIndexes(const QModelIndexList& indexes)
{
    QStringList ret;
    ret.reserve(indexes.length());

    int count = m_entries.length();
    for (const auto& i : std::as_const(indexes)) {
        if (!i.isValid()) continue;

        int row = i.row();
        if (row >= 0 && row < count) {
            ret.append(m_entries.at(row).path);
        }
    }

    return ret;
}

void BookmarksModel::notifyWatchers(const QString& path)
{
    if (m_watchers.contains(path)) {
        for (auto& i : m_watchers.value(path)) {
            if (i) {
                i->refresh();
            }
        }
    }
}

void BookmarksModel::addUserDefined(QString path, QString name, bool permanent)
{
    if (path.isEmpty()) return;

    if (m_userDefinedLookup.contains(path)) {
        if (!permanent) {
            // If a new temporary bookmark already exists,
            // we still send a signal so that the selection
            // can be updated. The bookmark is not added twice.
            int idx = findUserDefinedIndex(path);
            emit temporaryAdded(index(idx), idx);
        }

        return;
    }

    if (name.isEmpty()) {
        QDir dir(path);
        name = dir.dirName();

        if (name.isEmpty()) {
            name = QStringLiteral("/");
        }
    }

    int at = m_lastUserDefinedIndex + 1;
    if (!permanent) {
        // TODO actually handle BookmarkGroup::Bookmark and BookmarkGroup::Temporary
        // as separate groups that can be arbitrarily ordered.
        // For now, we simply always insert temporary entries before regular entries.
        at = m_firstUserDefinedIndex;
    }

    beginInsertRows(QModelIndex(), at, at);
    m_entries.insert(at, BookmarkItem(
        permanent ? BookmarkGroup::Bookmark : BookmarkGroup::Temporary,
        name,
        permanent ? QStringLiteral("icon-m-favorite") : QStringLiteral("icon-m-file-folder"),
        path, {},
        false, true)
    );
    ++m_lastUserDefinedIndex;
    m_userDefinedLookup.insert(path, &m_entries[at]);
    endInsertRows();

    if (permanent) {
        save();
        notifyWatchers(path);
    } else {
        emit temporaryAdded(index(at), at);
    }
}

void BookmarksModel::removeUserDefined(QString path, bool permanent)
{
    int idx = findUserDefinedIndex(path);
    if (idx < 0) return;

    beginRemoveRows(QModelIndex(), idx, idx);
    m_entries.removeAt(idx);
    m_userDefinedLookup.remove(path);
    --m_lastUserDefinedIndex;
    endRemoveRows();

    if (permanent) {
        notifyWatchers(path);
        save();
    }
}

int BookmarksModel::findUserDefinedIndex(QString path)
{
    if (path.isEmpty() || !m_userDefinedLookup.contains(path)) return -1;

    int count = m_entries.length();
    for (int i = 0; i < count; ++i) {
        const auto& item = m_entries.at(i);

        if (item.userDefined && item.path == path) {
            return i;
        }
    }

    return -1;
}

void BookmarksModel::move(int fromIndex, int toIndex, bool saveImmediately)
{
    // Note: only user defined bookmarks can be moved.

    if (fromIndex < 0 || fromIndex > rowCount() || fromIndex == toIndex
            || fromIndex < m_firstUserDefinedIndex || fromIndex > m_lastUserDefinedIndex) {
        qDebug() << "cannot move bookmark at non-user-defined index" << fromIndex << "to" << toIndex;
        return;
    }

    if (toIndex < m_firstUserDefinedIndex) {
        qDebug() << "cannot move bookmark above" << m_firstUserDefinedIndex
                 << "- requested" << toIndex << "but granting" << m_firstUserDefinedIndex;
        toIndex = m_firstUserDefinedIndex;
    } else if (toIndex > m_lastUserDefinedIndex) {
        qDebug() << "cannot move bookmark below" << m_lastUserDefinedIndex
                 << "- requested" << toIndex << "but granting" << m_lastUserDefinedIndex;
        toIndex = m_lastUserDefinedIndex;
    }

    if (toIndex == fromIndex) {
        qDebug() << "not moving bookmark: already at first/last legal index" << fromIndex;
        return;
    }

    qDebug() << "moving bookmark:" << fromIndex << toIndex;

    beginMoveRows(QModelIndex(), fromIndex, fromIndex,
                  QModelIndex(), toIndex < fromIndex ? toIndex : (toIndex + 1));
    m_entries.move(fromIndex, toIndex);
    endMoveRows();

    if (saveImmediately) {
        save();
    }
}

QList<BookmarksModel::BookmarkItem> BookmarksModel::getStandardLocations()
{
    BookmarkItem homeItem {
        BookmarkGroup::Location,
        tr("Home"),
        QStringLiteral("icon-m-home"),
        m_standardLocations[QStandardPaths::HomeLocation],
        {},
        true,
        false
    };

    BookmarkItem documentsItem {
        BookmarkGroup::Location,
        tr("Documents"),
        DOCUMENTS_ICON,
        m_standardLocations[QStandardPaths::DocumentsLocation],
        {},
        false,
        false
    };

    BookmarkItem downloadsItem {
    BookmarkGroup::Location,
        tr("Downloads"),
        DOWNLOADS_ICON,
        m_standardLocations[QStandardPaths::DownloadLocation],
        {},
        false,
        false
    };

    BookmarkItem picturesItem {
    BookmarkGroup::Location,
        tr("Pictures"),
        PICTURES_ICON,
        m_standardLocations[QStandardPaths::PicturesLocation],
        {},
        false,
        false
    };

    BookmarkItem videosItem {
        BookmarkGroup::Location,
        tr("Videos"),
        VIDEOS_ICON,
        m_standardLocations[QStandardPaths::MoviesLocation],
        {},
        false,
        false
    };

    BookmarkItem musicItem {
    BookmarkGroup::Location,
        tr("Music"),
        MUSIC_ICON,
        m_standardLocations[QStandardPaths::MusicLocation],
        {},
        false,
        false
    };

    BookmarkItem androidItem {
        BookmarkGroup::Location,
        tr("Android storage"),
        QStringLiteral("icon-m-file-apk"),
        m_standardLocations[QStandardPaths::DataLocation],
        {},
        false,
        false
    };

    BookmarkItem rootItem {
        BookmarkGroup::Location,
        tr("Root"),
        QStringLiteral("icon-m-file-rpm"),
        QStringLiteral("/"),
        {},
        true,
        false
    };

    if (m_haveAndroidPath) {
        auto setAlternatives = [&](BookmarkItem& item, const QString& androidName){
            QString android = m_standardLocations[QStandardPaths::DataLocation] + QStringLiteral("/") + androidName;
            QFileInfo androidInfo(android);

            if (androidInfo.exists() && androidInfo.isDir()) {
                item.alternatives = {
                    {tr("Internal storage"), item.path, tr("Internal storage")},
                    {tr("Android storage"), android, tr("Android storage")},
                };
                item.devices = LocationAlternative::makeDevicesList(item.alternatives);
            }
        };

        setAlternatives(documentsItem, QStringLiteral("Documents"));
        setAlternatives(downloadsItem, QStringLiteral("Download"));
        setAlternatives(picturesItem, QStringLiteral("Pictures"));
        setAlternatives(videosItem, QStringLiteral("Movies"));
        setAlternatives(musicItem, QStringLiteral("Music"));

        if (m_showOnlyDevices) {
            return {
                homeItem,
                androidItem, // <-- difference
                rootItem,
            };
        } else {
            return {
                homeItem,
                documentsItem,
                downloadsItem,
                picturesItem,
                videosItem,
                musicItem,
                androidItem, // <-- difference
                rootItem,
            };
        }
    } else {
        if (m_showOnlyDevices) {
            return {
                homeItem,
                // androidItem, // <-- difference
                rootItem,
            };
        } else {
            return {
                homeItem,
                documentsItem,
                downloadsItem,
                picturesItem,
                videosItem,
                musicItem,
                // androidItem, // <-- difference
                rootItem,
            };
        }
    }
}
