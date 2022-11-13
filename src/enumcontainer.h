/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef ENUMCONTAINER_H
#define ENUMCONTAINER_H

#include <QtQml>

// Use the following macros to expose an enumeration to QML.
//
// Usage:
//
// 0. Include "enumcontainer.h" in the header file.
//
// 1. Declare a new enum using the CREATE_ENUM macro in the header file.
//      CREATE_ENUM(Bookmark, Group, Temporary, External, Bookmark)
//
// 2. Declare a new registration function (only once) in the header file.
//      DECLARE_ENUM_REGISTRATION_FUNCTION(SettingsHandler)
//
// 3. Define the registration function in the code file.
//      DEFINE_ENUM_REGISTRATION_FUNCTION(SettingsHandler) {
//          REGISTER_ENUM_CONTAINER(Bookmark, Group)
//      }
//
// 4. Actually do the registration in the main() function.
//      REGISTER_ENUMS(SettingsHandler, "harbour.file.browser.Settings", 1, 0)
//
// 5. Workaround: duplicate the registration in the main() function so the
//    enums get picked up by QtCreator's completion system
//      qmlRegisterUncreatableType<BookmarkGroup>("harbour.file.browser.Settings", 1, 0, "BookmarkGroup", "This is only a container for an enumeration.");

#define CREATE_ENUM(BASE, NAME, VALUES...) \
    class BASE##NAME { \
        Q_GADGET \
    \
    public: \
        enum NAME { VALUES }; \
        \
        Q_ENUM(NAME) /* using "BASE##NAME::NAME" would make it "undefined" in QML */ \
        \
        static void registerToQml(const char* url, int major, int minor) { \
            static const char* qmlName = #BASE#NAME; \
            qmlRegisterUncreatableType<BASE##NAME>(url, major, minor, qmlName, "This is only a container for an enumeration."); \
        } \
    };

#define DECLARE_ENUM_REGISTRATION_FUNCTION(NAMESPACE) \
    namespace NAMESPACE##Enums { void registerEnumTypes(const char* qmlUrl, int major, int minor); }

#define DEFINE_ENUM_REGISTRATION_FUNCTION(NAMESPACE) \
    void NAMESPACE##Enums::registerEnumTypes(const char *qmlUrl, int major, int minor)

#define REGISTER_ENUM_CONTAINER(BASE, NAME) \
    qRegisterMetaType<BASE##NAME::NAME>(#BASE#NAME "::" #NAME); \
    BASE##NAME::registerToQml(qmlUrl, major, minor);

#define REGISTER_ENUMS(NAMESPACE, URI, MAJOR, MINOR) \
    NAMESPACE##Enums::registerEnumTypes(URI, MAJOR, MINOR);

#endif // ENUMCONTAINER_H
