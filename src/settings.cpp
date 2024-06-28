/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020-2023 Mirian Margiani
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

#include "settings.h"

#include <unistd.h>

#include <QMutexLocker>
#include <QSettings>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QtConcurrentRun>
#include <QQmlEngine>
#include <QJsonArray>
#include <QJsonDocument>
#include <QtQml>
#include <QTimer>
#include <QStorageInfo>

QSharedPointer<RawSettingsHandler> \
    RawSettingsHandler::s_globalInstance = \
        QSharedPointer<RawSettingsHandler>(nullptr);

QSharedPointer<BookmarksModel> \
    BookmarksModel::s_globalInstance = \
        QSharedPointer<BookmarksModel>(nullptr);

QString DirectorySettings::s_cachedInitialDirectory = QLatin1Literal();
QString DirectorySettings::s_forcedInitialDirectory = QLatin1Literal();
bool DirectorySettings::s_haveForcedInitialDirectory = false;
QString DirectorySettings::s_cachedStorageSettingsPath = QLatin1Literal();
QString DirectorySettings::s_cachedPdfViewerPath = QLatin1Literal();
SharingMethod::Enum DirectorySettings::s_cachedSharingMethod = SharingMethod::Disabled;
bool DirectorySettings::s_cachedSharingMethodDetermined = false;
bool DirectorySettings::s_authenticatedForRoot = false;

DEFINE_ENUM_REGISTRATION_FUNCTION(SettingsHandler) {
    REGISTER_ENUM_CONTAINER(BookmarkGroup)
    qRegisterMetaType<QList<BookmarkGroup::Enum>>("QList<BookmarkGroup::Enum>");
    REGISTER_ENUM_CONTAINER(SharingMethod)
    REGISTER_ENUM_CONTAINER(InitialDirectoryMode)
}

RawSettingsHandler::RawSettingsHandler(QObject *parent)
    : QObject(parent)
{
    // Explicitly set the QML ownership so we can use the same singleton
    // instance in C++ and in QML.
    // - https://doc.qt.io/qt-5/qqmlengine.html#qmlRegisterSingletonType-1
    // - https://stackoverflow.com/a/68873634
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);

    m_globalConfigDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QString configFile = QCoreApplication::applicationName() + ".conf";
    QSettings global(m_globalConfigDir + "/" + configFile, QSettings::IniFormat);
    m_globalConfigPath = global.fileName();

    if (   pathIsProtected(m_globalConfigPath)
        || !QDir("/").mkpath(QFileInfo(m_globalConfigPath).absolutePath())) {
        qWarning() << "[settings] cannot save global settings:" <<
                      "path is protected or not writable";
    }
}

RawSettingsHandler::~RawSettingsHandler() {
    //
}

bool RawSettingsHandler::pathIsProtected(QString path) const {
    QString absolutePath = QFileInfo(path).absoluteFilePath();

    if (   absolutePath.startsWith(QDir::home().absolutePath()) /* user's home directory */
        || absolutePath.startsWith(QString("/run/media/") +
                                   QDir::home().dirName()) /* below /run/media/USER */
       ) {
        return false; // unprotected
    }

    return true; // protected
}

void RawSettingsHandler::flushRuntimeSettings(QString fileName) {
    QFileInfo fileInfo = QFileInfo(fileName);
    QMutexLocker locker(&m_mutex);

    if (pathIsProtected(fileName) || !isWritable(fileInfo) || !hasRuntimeSettings(fileInfo)) {
        return;
    }

    QMap<QString, QVariant> data = getRuntimeSettings(fileInfo);
    m_runtimeSettings.remove(fileInfo.absoluteFilePath());
    locker.unlock();

    QSettings settings(fileName, QSettings::IniFormat);
    const QStringList keys = data.keys();

    for (const QString &key : keys) {
        QVariant value = data[key];

        if (settings.value(key) == value) continue;
        settings.setValue(key, value);
    }
}

bool RawSettingsHandler::hasRuntimeSettings(QFileInfo file) const {
    return m_runtimeSettings.contains(file.absoluteFilePath());
}

QMap<QString, QVariant>& RawSettingsHandler::getRuntimeSettings(QFileInfo file) {
    return m_runtimeSettings[file.absoluteFilePath()];
}

bool RawSettingsHandler::isWritable(QFileInfo fileInfo) const {
    // Check whether the file is writable. If it does not exist, check if
    // its parent directory can be written to.
    // Use this method instead of plain QFileInfo::isWritable!
    if (fileInfo.exists()) {
        if (fileInfo.isFile()) {
            return fileInfo.isWritable();
        } else {
            return false;
        }
    } else {
        return QFileInfo(fileInfo.absolutePath()).isWritable();
    }
}

QVariant RawSettingsHandler::readVariant(QString key, const QVariant &defaultValue, QString fileName) {
    sanitizeKey(key);
    if (fileName.isEmpty()) fileName = m_globalConfigPath;
    QFileInfo fileInfo = QFileInfo(fileName);

    if (!fileInfo.exists() || !fileInfo.isReadable() || pathIsProtected(fileName)) {
        QMutexLocker locker(&m_mutex);
        return getRuntimeSettings(fileInfo).value(key, defaultValue);
    }

    flushRuntimeSettings(fileName);
    QSettings settings(fileName, QSettings::IniFormat);
    return settings.value(key, defaultValue);
}

QString RawSettingsHandler::read(QString key, QString defaultValue, QString fileName) {
    return readVariant(key, defaultValue, fileName).toString();
}

void RawSettingsHandler::writeVariant(QString key, const QVariant &value, QString fileName) {
    sanitizeKey(key);
    bool usingLocalConfig = true;

    if (fileName.isEmpty()) {
        fileName = m_globalConfigPath;
        usingLocalConfig = false;
    }

    qDebug() << "writing:" << key << "=" << value << "in" << fileName;

    QFileInfo fileInfo = QFileInfo(fileName);

    if (pathIsProtected(fileName) || !isWritable(fileInfo)) {
        QMutexLocker locker(&m_mutex);
        getRuntimeSettings(fileInfo)[key] = value;
    } else {
        flushRuntimeSettings(fileName);
        QSettings settings(fileName, QSettings::IniFormat);
        if (settings.value(key) == value) return;
        settings.setValue(key, value);
    }

    emit settingsChanged(key, usingLocalConfig, usingLocalConfig ? fileInfo.absoluteFilePath() : "");
    if (fileName != m_globalConfigPath || key.startsWith("View/")) {
        emit viewSettingsChanged(usingLocalConfig ? fileInfo.absolutePath() : "");
    }
}

bool RawSettingsHandler::hasKey(QString key, QString fileName)
{
    sanitizeKey(key);
    if (fileName.isEmpty()) fileName = m_globalConfigPath;
    QFileInfo fileInfo = QFileInfo(fileName);

    if (!fileInfo.exists() || !fileInfo.isReadable() || pathIsProtected(fileName)) {
        QMutexLocker locker(&m_mutex);
        return getRuntimeSettings(fileInfo).contains(key);
    }

    flushRuntimeSettings(fileName);
    QSettings settings(fileName, QSettings::IniFormat);
    return settings.contains(key);
}

void RawSettingsHandler::sanitizeKey(QString& key) const {
    // Replace all but the first occurrence of '/' by '#',
    // so '/' can appear without being treated as divider for sub-groups.
    // This is needed for saving paths as keys (eg. for bookmarks).

    if (key.indexOf('/') == -1) return;
    int pos = key.indexOf('/');
    key.replace(pos, 1, '&');
    key.replace('/', '#');
    key.replace(pos, 1, '/');
}

void RawSettingsHandler::write(QString key, QString value, QString fileName) {
    writeVariant(key, value, fileName);
}

void RawSettingsHandler::remove(QString key, QString fileName) {
    sanitizeKey(key);
    bool usingLocalConfig = true;
    if (fileName.isEmpty()) {
        fileName = m_globalConfigPath;
        usingLocalConfig = false;
    }

    qDebug() << "deleting:" << key << "in" << fileName;

    QFileInfo fileInfo = QFileInfo(fileName);

    if (pathIsProtected(fileName) || !isWritable(fileInfo)) {
        QMutexLocker locker(&m_mutex);
        getRuntimeSettings(fileInfo).remove(key);
    } else {
        flushRuntimeSettings(fileName);
        QSettings settings(fileName, QSettings::IniFormat);
        settings.remove(key);
    }

    emit settingsChanged(key, usingLocalConfig, usingLocalConfig ? fileInfo.absoluteFilePath() : "");
    if (usingLocalConfig || key.startsWith("View/")) {
        emit viewSettingsChanged(usingLocalConfig ? fileInfo.absolutePath() : "");
    }
}

QStringList RawSettingsHandler::keys(QString group, QString fileName) {
    if (fileName.isEmpty()) fileName = m_globalConfigPath;
    QFileInfo fileInfo = QFileInfo(fileName);
    QStringList keys;

    if (!fileInfo.exists() || !fileInfo.isReadable() || pathIsProtected(fileName)) {
        QMutexLocker locker(&m_mutex);
        keys = getRuntimeSettings(fileInfo).uniqueKeys();
    } else {
        flushRuntimeSettings(fileName);
        QSettings settings(fileName, QSettings::IniFormat);
        if (!group.isEmpty()) settings.beginGroup(group);
        keys = settings.allKeys();
    }

    for (int i = 0; i < keys.length(); i++) {
        // Un-sanitize keys. FIXME: this is a dirty hack.
        keys[i] = keys[i].replace('#', '/');
    }

    return keys;
}

QString RawSettingsHandler::configDirectory() const
{
    return m_globalConfigDir;
}

QString DirectorySettings::initialDirectory()
{
    // Static member variables are used to make sure that the initial
    // directory can be defined from the command line (in the main function)
    // and is still available in all instances of this class.
    //
    // IMPORTANT: when initializing the main app window, the initial directory
    // must be read from the global settings object. Otherwise, the value
    // from the command line will not be stored here.
    //
    // Tl;dr: us this code in QML:
    //     import harbour.file.browser.Settings 1.0
    //     ... = GlobalSettings.initialDirectory
    //
    // Rationale: this is disgusting and complicated but it avoids the
    // need to create a DirectorySettings object on startup, and it provides
    // a clearer API. It makes more sense to access the initial directory
    // through the settings API than as a global context property.

    if (!s_cachedInitialDirectory.isEmpty()) {
        return s_cachedInitialDirectory;
    }

    QString initialDirectory;
    int initialDirectoryMode;

    if (s_haveForcedInitialDirectory) {
        QFileInfo info(s_forcedInitialDirectory);
        initialDirectoryMode = -1;
        initialDirectory = info.absoluteFilePath();
    } else {
        initialDirectoryMode = get_generalInitialDirectoryMode();

        if (initialDirectoryMode == InitialDirectoryMode::Home) {
            initialDirectory = QDir::homePath();
        } else if (initialDirectoryMode == InitialDirectoryMode::Last) {
            initialDirectory = get_generalLastDirectoryPath();
        } else if (initialDirectoryMode == InitialDirectoryMode::Custom) {
            initialDirectory = get_generalCustomInitialDirectoryPath();
        } else {
            initialDirectory = getDefault_generalCustomInitialDirectoryPath();
        }
    }

    if (!QFileInfo::exists(initialDirectory) || !QFileInfo(initialDirectory).isDir()) {
        qDebug() << "initial directory" << initialDirectory <<
                    "does not exist, resetting to home directory | mode:" << initialDirectoryMode;
        initialDirectory = QDir::homePath();
    } else {
        qDebug() << "using initial directory" << initialDirectory << "| mode:" << initialDirectoryMode;
    }

    s_cachedInitialDirectory = initialDirectory;
    return s_cachedInitialDirectory;
}

bool DirectorySettings::systemSettingsEnabled()
{
#ifdef NO_FEATURE_STORAGE_SETTINGS
    return false;
#else
    return !storageSettingsPath().isEmpty();
#endif
}

QString DirectorySettings::storageSettingsPath()
{
#ifdef NO_FEATURE_STORAGE_SETTINGS
    return QStringLiteral("");
#else
    if (!s_cachedStorageSettingsPath.isEmpty()) return s_cachedStorageSettingsPath;

    // This should normally be </usr/share/>jolla-settings/pages/storage/storage.qml.
    // The result will be empty if the file is missing or cannot be accessed, e.g
    // due to sandboxing. Therefore, we don't need compile-time switches to turn it off.
    s_cachedStorageSettingsPath = QStandardPaths::locate(QStandardPaths::GenericDataLocation,
                                                   "jolla-settings/pages/storage/storage.qml",
                                                   QStandardPaths::LocateFile);
    return s_cachedStorageSettingsPath;
#endif
}

bool DirectorySettings::pdfViewerEnabled()
{
#ifdef NO_FEATURE_PDF_VIEWER
    return false;
#else
    return !pdfViewerPath().isEmpty();
#endif
}

QString DirectorySettings::pdfViewerPath()
{
#ifdef NO_FEATURE_PDF_VIEWER
    return QStringLiteral("");
#else
    if (!s_cachedPdfViewerPath.isEmpty()) {
        return s_cachedPdfViewerPath;
    }

    // This requires access to the system documents viewer.
    // The feature will be disabled if core QML files are missing or cannot be
    // accessed, e.g due to sandboxing. Therefore, we don't need compile-time
    // switches to turn it off.

    s_cachedPdfViewerPath = QStringLiteral("Sailfish.Office.PDFDocumentPage");

    if (!QFileInfo::exists(
                QStringLiteral("/usr/lib/") +
                QStringLiteral("qt5/qml/Sailfish/Office/PDFDocumentPage.qml"))) {
        if (!QFileInfo::exists(
                    QStringLiteral("/usr/lib64/") +
                    QStringLiteral("qt5/qml/Sailfish/Office/PDFDocumentPage.qml"))) {
            s_cachedPdfViewerPath = QLatin1String("");
        }
    }

    return s_cachedPdfViewerPath;
#endif
}

bool DirectorySettings::sharingEnabled()
{
#ifdef NO_FEATURE_SHARING
    return false;
#else
    return sharingMethod() != SharingMethod::Disabled;
#endif
}

SharingMethod::Enum DirectorySettings::sharingMethod()
{
#ifdef NO_FEATURE_SHARING
    return SharingMethod::Disabled;
#else
    if (s_cachedSharingMethodDetermined) {
        return s_cachedSharingMethod;
    }

    SharingMethod::Enum method = SharingMethod::Disabled;

    if (   QFileInfo::exists(
                QStringLiteral("/usr/lib/") +
                QStringLiteral("qt5/qml/Sailfish/Share/qmldir"))
        || QFileInfo::exists(
                QStringLiteral("/usr/lib64/") +
                QStringLiteral("qt5/qml/Sailfish/Share/qmldir"))) {
        method = SharingMethod::Share;
    } else if (
           QFileInfo::exists(
                QStringLiteral("/usr/lib/") +
                QStringLiteral("qt5/qml/Sailfish/TransferEngine/qmldir"))
        || QFileInfo::exists(
                QStringLiteral("/usr/lib64/") +
                QStringLiteral("qt5/qml/Sailfish/TransferEngine/qmldir"))) {
        method = SharingMethod::TransferEngine;
    }

    if (method == SharingMethod::Disabled) {
        qDebug() << "no supported sharing system found";
    }

    s_cachedSharingMethod = method;
    return s_cachedSharingMethod;
#endif
}

bool DirectorySettings::runningAsRoot() const
{
    if (geteuid() == 0) return true;
    return false;
}

void DirectorySettings::setAuthenticatedForRoot(bool isOk)
{
    if (isOk == s_authenticatedForRoot) return;

    if (runningAsRoot()) {
        s_authenticatedForRoot = isOk;
        emit authenticatedForRootChanged();
    } else {
        qDebug() << "not running as root, so ignoring request to change 'authenticatedForRoot'";
        s_authenticatedForRoot = false;
        emit authenticatedForRootChanged();
    }
}

DirectorySettings::DirectorySettings(QObject* parent) : QObject(parent) {}

DirectorySettings::DirectorySettings(QString path, QObject *parent) :
    QObject(parent), m_path(path) {}

DirectorySettings::DirectorySettings(bool, QString initialDir)
    : QObject(nullptr)
{
    if (s_haveForcedInitialDirectory && initialDir != s_forcedInitialDirectory) {
        qDebug() << "cannot reset forced initial directory from" <<
                    s_forcedInitialDirectory << "to" << initialDir;
    } else if (!initialDir.isEmpty()) {
        qDebug() << "using forced initial directory" << initialDir;
        s_haveForcedInitialDirectory = true;
        s_forcedInitialDirectory = initialDir;
    }
}

DirectorySettings::~DirectorySettings()
{
    //
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


enum BookmarkRole {
    groupRole =         Qt::UserRole +  1,
    nameRole =          Qt::UserRole +  2,
    thumbnailRole =     Qt::UserRole +  3,
    pathRole =          Qt::UserRole +  4,
    showSizeRole =      Qt::UserRole +  5,
    userDefinedRole =   Qt::UserRole +  6
};

namespace {
    void migrateBookmarks(QString bookmarksFile)
    {
        if (QFile::exists(bookmarksFile)) {
            return;
        }

        qDebug() << "migrating bookmarks from old config location to" << bookmarksFile;

        std::string order = RawSettingsHandler::instance()->read(
                    QStringLiteral("Bookmarks/Entries"), QStringLiteral("[]")).toStdString();
        auto inDoc = QJsonDocument::fromJson(QByteArray::fromStdString(order));

        QStringList keys;
        QJsonArray outArray;

        if (inDoc.isArray()) {
            const auto inArray = inDoc.array();
            for (const auto& i : inArray) {
                QString path = i.toString();
                QString name = RawSettingsHandler::instance()->read(
                            QStringLiteral("Bookmarks/") + path, path.split("/").last());

                QJsonObject obj;
                obj.insert(QStringLiteral("name"), name);
                obj.insert(QStringLiteral("path"), path);
                outArray.append(obj);
                keys.append(path);
            }
        }

        {
            ConfigFileMonitor out;
            out.reset(bookmarksFile, ConfigFileMonitor::InitiallyPaused);

            if (!out.writeJson(outArray, QStringLiteral("1"))) {
                qWarning() << "failed to migrate bookmarks to new location at" << bookmarksFile;
                return;
            }
        }

        qDebug() << "removing bookmarks from old location";

        for (const auto& i : std::as_const(keys)) {
            RawSettingsHandler::instance()->remove(QStringLiteral("Bookmarks/") + i);
        }
        RawSettingsHandler::instance()->remove(QStringLiteral("Bookmarks/Entries"));

        qDebug() << "bookmarks successfully migrated";
    }
}

BookmarksModel::BookmarksModel(QObject *parent) :
    QAbstractListModel(parent),
    m_mountsPollingTimer(new QTimer(this)),
    m_bookmarksMonitor(new ConfigFileMonitor(this))
{
    // NOTE Add only full paths to this list.
    //      Ignored base paths like /opt/appsupport/ where all mount points are
    //      to be ignored are listed in BookmarksModel::updateExternalDevices().
    m_ignoredMounts.insert(qHash(QStringLiteral("/")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/persist")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/dsp")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/odm")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/home")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/firmware")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/bt_firmware")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/firmware_mnt")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/metadata")));
    m_ignoredMounts.insert(qHash(QStringLiteral("/mnt/vendor/persist")));

    QString bookmarksFile = RawSettingsHandler::instance()->configDirectory() + "/bookmarks.json";

    if (!QFile::exists(bookmarksFile)) {
        QtConcurrent::run([=](){ migrateBookmarks(bookmarksFile); });
    }

    m_bookmarksMonitor->reset(bookmarksFile);
    connect(m_bookmarksMonitor, &ConfigFileMonitor::configChanged, this, &BookmarksModel::reload);

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
    QList<int> toRemove;
    toRemove.reserve(m_entries.size());

    for (int i = m_entries.length()-1; i >= 0; --i) {
        if (m_entries.at(i).group == BookmarkGroup::Temporary) {
            toRemove.append(i);
        }
    }

    for (auto i : toRemove) {
        beginRemoveRows(QModelIndex(), i, i);
        m_entries.removeAt(i);
        endRemoveRows();
    }
}

void BookmarksModel::sortFilter(QVariantList order)
{
    QList<BookmarkGroup::Enum> newOrder;
    for (const auto& i : std::as_const(order)) {
        if (i.isValid()) newOrder.append(i.value<BookmarkGroup::Enum>());
    }

    if (newOrder == m_groupsOrder) return;
    m_groupsOrder = newOrder;
    reload();
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

    for (const auto& i : activeMounts) {
        if (    i.isValid()
            &&  i.isReady()
            && !i.isRoot()
            &&  i.fileSystemType() != QStringLiteral("tmpfs")

            // NOTE List only paths below which all mount points are ignore in this list.
            //      Single ignored mount points are listed in the constructor.
            && !i.rootPath().startsWith(QStringLiteral("/opt/alien/"))
            && !i.rootPath().startsWith(QStringLiteral("/apex/"))
            && !i.rootPath().startsWith(QStringLiteral("/opt/appsupport/"))
            && !i.rootPath().startsWith(QStringLiteral("/vendor/"))
            && !i.rootPath().startsWith(QStringLiteral("/home/"))
            && !i.rootPath().startsWith(QStringLiteral("/dsp/"))
            && !i.rootPath().startsWith(QStringLiteral("/firmware/"))
            && !i.rootPath().startsWith(QStringLiteral("/bt_firmware/"))
            && !i.rootPath().startsWith(QStringLiteral("/firmware_mnt/"))
            && !i.rootPath().startsWith(QStringLiteral("/persist/"))
        ) {
            int pathHash = qHash(i.rootPath());

            if (!m_ignoredMounts.contains(pathHash)) {
                activeHashes.insert(pathHash);
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
                title, icon, i.rootPath(),
                true, false);

            beginInsertRows(QModelIndex(), nextExternalIndex, nextExternalIndex);
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
        m_entries.removeAt(i);
        if (m_firstExternalIndex <= m_firstUserDefinedIndex) {
            --m_firstUserDefinedIndex;
            --m_lastUserDefinedIndex;
            qDebug() << "changingB:" << nextExternalIndex << m_firstExternalIndex << m_lastUserDefinedIndex;
        }
        endRemoveRows();
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
    const auto value = m_bookmarksMonitor->readJson(QStringLiteral("1"));

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

            newEntries[BookmarkGroup::Bookmark].append(BookmarkItem(
                BookmarkGroup::Bookmark,
                name,
                QStringLiteral("icon-m-favorite"),
                path,
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

void BookmarksModel::save()
{
    QMutexLocker locker(&m_mutex);
    QJsonArray array;

    for (const auto& i : std::as_const(m_entries)) {
        if (!i.userDefined) continue;

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
    if (m_userDefinedLookup.contains(path)) return;

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
        path, false, true)
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
    if (fromIndex < 0 || fromIndex > rowCount() || fromIndex == toIndex
            || fromIndex < m_firstUserDefinedIndex || toIndex > m_lastUserDefinedIndex) {
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

QString BookmarksModel::loadBookmarksFile()
{
    return m_bookmarksMonitor->readFile();
}

QList<BookmarksModel::BookmarkItem> BookmarksModel::getStandardLocations()
{
    const static QList<BookmarkItem> ret {
        {
            BookmarkGroup::Location,
            tr("Home"),
            QStringLiteral("icon-m-home"),
            QStandardPaths::writableLocation(QStandardPaths::HomeLocation),
            true,
            false
        },
        {
            BookmarkGroup::Location,
            tr("Documents"),
            QStringLiteral("icon-m-file-document-light"),
            QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation),
            false,
            false
        },
        {
            BookmarkGroup::Location,
            tr("Downloads"),
            QStringLiteral("icon-m-cloud-download"),
            QStandardPaths::writableLocation(QStandardPaths::DownloadLocation),
            false,
            false
        },
        {
            BookmarkGroup::Location,
            tr("Music"),
            QStringLiteral("icon-m-file-audio"),
            QStandardPaths::writableLocation(QStandardPaths::MusicLocation),
            false,
            false
        },
        {
            BookmarkGroup::Location,
            tr("Pictures"),
            QStringLiteral("icon-m-file-image"),
            QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
            false,
            false
        },
        {
            BookmarkGroup::Location,
            tr("Videos"),
            QStringLiteral("icon-m-file-video"),
            QStandardPaths::writableLocation(QStandardPaths::MoviesLocation),
            false,
            false
        },
    };

    const static QList<BookmarkItem> androidStorage {{
        BookmarkGroup::Location,
        tr("Android storage"),
        QStringLiteral("icon-m-file-apk"),
        QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/android_storage",
        false,
        false
    }};

    const static QList<BookmarkItem> root {{
        BookmarkGroup::Location,
        tr("Root"),
        QStringLiteral("icon-m-file-rpm"),
        QStringLiteral("/"),
        true,
        false
    }};

    QFileInfo androidInfo(androidStorage[0].path);
    if (androidInfo.exists() && androidInfo.isDir()) {
        return ret + androidStorage + root;
    } else {
        return ret + root;
    }
}
