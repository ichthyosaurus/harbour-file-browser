/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020-2024 Mirian Margiani
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

#ifndef SETTINGS_H
#define SETTINGS_H

#include <QVariant>
#include <QMap>
#include <QHash>
#include <QPair>
#include <QString>
#include <QMutex>
#include <QSharedPointer>
#include <QPointer>
#include <QDir>
#include <QAbstractListModel>
#include <QFileSystemWatcher>

#include "configfilemonitor.h"
#include "enumcontainer.h"
#include "property_macros.h"

class QFileInfo;

CREATE_ENUM(BookmarkGroup, Temporary, Location, External, Bookmark)
CREATE_ENUM(SharingMethod, Share, TransferEngine, Disabled)
CREATE_ENUM(InitialDirectoryMode, Home = 0, Last = 1, Custom = 2)
DECLARE_ENUM_REGISTRATION_FUNCTION(SettingsHandler)

// Generic settings handler class.
// This class provides access to "global" and "local" key-value pairs.
// Settings will be shadowed in memory if a settings file is not writable.
//
// Values are non-notifyable.

class RawSettingsHandler : public QObject
{
    Q_OBJECT

public:
    explicit RawSettingsHandler(QObject *parent = nullptr);
    virtual ~RawSettingsHandler();

    Q_INVOKABLE bool pathIsProtected(QString path) const;
    Q_INVOKABLE QString read(QString key, QString defaultValue = QString(), QString fileName = QString());
    Q_INVOKABLE void write(QString key, QString value, QString fileName = QString());
    Q_INVOKABLE void remove(QString key, QString fileName = QString());
    Q_INVOKABLE QStringList keys(QString group = QString(), QString fileName = QString());
    Q_INVOKABLE QString configDirectory() const;

    QVariant readVariant(QString key, const QVariant& defaultValue = QVariant(), QString fileName = QString());
    void writeVariant(QString key, const QVariant& value, QString fileName = QString());
    bool hasKey(QString key, QString fileName = QString());

    static RawSettingsHandler* instance() {
        if (s_globalInstance.isNull()) s_globalInstance.reset(new RawSettingsHandler());
        return s_globalInstance.data();
    }

signals:
    void settingsChanged(QString key, bool locally, QString localPath);
    void viewSettingsChanged(QString localPath);

private:
    void sanitizeKey(QString& key) const;
    void flushRuntimeSettings(QString fileName);
    bool hasRuntimeSettings(QFileInfo file) const;
    QMap<QString, QVariant>& getRuntimeSettings(QFileInfo file);
    bool isWritable(QFileInfo file) const;

    // in-memory settings to be used when local settings are not available
    // It is a QMap of QMap, combining file paths with their local settings QMaps.
    QMap<QString, QMap<QString, QVariant>> m_runtimeSettings;
    QString m_globalConfigPath;
    QString m_globalConfigDir;
    QMutex m_mutex;

    static QSharedPointer<RawSettingsHandler> s_globalInstance;
};


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
    Q_INVOKABLE void rename(QString path, QString newName);
    Q_INVOKABLE bool hasBookmark(QString path) const;
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

private slots:
    void updateExternalDevices();
    void updateStandardLocations(const QList<LocationAlternative>& newExternalPaths, const uint& lostPathsCount);
    void reload();

private:
    void notifyWatchers(const QString& path);

    void addUserDefined(QString path, QString name, bool permanent);
    void removeUserDefined(QString path, bool permanent);
    int findUserDefinedIndex(QString path);

    QString loadBookmarksFile();

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

    bool m_haveAndroidPath {false};
    QMap<QStandardPaths::StandardLocation, QString> m_standardLocations;
    // BookmarkItem* m_documentsItem {nullptr};
    // BookmarkItem* m_downloadsItem {nullptr};
    // BookmarkItem* m_picturesItem {nullptr};
    // BookmarkItem* m_videosItem {nullptr};
    // BookmarkItem* m_musicItem {nullptr};

    // We monitor the bookmarks file except while saving entries.
    ConfigFileMonitor* m_bookmarksMonitor;

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


// Settings specific to File Browser.
// The following classes implement settings that are canonicalized and documented.
// These values are available as read-write properties and support signals.
//
// Prefer this class over reading and writing raw key-value pairs.
//
// Usage:
// import harbour.file.browser.Settings 1.0
// DirectorySettings { path: "/path/to/dir" }
//
// Specify a path to handle local settings. Leave the path empty to
// handle global settings only. A global object exposing global settings
// is available as "GlobalSettings" when importing the Settings module im QML.

#define QSL QStringLiteral
#include <QDebug>

class DirectorySettings : public QObject {
    Q_OBJECT

private:
    template<typename T>
    class Mapping : public QHash<QString, T> {
    public:
        template<typename U = T> // only available if T is QString
        Mapping(QString defaultValue, QStringList passthroughValues, typename std::enable_if<std::is_same_v<U, QString>>::type* = 0)
            : defaultValue({defaultValue, defaultValue}) {
            this->insert(defaultValue, defaultValue);
            for (auto& i : passthroughValues) this->insert(i, i);
        }

        Mapping(QPair<QString, T> defaultValue, QHash<QString, T> pairs)
            : QHash<QString, T>(pairs), defaultValue(defaultValue) {
            this->insert(defaultValue.first, defaultValue.second);
        }

        template<typename U = T> // only available if T is QString
        Mapping(QString defaultValue, bool allowAnyString, typename std::enable_if<std::is_same_v<U, QString>>::type* = 0)
            : defaultValue({defaultValue, defaultValue}), allowAnyString(allowAnyString) { }

        virtual T value(const QString& key, const T& fallback) {
            if constexpr (std::is_same_v<T, QString>) { if (allowAnyString) return key; }
            return QHash<QString, T>::value(key, fallback);
        }
        virtual T value(const QString& key) {
            if constexpr (std::is_same_v<T, QString>) { if (allowAnyString) return key; }
            return QHash<QString, T>::value(key);
        }

        virtual QString key(const T& value, const QString& fallback) {
            if constexpr (std::is_same_v<T, QString>) { if (allowAnyString) return value; }
            return QHash<QString, T>::key(value, fallback);
        }
        virtual QString key(const T& value) {
            if constexpr (std::is_same_v<T, QString>) { if (allowAnyString) return value; }
            return QHash<QString, T>::key(value);
        }

        QPair<QString, T> defaultValue;
        const bool allowAnyString {false};
    };

#define PROP(TYPE, NAME, GLOBAL_KEY, LOCAL_KEY, GLOBAL_MAP, LOCAL_MAP) \
    Q_PROPERTY(TYPE NAME READ get_##NAME WRITE set_##NAME NOTIFY NAME##Changed) \
    Q_PROPERTY(TYPE default_##NAME READ getDefault_##NAME NOTIFY NAME##DefaultChanged) \
    public: Q_SIGNAL void NAME##Changed(); \
    public: Q_SIGNAL void NAME##DefaultChanged(); \
    public: Q_SLOT void set_##NAME(TYPE newValue) { \
        setValue<TYPE>(QSL(GLOBAL_KEY), QSL(LOCAL_KEY), GLOBAL_MAP, LOCAL_MAP, newValue); \
        /* no "emit NAME##Changed();" to avoid signalling the change twice: once here, and once via Settings::settingsChanged */ \
    } \
    public: TYPE get_##NAME() const { \
        return getValue<TYPE>(QSL(GLOBAL_KEY), QSL(LOCAL_KEY), GLOBAL_MAP, LOCAL_MAP); \
    } \
    public: TYPE getDefault_##NAME() const { \
        return GLOBAL_MAP.defaultValue.second; \
    } \
    private: Q_SLOT void handle_##NAME(QString key, bool locally, QString localPath) { \
        if (locally && key == QSL(LOCAL_KEY) && localPath == m_localFile) { \
            /* qDebug() << "local setting changed:" << key << locally << localPath << m_localFile << #NAME; */ \
            emit NAME##Changed(); \
        } else if (!locally && key == QSL(GLOBAL_KEY)) { \
            /* qDebug() << "global settings changed: "#NAME << "from" << localPath; */ \
            emit NAME##Changed(); \
        } \
    } \
    private: QMetaObject::Connection conn_##NAME {connect(RawSettingsHandler::instance(), &RawSettingsHandler::settingsChanged, \
        this, &DirectorySettings::handle_##NAME)};

    //
    // vvv SETTINGS vvv
    //
    // Below is the definition of all documented settings.
    //
    // - values are verified automatically, invalid values will revert to the default
    // - each setting must define a global key with valid values
    // - optionally, a local key with (possibly different values) can be defined
    // - local-only settings are not possible
    //
    // How to define a setting:
    // 1. document the new setting in SETTINGS.md
    // 2. create a property:
    //    PROP(TYPE, NAME, GLOBAL_KEY, LOCAL_KEY, GLOBAL_MAP, LOCAL_MAP)
    //    - TYPE: should generally be bool or QString, other types are not really supported
    //    - NAME: property name to be used in QML; should follow the pattern "sectionGlobalKey", e.g. "generalEnableFoo"
    //    - GLOBAL_KEY: global key as documented in SETTINGS.md; pattern: "Section/PropertyName", e.g. "General/EnableFoo"
    //    - LOCAL_KEY: analogous to GLOBAL_KEY, empty string if the setting is global-only
    //    - GLOBAL_MAP: mapping defining valid values for the global key
    //    - LOCAL_MAP: analogous to GLOBAL_MAP; use the predefined "map_invalid" for global-only settings
    // 3. setup mappings if needed
    //    Mapping<TYPE> map_propertyName{{QSL("string-representation"), valueInCode}, {{{...}, {...}}, ...}};
    //    Mapping<TYPE> map_propertyName{QSL("valid-string"), {QSL("further-valid-string"), ...};
    //    Mapping<TYPE> map_propertyName{"", true}; -- allow any string without checking
    //    - TYPE: must be the same type as declared in the PROP macro
    //    - mappings map a string representation to an actual C++ value
    //    - the first entry in the mappings list is the default value for this setting
    //      (must be documented in SETTINGS.md)
    //    - use the predefined mappings "map_bool_true" for boolean values that are true by default,
    //      and "map_bool_false" for boolean values that are false by default
    //    - use "map_any_string" if the key is allowed to store an arbitrary string
    //
    // How to define settings with a custom API:
    // 1. document the setting in SETTINGS.md
    // 2. implement the API
    // 3. make sure the API exposes properties instead of methods where possible
    //

    // common value mappings
    Mapping<QString> map_invalid {QLatin1Literal(), {}};
    Mapping<bool> map_bool_true{{QSL("true"), true}, {{QSL("false"), false}}};
    Mapping<bool> map_bool_false{{QSL("false"), false}, {{QSL("true"), true}}};
    Mapping<QString> map_any_string{QLatin1Literal(), true};

    // [General] section
    Mapping<QString> map_filterAction{QSL("filter"), {QSL("search")}};
    PROP(QString, generalDefaultFilterAction, "General/DefaultFilterAction", "", map_filterAction, map_invalid)
    PROP(bool, generalShowFullDirectoryPaths, "General/ShowFullDirectoryPaths", "", map_bool_false, map_bool_false)
    PROP(bool, generalShowNavigationMenuIcon, "General/ShowNavigationMenuIcon", "", map_bool_true, map_bool_true)
    Mapping<QString> map_elideMode{QSL("fade"), {QSL("end"), QSL("middle")}};
    PROP(QString, generalFilenameElideMode, "General/FilenameElideMode", "", map_elideMode, map_invalid)
    PROP(bool, generalSolidWindowBackground, "General/SolidWindowBackground", "", map_bool_false, map_bool_false)
    Mapping<InitialDirectoryMode::Enum> map_initialDirMode{{QSL("home"), InitialDirectoryMode::Home}, {
            {QSL("last"), InitialDirectoryMode::Last}, {QSL("custom"), InitialDirectoryMode::Custom}}};
    Mapping<InitialDirectoryMode::Enum> map_initialDirInvalid{{QLatin1Literal(), {}}, {}};
    PROP(InitialDirectoryMode::Enum, generalInitialDirectoryMode, "General/InitialDirectoryMode", "", map_initialDirMode, map_initialDirInvalid)
    Mapping<QString> map_initialDirPath{QDir::homePath(), true};
    PROP(QString, generalCustomInitialDirectoryPath, "General/CustomInitialDirectoryPath", "", map_initialDirPath, map_invalid);
    PROP(QString, generalLastDirectoryPath, "General/LastDirectoryPath", "", map_initialDirPath, map_invalid);
    PROP(bool, generalShareClipboard, "General/ShareClipboard", "", map_bool_true, map_bool_true)
    // PROP(bool, generalUseTrashCan, "General/UseTrashCan", "", map_bool_true, map_bool_true)

    // [Transfer] section
    Mapping<QString> map_transferAction{QSL("none"), {QSL("copy"), QSL("move"), QSL("link")}};
    PROP(QString, transferDefaultAction, "Transfer/DefaultAction", "", map_transferAction, map_invalid)

    // [View] section
    Mapping<QString> map_sortRole{QSL("name"), {QSL("size"), QSL("modificationtime"), QSL("type")}};
    PROP(QString, viewSortRole, "View/SortRole", "Dolphin/SortRole", map_sortRole, map_sortRole)
    Mapping<QString> map_sortOrder_global{QSL("default"), {QSL("reversed")}};
    Mapping<QString> map_sortOrder_local{{QSL("0"), QSL("default")}, {{QSL("1"), QSL("reversed")}}}; // local to generic
    PROP(QString, viewSortOrder, "View/SortOrder", "Dolphin/SortOrder", map_sortOrder_global, map_sortOrder_local)
    PROP(bool, viewSortCaseSensitively, "View/SortCaseSensitively", "Sailfish/SortCaseSensitively", map_bool_false, map_bool_false)
    PROP(bool, viewShowDirectoriesFirst, "View/ShowDirectoriesFirst", "Dolphin/SortFoldersFirst", map_bool_true, map_bool_true)
    PROP(bool, viewShowHiddenLast, "View/ShowHiddenLast", "Dolphin/SortHiddenLast", map_bool_false, map_bool_false)
    PROP(bool, viewHiddenFilesShown, "View/HiddenFilesShown", "Settings/HiddenFilesShown", map_bool_false, map_bool_false)
    PROP(bool, viewPreviewsShown, "View/PreviewsShown", "Dolphin/PreviewsShown", map_bool_false, map_bool_false)
    Mapping<QString> map_previewSize{QSL("medium"), {QSL("small"), QSL("large"), QSL("huge")}};
    PROP(QString, viewPreviewsSize, "View/PreviewsSize", "Sailfish/PreviewsSize", map_previewSize, map_previewSize);
    PROP(bool, viewUseLocalSettings, "View/UseLocalSettings", "", map_bool_true, map_bool_true)
    Mapping<QString> map_viewMode{QSL("list"), {QSL("gallery"), QSL("grid")}};
    PROP(QString, viewViewMode, "View/ViewMode", "Sailfish/ViewMode", map_viewMode, map_viewMode);

    // [Bookmarks] section with custom API
    private: Q_PROPERTY(BookmarksModel* bookmarks READ bookmarks CONSTANT)
    public: BookmarksModel* bookmarks() { return BookmarksModel::instance(); }

    //
    // ^^^ SETTINGS ^^^
    //

    //
    // vvv CONSTANTS vvv
    //

    private: Q_PROPERTY(QString initialDirectory READ initialDirectory CONSTANT)
    public: QString initialDirectory();

    private: Q_PROPERTY(bool systemSettingsEnabled READ systemSettingsEnabled CONSTANT)
    private: Q_PROPERTY(QString storageSettingsPath READ storageSettingsPath CONSTANT)
    public: bool systemSettingsEnabled();
    public: QString storageSettingsPath();

    private: Q_PROPERTY(bool pdfViewerEnabled READ pdfViewerEnabled CONSTANT)
    private: Q_PROPERTY(QString pdfViewerPath READ pdfViewerPath CONSTANT)
    public: bool pdfViewerEnabled();
    public: QString pdfViewerPath();

    private: Q_PROPERTY(bool sharingEnabled READ sharingEnabled CONSTANT)
    private: Q_PROPERTY(SharingMethod::Enum sharingMethod READ sharingMethod CONSTANT)
    public: bool sharingEnabled();
    public: SharingMethod::Enum sharingMethod();

    private: Q_PROPERTY(bool runningAsRoot READ runningAsRoot CONSTANT)
    public: bool runningAsRoot() const;

    private: Q_PROPERTY(bool authenticatedForRoot READ authenticatedForRoot WRITE setAuthenticatedForRoot NOTIFY authenticatedForRootChanged)
    public: // if changing this is possible
        bool authenticatedForRoot() const { return s_authenticatedForRoot; }
        void setAuthenticatedForRoot(bool isOk);
        Q_SIGNAL void authenticatedForRootChanged();

    //
    // ^^^ CONSTANTS ^^^
    //

    //
    // vvv QML CONFIG vvv
    //

    private: Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    public:
    QString path() const { return m_path; }
    Q_SIGNAL void pathChanged(QString newValue);
    Q_SLOT void setPath(QString newValue) {
        m_path = newValue;
        m_localFile = m_path + QSL("/.directory");
        emit pathChanged(newValue);
    }

    //
    // ^^^ QML CONFIG ^^^
    //

public:
    // Specify a path to handle local settings. Leave the path empty to handle global settings only.
    explicit DirectorySettings(QObject* parent = nullptr);
    explicit DirectorySettings(QString path, QObject* parent);
    explicit DirectorySettings(bool, QString initialDir);
    ~DirectorySettings();

private:
    QString m_path {};
    QString m_localFile {};

    static QString s_cachedInitialDirectory;
    static QString s_forcedInitialDirectory;
    static bool s_haveForcedInitialDirectory;

    static QString s_cachedStorageSettingsPath;
    static QString s_cachedPdfViewerPath;
    static SharingMethod::Enum s_cachedSharingMethod;
    static bool s_cachedSharingMethodDetermined;
    static bool s_authenticatedForRoot;

    template<typename T>
    void setValue(QString globalKey, QString localKey, Mapping<T> globalMap, Mapping<T> localMap, T newValue) {
        // Write local settings if they are enabled, a local key is available, and
        // a local settings file is specified. Otherwise write global settings.
        if (   !m_localFile.isEmpty()
            && !localKey.isEmpty()
            && RawSettingsHandler::instance()->read(QSL("View/UseLocalSettings"), QSL("true")) == QSL("true")) {
            if (newValue == globalMap.value(
                        RawSettingsHandler::instance()->read(globalKey, globalMap.defaultValue.first),
                        globalMap.defaultValue.second)) {
                // If the new value matches the currently set global setting,
                // we remove the local setting. This makes sure that local settings
                // are updated as expected when global settings change. We assume
                // that users don't want to "set this setting locally to a fixed value",
                // but instead want to "enable" or "disable" a specific setting. For example:
                // hidden files are globally hidden; the user shows them explicitly
                // via the local settings. The user hides them again but sets the
                // global setting so they are shown. The user expects them now the
                // be shown in all directories. If we would simply save "hidden
                // files are hidden here", then the user would have to change the
                // local settings again, which is counterintuitive and annoying.
                RawSettingsHandler::instance()->remove(localKey, m_localFile);
            } else {
                RawSettingsHandler::instance()->write(localKey, localMap.key(newValue), m_localFile);
            }
        } else {
            RawSettingsHandler::instance()->write(globalKey, globalMap.key(newValue));
        }
    }

    template<typename T>
    T getValue(QString globalKey, QString localKey, Mapping<T> globalMap, Mapping<T> localMap) const {
        // Read local settings if they are enabled, a local key is available,
        // a local settings file is specified, and the key is defined in this file.
        // Otherwise read global settings.
        if (   !m_localFile.isEmpty()
            && !localKey.isEmpty()
            && RawSettingsHandler::instance()->read(QSL("View/UseLocalSettings"), QSL("true")) == QSL("true")
            && RawSettingsHandler::instance()->hasKey(localKey, m_localFile)) {
            return localMap.value(
                        RawSettingsHandler::instance()->read(localKey, QLatin1String(), m_localFile),
                        globalMap.defaultValue.second);
        } else {
            return globalMap.value(
                        RawSettingsHandler::instance()->read(globalKey, globalMap.defaultValue.first),
                        globalMap.defaultValue.second);
        }
    }
};

#undef QSL
#undef PROP
#endif // SETTINGS_H
