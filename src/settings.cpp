/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2020-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "settings.h"
#include "bookmarks.h"

#include <unistd.h>

#include <QMutexLocker>
#include <QSettings>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QQmlEngine>


QSharedPointer<RawSettingsHandler> \
    RawSettingsHandler::s_globalInstance = \
        QSharedPointer<RawSettingsHandler>(nullptr);


QString DirectorySettings::s_cachedInitialDirectory = QLatin1Literal();
QString DirectorySettings::s_forcedInitialDirectory = QLatin1Literal();
bool DirectorySettings::s_haveForcedInitialDirectory = false;
QString DirectorySettings::s_cachedStorageSettingsPath = QLatin1Literal();
QString DirectorySettings::s_cachedSpaceInspectorPath = QLatin1Literal();
QString DirectorySettings::s_cachedPdfViewerPath = QLatin1Literal();
SharingMethod::Enum DirectorySettings::s_cachedSharingMethod = SharingMethod::Disabled;
bool DirectorySettings::s_cachedSharingMethodDetermined = false;
bool DirectorySettings::s_authenticatedForRoot = false;

DEFINE_ENUM_REGISTRATION_FUNCTION(SettingsHandler) {
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
                      "path is protected or not writable at" <<
                      QFileInfo(m_globalConfigPath).absolutePath();
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

BookmarksModel* DirectorySettings::bookmarks() {
    return BookmarksModel::instance();
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

bool DirectorySettings::spaceInspectorEnabled()
{
#ifdef NO_FEATURE_SPACE_INSPECTOR
    return false;
#else
    return !spaceInspectorPath().isEmpty();
#endif
}

QString DirectorySettings::spaceInspectorPath()
{
#ifdef NO_FEATURE_SPACE_INSPECTOR
    return QStringLiteral("");
#else
    if (!s_cachedSpaceInspectorPath.isEmpty()) {
        return s_cachedSpaceInspectorPath;
    }

    QString& newPath = s_cachedSpaceInspectorPath;

    newPath =
        QStringLiteral("/opt/sdk/") +
        QStringLiteral("harbour-space-inspector/usr/"
                       "bin/harbour-space-inspector");

    if (!QFileInfo::exists(newPath)) {
        newPath = QStringLiteral("/usr/bin/") +
                  QStringLiteral("harbour-space-inspector");

        if (!QFileInfo::exists(newPath)) {
            newPath = QLatin1String("");
        }
    }

    if (!newPath.isEmpty() && !QFileInfo(newPath).isExecutable()) {
        qDebug() << "found space inspector at" << newPath
                 << "but the file is not executable";
        newPath = QLatin1String("");
    }

    return s_cachedSpaceInspectorPath;
#endif
}

bool DirectorySettings::launchSpaceInspector(const QString& folder)
{
#ifdef NO_FEATURE_SPACE_INSPECTOR
    return false;
#else
    if (!spaceInspectorEnabled()) {
        return false;
    }

    QFileInfo folderInfo(folder);
    QFileInfo appInfo(spaceInspectorPath());
    QStringList args = {folderInfo.absoluteFilePath()};

    if (!folderInfo.isDir()) {
        return false;
    }

    return QProcess::startDetached(
        appInfo.absoluteFilePath(), args);
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

bool DirectorySettings::runningInSailjail()
{
#ifdef NO_HARBOUR_COMPLIANCE
    return false;
#else
    return true;
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
