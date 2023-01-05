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

#include "settingshandler.h"

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

    if (QFileInfo::exists(
                QStringLiteral("/usr/lib/") +
                QStringLiteral("qt5/qml/Sailfish/Share/qmldir"))) {
        method = SharingMethod::Share;
    } else if (QFileInfo::exists(
                   QStringLiteral("/usr/lib/") +
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


enum {
    GroupRole =         Qt::UserRole +  1,
    NameRole =          Qt::UserRole +  2,
    ThumbnailRole =     Qt::UserRole +  3,
    PathRole =          Qt::UserRole +  4,
    ShowSizeRole =      Qt::UserRole +  5,
    UserDefinedRole =   Qt::UserRole +  6
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
        QJsonDocument outDoc;
        QJsonObject outObj;
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

        outObj.insert(QStringLiteral("version"), QStringLiteral("1"));
        outObj.insert(QStringLiteral("data"), outArray);
        outDoc.setObject(outObj);

        QSaveFile outFile(bookmarksFile);

        if (!outFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Unbuffered)) {
            qWarning() << "failed to open file to save migrated bookmarks";
            return;
        }

        outFile.write(outDoc.toJson(QJsonDocument::Indented));

        if (!outFile.commit()) {
            qWarning() << "failed to save migrated bookmarks";
            return;
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
    m_mountWatcher({QStringLiteral("/proc/mounts")}, this),
    m_bookmarksMonitor(new ConfigFileMonitor(this))
{
    QString bookmarksFile = RawSettingsHandler::instance()->configDirectory() + "/bookmarks.json";

    if (!QFile::exists(bookmarksFile)) {
        QtConcurrent::run([=](){ migrateBookmarks(bookmarksFile); });
    }

    m_bookmarksMonitor->reset(bookmarksFile);
    reload();

    connect(m_bookmarksMonitor, &ConfigFileMonitor::configChanged, this, &BookmarksModel::reload);
    connect(&m_mountWatcher, &QFileSystemWatcher::fileChanged, this, &BookmarksModel::updateExternalDevices);
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
    case NameRole:
        return entry.name;

    case GroupRole: return entry.group;
    case ThumbnailRole: return entry.thumbnail;
    case PathRole: return entry.path;
    case ShowSizeRole: return entry.showSize;
    case UserDefinedRole: return entry.userDefined;

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> BookmarksModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(GroupRole, QByteArray("group"));
    roles.insert(NameRole, QByteArray("name"));
    roles.insert(ThumbnailRole, QByteArray("thumbnail"));
    roles.insert(PathRole, QByteArray("path"));
    roles.insert(ShowSizeRole, QByteArray("showSize"));
    roles.insert(UserDefinedRole, QByteArray("userDefined"));
    return roles;
}

void BookmarksModel::add(QString path, QString name)
{
    appendItem(path, name, true);
}

void BookmarksModel::addTemporary(QString path, QString name)
{
    appendItem(path, name, false);
}

void BookmarksModel::remove(QString path)
{
    removeItem(path, true);
}

void BookmarksModel::removeTemporary(QString path)
{
    removeItem(path, false);
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

void BookmarksModel::moveUp(QString path)
{
    if (!m_indexLookup.contains(path)) {
        return;
    }

    int fromIndex = m_indexLookup.value(path, -1);
    int toIndex = 0;

    if (fromIndex < 0 || fromIndex > rowCount()) {
        qDebug() << "moving bookmark up: no" << fromIndex << rowCount();
        return;
    } else if (fromIndex == std::max(0, m_firstUserDefinedIndex)) {
        // already at the top? cycle to the bottom
        qDebug() << "moving bookmark up: already at the top" << fromIndex << m_firstUserDefinedIndex;
        toIndex = rowCount();
    } else {
        qDebug() << "moving bookmark up: normal" << fromIndex << fromIndex - 1;
        toIndex = fromIndex - 1;
    }

    moveItem(fromIndex, toIndex);
}

void BookmarksModel::moveDown(QString path)
{
    if (!m_indexLookup.contains(path)) {
        return;
    }

    int fromIndex = m_indexLookup.value(path, -1);
    int toIndex = 0;

    if (fromIndex < 0 || fromIndex > rowCount()) {
        return;
    } else if (fromIndex + 1 >= rowCount()) {
        // already at the bottom? cycle to the top
        toIndex = std::max(0, m_firstUserDefinedIndex);
    } else {
        toIndex = fromIndex + 1;
    }

    moveItem(fromIndex, toIndex);
}

void BookmarksModel::rename(QString path, QString newName)
{

    if (!m_indexLookup.contains(path) || newName.isEmpty()) {
        return;
    }

    int idx = m_indexLookup.value(path);

    m_entries[idx].name = newName;

    QModelIndex topLeft = index(idx, 0);
    QModelIndex bottomRight = index(idx, 0);
    emit dataChanged(topLeft, bottomRight, {NameRole});

    save();
    notifyWatchers(m_entries.at(idx).path);
}

bool BookmarksModel::hasBookmark(QString path) const
{
    if (m_indexLookup.contains(path)) {
        return true;
    }

    return false;
}

QString BookmarksModel::getBookmarkName(QString path) const
{
    if (path.isEmpty() || !m_indexLookup.contains(path)) {
        return QLatin1Literal();
    }

    return m_entries.at(m_indexLookup.value(path)).name;
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

void BookmarksModel::updateExternalDevices()
{
    QList<int> toRemove;
    toRemove.reserve(m_entries.size());

    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).group == BookmarkGroup::External) {
            toRemove.append(i);
        }
    }

    auto emptyIndex = QModelIndex();
    for (auto i : toRemove) {
        beginRemoveRows(emptyIndex, i, i);
        endRemoveRows();
    }

    int firstEntry = toRemove.first();
    const auto drives = externalDrives();

    beginInsertRows(QModelIndex(), firstEntry, firstEntry+drives.size());
    for (const auto& i : std::as_const(drives)) {
        m_entries.insert(firstEntry, i);
        firstEntry++;
    }
    endInsertRows();
}

void BookmarksModel::reload()
{
    QList<BookmarkItem> newEntries;
    QMap<QString, int> newIndexLookup;

    // populate model with default locations shortcuts

    newEntries.append(BookmarkItem(
        BookmarkGroup::Location,
        tr("Home"),
        QStringLiteral("icon-m-home"),
        QStandardPaths::writableLocation(QStandardPaths::HomeLocation),
        true,
        false)
    );

    newEntries.append(BookmarkItem(
        BookmarkGroup::Location,
        tr("Documents"),
        QStringLiteral("icon-m-file-document-light"),
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation),
        false,
        false)
    );

    newEntries.append(BookmarkItem(
        BookmarkGroup::Location,
        tr("Downloads"),
        QStringLiteral("icon-m-cloud-download"),
        QStandardPaths::writableLocation(QStandardPaths::DownloadLocation),
        false,
        false)
    );

    newEntries.append(BookmarkItem(
        BookmarkGroup::Location,
        tr("Music"),
        QStringLiteral("icon-m-file-audio"),
        QStandardPaths::writableLocation(QStandardPaths::MusicLocation),
        false,
        false)
    );

    newEntries.append(BookmarkItem(
        BookmarkGroup::Location,
        tr("Pictures"),
        QStringLiteral("icon-m-file-image"),
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
        false,
        false)
    );

    newEntries.append(BookmarkItem(
        BookmarkGroup::Location,
        tr("Videos"),
        QStringLiteral("icon-m-file-video"),
        QStandardPaths::writableLocation(QStandardPaths::MoviesLocation),
        false,
        false)
    );

    QString androidPath = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/android_storage";
    QFileInfo androidInfo(androidPath);

    if (androidInfo.exists() && androidInfo.isDir()) {
        newEntries.append(BookmarkItem(
            BookmarkGroup::Location,
            tr("Android storage"),
            QStringLiteral("icon-m-file-apk"),
            androidPath,
            false,
            false)
        );
    }

    newEntries.append(BookmarkItem(
        BookmarkGroup::Location,
        tr("Root"),
        QStringLiteral("icon-m-file-rpm"),
        QStringLiteral("/"),
        true,
        false)
    );

    newEntries.append(externalDrives());

    // load user defined bookmarks
    m_firstUserDefinedIndex = newEntries.length();

    const auto value = m_bookmarksMonitor->readJson(QStringLiteral("1"));

    if (value.isArray()) {
        const auto array = value.toArray();
        int idx = m_firstUserDefinedIndex;

        for (const auto& i : array) {
            if (!i.isObject()) {
                qWarning() << "invalid bookmarks entry in" << m_bookmarksMonitor->file() << i;
                continue;
            }

            auto obj = i.toObject();
            QString path = obj.value(QStringLiteral("path")).toString(QStringLiteral("/home"));
            QString name = obj.value(QStringLiteral("name")).toString(path.split("/").last());

            newEntries.append(BookmarkItem(
                BookmarkGroup::Bookmark,
                name,
                QStringLiteral("icon-m-favorite"),
                path,
                false, true));
            newIndexLookup.insert(path, idx);
            ++idx;
        }
    } else {
        qWarning() << "invalid bookmarks data in" << m_bookmarksMonitor->file() << value;
    }

    m_lastUserDefinedIndex = newEntries.length();

    beginResetModel();
    m_entries = newEntries;
    m_indexLookup = newIndexLookup;
    endResetModel();
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

void BookmarksModel::moveItem(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex > rowCount()) {
        return;
    }

    qDebug() << "moving bookmark:" << fromIndex << toIndex;

    // Moving rows using the beginMoveRows()/endMoveRows()/m_entries.move()
    // functions is incredibly slow for some reason.
    // Removing the row and adding it again has good performance.

    int lastIndex = rowCount();
    if (toIndex > lastIndex) {
        toIndex = lastIndex;
    }

    beginRemoveRows(QModelIndex(), fromIndex, fromIndex);
    auto item = m_entries.takeAt(fromIndex);
    m_indexLookup.remove(item.path);
    endRemoveRows();

    // the position we want to move to just moved one place
    // up because we removed the old entry
    if (toIndex > fromIndex) {
        toIndex -= 1;
    }

    beginInsertRows(QModelIndex(), toIndex, toIndex);
    m_entries.insert(toIndex, item);
    rebuildIndexLookup();
    endInsertRows();

    save();
}

void BookmarksModel::appendItem(QString path, QString name, bool doSave)
{
    if (name.isEmpty()) {
        QDir dir(path);
        name = dir.dirName();

        if (name.isEmpty()) {
            name = QStringLiteral("/");
        }
    }

    auto last = rowCount();
    beginInsertRows(QModelIndex(), last, last);
    m_entries.append(BookmarkItem(
        doSave ? BookmarkGroup::Bookmark : BookmarkGroup::Temporary,
        name,
        doSave ? QStringLiteral("icon-m-favorite") : QStringLiteral("icon-m-file-folder"),
        path, false, true));
    m_indexLookup.insert(path, last);
    endInsertRows();

    if (doSave) {
        save();
        notifyWatchers(path);
    }
}

void BookmarksModel::removeItem(QString path, bool doSave)
{
    if (!m_indexLookup.contains(path)) {
        return;
    }

    auto index = m_indexLookup.value(path);
    beginRemoveRows(QModelIndex(), index, index);
    m_entries.removeAt(index);
    rebuildIndexLookup();
    endRemoveRows();

    if (doSave) {
        notifyWatchers(path);
        save();
    }
}

QString BookmarksModel::loadBookmarksFile()
{
    return m_bookmarksMonitor->readFile();
}

void BookmarksModel::rebuildIndexLookup()
{
    m_indexLookup.clear();

    for (int i = 0; i < m_entries.count(); ++i) {
        if (m_entries.at(i).userDefined) {
            m_indexLookup.insert(m_entries.at(i).path, i);
        }
    }
}

QStringList BookmarksModel::subdirs(const QString &dirname, bool includeHidden)
{
    QDir dir(dirname);
    if (!dir.exists()) return QStringList();

    QDir::Filter hiddenFilter = includeHidden ? QDir::Hidden : static_cast<QDir::Filter>(0);
    dir.setFilter(QDir::AllDirs | QDir::NoDotAndDotDot | hiddenFilter);

    const QStringList list = dir.entryList();
    QStringList abslist;

    for (const auto& relpath : list) {
        abslist.append(dir.absoluteFilePath(relpath));
    }

    return abslist;
}

QList<BookmarksModel::BookmarkItem> BookmarksModel::externalDrives()
{
    // from SailfishOS 2.2.0 onwards, "/media/sdcard" is
    // a symbolic link instead of a folder. In that case, follow the link
    // to the actual folder.
    QString sdcardFolder = "/media/sdcard";
    QFileInfo fileinfo(sdcardFolder);
    if (fileinfo.isSymLink()) sdcardFolder = fileinfo.symLinkTarget();

    // get sdcard dir candidates for "/media/sdcard" (or its symlink target)
    QStringList candidates = subdirs(sdcardFolder);

    // If the base folder is not already /run/media/USER, we add it too. This
    // is where OTG devices will be mounted.
    // Also, some users may have a symlink from "/media/sdcard/USER"
    // (not from "/media/sdcard"), which means no SD cards would be found before,
    // so we also get candidates for those users.
    QString expectedUserFolder = QString("/run/media/") + QDir::home().dirName();
    if (sdcardFolder != expectedUserFolder) candidates.append(subdirs(expectedUserFolder));

    // no candidates found, abort
    if (candidates.isEmpty()) return {};

    // remove all directories which are not mount points
    QMap<QString, QString> mps = mountPoints();
    QMutableStringListIterator i(candidates);
    while (i.hasNext()) {
        QString dirname = i.next();
        if (!mps.contains(dirname)) i.remove();
    }

    // all candidates eliminated, abort
    if (candidates.isEmpty()) return {};

    QList<BookmarkItem> ret;
    for (const auto& drive : std::as_const(candidates)) {
        QString title;
        bool isSdCard;

        if (mps[drive].startsWith("/dev/mmc")) {
            title = tr("SD card");
            isSdCard = true;
        } else {
            title = tr("Removable Media");
            isSdCard = false;
        }

        ret.append(BookmarkItem(
            BookmarkGroup::External,
            title,
            isSdCard ? QStringLiteral("icon-m-sd-card")
                     : QStringLiteral("icon-m-usb"),
            drive,
            true,
            false)
        );
    }

    return ret;
}

QMap<QString, QString> BookmarksModel::mountPoints()
{
    // read /proc/mounts and return all mount points for the filesystem
    QFile file("/proc/mounts");
    if (!file.open(QFile::ReadOnly | QFile::Text))
        return QMap<QString, QString>();

    QTextStream in(&file);
    QString result = in.readAll();

    // split result to lines
    const QStringList lines = result.split(QRegExp("[\n\r]"));

    // get columns
    QMap<QString, QString> paired;
    for (const auto& line : lines) {
        QStringList columns = line.split(QRegExp("\\s+"), QString::SkipEmptyParts);
        if (columns.count() < 6) continue; // sanity check
        paired[columns.at(1)] = columns.at(0);
    }

    return paired;
}
