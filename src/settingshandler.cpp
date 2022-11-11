/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020-2022 Mirian Margiani
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

#include <QMutexLocker>
#include <QSettings>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QQmlEngine>
#include <QJsonArray>
#include <QJsonDocument>

#include "settingshandler.h"

QSharedPointer<RawSettingsHandler> \
    RawSettingsHandler::m_globalInstance = \
        QSharedPointer<RawSettingsHandler>(nullptr);

QSharedPointer<BookmarksModel> \
    BookmarksModel::m_globalInstance = \
        QSharedPointer<BookmarksModel>(nullptr);


RawSettingsHandler::RawSettingsHandler(QObject *parent)
    : QObject(parent)
{
    // Explicitly set the QML ownership so we can use the same singleton
    // instance in C++ and in QML.
    // - https://doc.qt.io/qt-5/qqmlengine.html#qmlRegisterSingletonType-1
    // - https://stackoverflow.com/a/68873634
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);

    QString newConfigDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QString configFile = QCoreApplication::applicationName() + ".conf";
    QSettings global(newConfigDir + "/" + configFile, QSettings::IniFormat);
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

    qDebug() << "[SettingsHandler] writing:" << key << "=" << value << "in" << fileName;

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

    qDebug() << "[SettingsHandler] deleting:" << key << "in" << fileName;

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

DirectorySettings::DirectorySettings(QObject* parent) : QObject(parent) {}

DirectorySettings::DirectorySettings(QString path, QObject *parent) :
    QObject(parent), m_path(path) {}

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
//    BookmarksModel::instance()->unregisterWatcher(m_path, QSharedPointer(this));
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
    PathRole = Qt::UserRole +  1,
    NameRole = Qt::UserRole +  2,
};

BookmarksModel::BookmarksModel(QObject *parent) :
    QAbstractListModel(parent)
{
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
    case PathRole:
        return entry.first;

    case Qt::DisplayRole:
    case NameRole:
        return entry.second;

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> BookmarksModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(PathRole, QByteArray("path"));
    roles.insert(NameRole, QByteArray("name"));
    return roles;
}

void BookmarksModel::add(QString path, QString name)
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
    m_entries.append({path, name});
    m_indexLookup.insert(path, last);
    endInsertRows();

    saveItem(path, name);
    saveOrder();
}

void BookmarksModel::remove(QString path)
{
    if (!m_indexLookup.contains(path)) {
        return;
    }

    auto index = m_indexLookup.value(path);
    beginRemoveRows(QModelIndex(), index, index);
    m_entries.removeAt(index);
    m_indexLookup.remove(path);
    endRemoveRows();

    removeItem(path);
    saveOrder();
}

void BookmarksModel::moveUp(QString path)
{
    if (!m_indexLookup.contains(path)) {
        return;
    }

    int fromIndex = m_indexLookup.value(path);

    if (fromIndex < 0 || fromIndex > rowCount()) {
        return;
    } else if (fromIndex-1 < 0) {
        // already at the top? cycle to the bottom
        beginMoveRows(QModelIndex(), fromIndex, fromIndex, QModelIndex(), rowCount()-1);
        m_entries.move(fromIndex, rowCount()-1);
    } else {
        beginMoveRows(QModelIndex(), fromIndex, fromIndex, QModelIndex(), fromIndex-1);
        m_entries.move(fromIndex, fromIndex-1);
    }

    m_indexLookup.clear();
    for (int i = 0; i < m_entries.count(); ++i) {
        m_indexLookup.insert(m_entries.at(i).first, i);
    }

    endMoveRows();

    saveOrder();
}

void BookmarksModel::moveDown(QString path)
{
    if (!m_indexLookup.contains(path)) {
        return;
    }

    int fromIndex = m_indexLookup.value(path);

    if (fromIndex < 0 || fromIndex > rowCount()) {
        return;
    } else if (fromIndex+1 >= rowCount()) {
        // already at the bottom? cycle to the top
        beginMoveRows(QModelIndex(), fromIndex, fromIndex, QModelIndex(), 0);
        m_entries.move(fromIndex, 0);
    } else {
        beginMoveRows(QModelIndex(), fromIndex, fromIndex, QModelIndex(), fromIndex+1);
        m_entries.move(fromIndex, fromIndex+1);
    }

    m_indexLookup.clear();
    for (int i = 0; i < m_entries.count(); ++i) {
        m_indexLookup.insert(m_entries.at(i).first, i);
    }

    endMoveRows();

    saveOrder();
}

void BookmarksModel::rename(QString path, QString newName)
{
//    if (idx < 0 || idx > rowCount() || newName.isEmpty()) {
//        return;
//    }

    if (!m_indexLookup.contains(path) || newName.isEmpty()) {
        return;
    }

    int idx = m_indexLookup.value(path);

    m_entries[idx].second = newName;

    QModelIndex topLeft = index(idx, 0);
    QModelIndex bottomRight = index(idx, 0);
    emit dataChanged(topLeft, bottomRight, {NameRole});

    saveItem(m_entries.at(idx).first, newName);
}

bool BookmarksModel::hasBookmark(QString path)
{
    if (m_indexLookup.contains(path)) {
        return true;
    }

    return false;
}

QString BookmarksModel::getBookmarkName(QString path)
{
    if (path.isEmpty() || !m_indexLookup.contains(path)) {
        return QLatin1Literal();
    }

    return m_entries.at(m_indexLookup.value(path)).second;
}

QStringList BookmarksModel::getBookmarks()
{
    QStringList ret;

    for (const auto& i : std::as_const(m_entries)) {
        ret << i.first;
    }

    ret.removeDuplicates();
    return ret;
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

void BookmarksModel::reload()
{
    QString order = RawSettingsHandler::instance()->read(QStringLiteral("Bookmarks/Entries"), QStringLiteral("[]"));
    auto doc = QJsonDocument::fromJson(QByteArray::fromStdString(order.toStdString()));

    if (doc.isArray()) {
        int idx = 0;
        const auto array = doc.array();

        for (const auto& i : array) {
            QString path = i.toString();
            QString name = RawSettingsHandler::instance()->read(QStringLiteral("Bookmarks/") + path, path.split("/").last());
            m_entries.append({path, name});
            m_indexLookup.insert(path, idx);
            idx++;
        }
    }
}

void BookmarksModel::saveOrder()
{
    QJsonDocument doc;
    QVariantList list;

    for (int i = 0; i < m_entries.length(); ++i) {
        list.append(m_entries.at(i).first);
    }

    doc.setArray(QJsonArray::fromVariantList(list));
    RawSettingsHandler::instance()->write(QStringLiteral("Bookmarks/Entries"), doc.toJson(QJsonDocument::Compact));
}

void BookmarksModel::saveItem(QString path, QString name)
{
    RawSettingsHandler::instance()->write(QStringLiteral("Bookmarks/") + path, name);

    if (m_watchers.contains(path)) {
        for (auto& i : m_watchers.value(path)) {
            if (i) {
                i->refresh();
            }
        }
    }
}

void BookmarksModel::removeItem(QString path)
{
    RawSettingsHandler::instance()->remove(QStringLiteral("Bookmarks/") + path);

    if (m_watchers.contains(path)) {
        for (auto& i : m_watchers.value(path)) {
            if (i) {
                i->refresh();
            }
        }
    }
}
