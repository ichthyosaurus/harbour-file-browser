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

#ifndef SETTINGSHANDLER_H
#define SETTINGSHANDLER_H

#include <QVariant>
#include <QMap>
#include <QHash>
#include <QPair>
#include <QString>
#include <QMutex>
#include <QSharedPointer>
#include <QDir>

class QFileInfo;


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

    QVariant readVariant(QString key, const QVariant& defaultValue = QVariant(), QString fileName = QString());
    void writeVariant(QString key, const QVariant& value, QString fileName = QString());
    bool hasKey(QString key, QString fileName = QString());

    static RawSettingsHandler* instance() {
        if (m_globalInstance.isNull()) m_globalInstance.reset(new RawSettingsHandler());
        return m_globalInstance.data();
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
    QMutex m_mutex;

    static QSharedPointer<RawSettingsHandler> m_globalInstance;
};


// Settings specific to File Browser.
// The following classes implement settings that are canonicalized and documented.
// These values are available as read-write properties and support signals.
//
// Prefer this class over reading and writing raw key-value pairs.

#define QSL QStringLiteral
#include <QDebug>

class DirectorySettings : public QObject {
    Q_OBJECT

private:
    template<typename T>
    class Mapping : public QHash<QString, T> {
    public:
        Mapping(QString defaultValue, QStringList passthroughValues)
            : defaultValue({defaultValue, defaultValue}) {
            this->insert(defaultValue, defaultValue);
            for (auto& i : passthroughValues) this->insert(i, i);
        }
        Mapping(QPair<QString, T> defaultValue, QHash<QString, T> pairs)
            : QHash<QString, T>(pairs), defaultValue(defaultValue) {
            this->insert(defaultValue.first, defaultValue.second);
        }

        template<typename U = T>
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
            qDebug() << "[local setting changed]" << key << locally << localPath << m_localFile << #NAME; \
            emit NAME##Changed(); \
        } else if (!locally && key == QSL(GLOBAL_KEY)) { \
            qDebug() << "[global settings changed]" << key << locally << localPath << m_localFile << #NAME; \
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
    Mapping<QString> map_initialDirMode{QSL("home"), {QSL("last"), QSL("custom")}};
    PROP(QString, generalInitialDirectoryMode, "General/InitialDirectoryMode", "", map_initialDirMode, map_invalid)
    Mapping<QString> map_initialDirPath{QDir::homePath(), true};
    PROP(QString, generalCustomInitialDirectoryPath, "General/CustomInitialDirectoryPath", "", map_initialDirPath, map_invalid);
    PROP(QString, generalLastDirectoryPath, "General/LastDirectoryPath", "", map_initialDirPath, map_invalid);

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
    PROP(bool, viewHiddenFilesShown, "View/HiddenFilesShown", "Settings/HiddenFilesShown", map_bool_false, map_bool_false)
    PROP(bool, viewPreviewsShown, "View/PreviewsShown", "Dolphin/PreviewsShown", map_bool_false, map_bool_false)
    Mapping<QString> map_previewSize{QSL("medium"), {QSL("small"), QSL("large"), QSL("huge")}};
    PROP(QString, viewPreviewsSize, "View/PreviewsSize", "", map_previewSize, map_invalid);
    PROP(bool, viewUseLocalSettings, "View/UseLocalSettings", "", map_bool_true, map_bool_true)
    Mapping<QString> map_viewMode{QSL("list"), {QSL("gallery"), QSL("grid")}};
    PROP(QString, viewViewMode, "View/ViewMode", "Sailfish/ViewMode", map_viewMode, map_viewMode);

    // [Bookmarks] section
    // TODO

    //
    // ^^^ SETTINGS ^^^
    //

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    public: Q_SIGNAL void pathChanged(QString newValue);
    public: Q_SLOT void setPath(QString newValue) { m_path = newValue; m_localFile = m_path + QSL("/.directory"); emit pathChanged(newValue); }
    public: QString path() const { return m_path; }

public:
    // Specify a path to handle local settings. Leave the path empty to handle global settings only.
    explicit DirectorySettings(QObject* parent = nullptr);
    explicit DirectorySettings(QString path, QObject* parent = nullptr);
    ~DirectorySettings();

private:
    QString m_path;
    QString m_localFile;

    template<typename T>
    void setValue(QString globalKey, QString localKey, Mapping<T> globalMap, Mapping<T> localMap, T newValue) {
        // Write local settings if they are enabled, a local key is available, and
        // a local settings file is specified. Otherwise write global settings.
        if (   !m_localFile.isEmpty()
            && !localKey.isEmpty()
            && RawSettingsHandler::instance()->read(QSL("View/UseLocalSettings"), QSL("true")) == QSL("true")) {
            if (newValue == globalMap.value(RawSettingsHandler::instance()->read(globalKey, globalMap.defaultValue.first), globalMap.defaultValue.second)) {
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
            return localMap.value(RawSettingsHandler::instance()->read(localKey, QLatin1String(), m_localFile), globalMap.defaultValue.second);
        } else {
            return globalMap.value(RawSettingsHandler::instance()->read(globalKey, globalMap.defaultValue.first), globalMap.defaultValue.second);
        }
    }
};

#undef QSL
#undef PROP
#endif // SETTINGSHANDLER_H
