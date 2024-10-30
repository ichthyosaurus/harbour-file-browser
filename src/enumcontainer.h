/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef ENUMCONTAINER_H
#define ENUMCONTAINER_H

#include <QtQml/QtQml>
#include <QObject>

// Use the following macros to expose an enumeration to QML.
//
// Usage:
//
// 0. Include "enumcontainer.h" in the header file.
//
// 1. Declare a new enum using the CREATE_ENUM macro in the header file.
//      CREATE_ENUM(MyEnum, Value1, Value2, Value3)
//
// 2. Declare a new registration function (only once) in the header file.
//      DECLARE_ENUM_REGISTRATION_FUNCTION(MyNamespace)
//
// 3. Define the registration function in the code file.
//      DEFINE_ENUM_REGISTRATION_FUNCTION(MyNamespace) {
//          REGISTER_ENUM_CONTAINER(MyEnum)
//      }
//
// 4. Actually do the registration in the main() function.
//      REGISTER_ENUMS(MyNamespace, "MyApp.MyModule", 1, 0)
//
// 5. Workaround: duplicate the registration in the main() function so the
//    enums get picked up by QtCreator's completion system
//      qmlRegisterUncreatableType<MyEnum>("MyApp.MyModule", 1, 0, "MyEnum", "This is only a container for an enumeration.");
//
// 6. Workaround: if your header file does not contain the Q_OBJECT macro,
//    then qmake will not run "moc" on it and the project will not compile.
//    Add this to the header file as a workaround:
//      #ifdef __HACK_TO_FORCE_MOC
//      Q_OBJECT
//      #endif
//

#define CREATE_ENUM(NAME, VALUES...) \
    class NAME : public QObject { \
        Q_OBJECT \
        Q_DISABLE_COPY(NAME) \
        \
        NAME() {}\
    \
    public: \
        enum Enum { VALUES }; \
        \
        Q_ENUM(Enum) /* using "NAME::Enum" here would make it "undefined" in QML */ \
        \
        static void registerToQml(const char* url, int major, int minor) { \
            static const char* qmlName = #NAME; \
            qmlRegisterSingletonType<NAME>(url, major, minor, qmlName, &NAME::qmlInstance); \
        } \
        \
        Q_INVOKABLE static bool isValid(int value) { \
            return QMetaEnum::fromType<Enum>().valueToKey(value) != 0; \
        } \
        \
        Q_INVOKABLE static QString string(int value) { \
            return QString::fromLatin1(QMetaEnum::fromType<Enum>().valueToKey(value)); \
        } \
        \
        static QObject* qmlInstance(QQmlEngine* engine, QJSEngine* scriptEngine) { \
            Q_UNUSED(engine); \
            Q_UNUSED(scriptEngine); \
            return new NAME; \
        } \
    }; \

#define DECLARE_ENUM_REGISTRATION_FUNCTION(NAMESPACE) \
    namespace NAMESPACE##Enums { void registerEnumTypes(const char* qmlUrl, int major, int minor); }

#define DEFINE_ENUM_REGISTRATION_FUNCTION(NAMESPACE) \
    void NAMESPACE##Enums::registerEnumTypes(const char *qmlUrl, int major, int minor)

#define REGISTER_ENUM_CONTAINER(NAME) \
    qRegisterMetaType<NAME::Enum>(#NAME "::Enum"); \
    qRegisterMetaType<QList<NAME::Enum>>("QList<" #NAME "::Enum>"); \
    NAME::registerToQml(qmlUrl, major, minor);

#define REGISTER_ENUMS(NAMESPACE, URI, MAJOR, MINOR) \
    NAMESPACE##Enums::registerEnumTypes(URI, MAJOR, MINOR);

#endif // ENUMCONTAINER_H
