/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2016 Kari Pihkala
 * SPDX-FileCopyrightText: 2014 jklingen
 * SPDX-FileCopyrightText: 2019-2024 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QScopedPointer>
#include <QQuickView>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlContext>
#include <QtGui/QGuiApplication>
#include <QTranslator>
#include <QStandardPaths>
#include <QtQuick/QQuickPaintedItem>

#include "requires_defines.h"
#include "enumcontainer.h"
#include "filemodel.h"
#include "filedata.h"
#include "searchengine.h"
#include "engine.h"
#include "consolemodel.h"
#include "settings.h"
#include "texteditor.h"
#include "fileoperations.h"
#include "fileclipboardmodel.h"

namespace {
    bool migrateItem(const QString& oldLocation, const QString& newLocation)
    {
        // Based on Migration.cpp from OSMScout for SFOS.
        // GPL-2.0-or-later, 2021  Lukáš Karas
        // https://github.com/Karry/osmscout-sailfish/blob/35c12584e7016fc3651b36ef7c2b6a0898fd4ce1/src/Migration.cpp

        qDebug() << "Considering migration" << oldLocation << "to" << newLocation;
        QFileInfo oldInfo(oldLocation);
        QFileInfo newInfo(newLocation);

        if (oldInfo.exists() && !newInfo.exists()) {
            QDir parent = newInfo.dir();

            if (!parent.mkpath(parent.absolutePath())) {
                qWarning() << "Failed to create path" << parent.absolutePath();
                return false;
            }

            if (!QFile::rename(oldLocation, newLocation)) {
                qWarning() << "Failed to move" << oldLocation << "to" << newLocation;
                return false;
            }

            qDebug() << "Migrated" << oldLocation << "to" << newLocation;
            return true;
        } else {
            qDebug() << "No migration required.";
        }

        if (newInfo.exists()) {
            return true;
        } else {
            return false;
        }
    }

    void runMigrations()
    {
        QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
        bool success = true;

        // migration for Sailjail (SFOS 4.3)
        QString oldConfigDir = home + "/.config/harbour-file-browser";
        QString newConfigDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);

        // vvv files
        QString configFile = QCoreApplication::applicationName() + ".conf";
        success = success && migrateItem(oldConfigDir + "/harbour-file-browser.conf", newConfigDir + "/" + configFile);
        // ^^^ files

        if (!success) {
            QString message = QStringLiteral(
                "Failed to migrate application data to new location.\n"
                "The application will now start normally but some data or configuration will be missing.\n"
                "Please close the app and move the files listed above manually.\n"
            );
            qWarning() << message;
        }
    }
}

int main(int argc, char *argv[])
{
    qRegisterMetaType<FileModelWorker::Mode>("FileModelWorker::Mode");
    qRegisterMetaType<StatFileInfo>("StatFileInfo");
    qRegisterMetaType<QList<StatFileInfo>>("QList<StatFileInfo>");
    qRegisterMetaType<LocationAlternative>("LocationAlternative");
    qRegisterMetaType<QList<LocationAlternative>>("QList<LocationAlternative>");
    qmlRegisterType<FileModel>("harbour.file.browser.FileModel", 1, 0, "FileModel");
    qmlRegisterType<FileData>("harbour.file.browser.FileData", 1, 0, "FileData");
    qmlRegisterType<SearchEngine>("harbour.file.browser.SearchEngine", 1, 0, "SearchEngine");
    qmlRegisterType<ConsoleModel>("harbour.file.browser.ConsoleModel", 1, 0, "ConsoleModel");
    qmlRegisterType<TextEditor>("harbour.file.browser.TextEditor", 1, 0, "TextEditor");

    REGISTER_ENUMS(SettingsHandler, "harbour.file.browser.Settings", 1, 0)
    qmlRegisterUncreatableType<BookmarkGroup>("harbour.file.browser.Settings", 1, 0, "BookmarkGroup", "This is only a container for an enumeration.");
    qmlRegisterUncreatableType<SharingMethod>("harbour.file.browser.Settings", 1, 0, "SharingMethod", "This is only a container for an enumeration.");
    qmlRegisterUncreatableType<InitialDirectoryMode>("harbour.file.browser.Settings", 1, 0, "InitialDirectoryMode", "This is only a container for an enumeration.");
    qmlRegisterUncreatableType<InitialPageMode>("harbour.file.browser.Settings", 1, 0, "InitialPageMode", "This is only a container for an enumeration.");

    qmlRegisterType<DirectorySettings>("harbour.file.browser.Settings", 1, 0, "DirectorySettings");
    qmlRegisterType<BookmarkWatcher>("harbour.file.browser.Settings", 1, 0, "Bookmark");
    qmlRegisterSingletonType<DirectorySettings>("harbour.file.browser.Settings", 1, 0, "GlobalSettings", [](QQmlEngine* engine, QJSEngine* scriptEngine) -> QObject* {
        Q_UNUSED(scriptEngine);
        return new DirectorySettings(true, engine->property("cliForcedInitialDirectory").toString());
    });
    qmlRegisterSingletonType<RawSettingsHandler>("harbour.file.browser.Settings", 1, 0, "RawSettings", [](QQmlEngine* engine, QJSEngine* scriptEngine) -> QObject* {
        Q_UNUSED(engine); Q_UNUSED(scriptEngine);
        return RawSettingsHandler::instance();
    });

    REGISTER_ENUMS(FileOperations, "harbour.file.browser.FileOperations", 1, 0)
    qmlRegisterUncreatableType<FileOpMode>("harbour.file.browser.FileOperations", 1, 0, "FileOpMode", "This is only a container for an enumeration.");
    qmlRegisterUncreatableType<FileOpErrorType>("harbour.file.browser.FileOperations", 1, 0, "FileOpErrorType", "This is only a container for an enumeration.");
    qmlRegisterUncreatableType<FileOpErrorAction>("harbour.file.browser.FileOperations", 1, 0, "FileOpErrorAction", "This is only a container for an enumeration.");
    qmlRegisterUncreatableType<FileOpStatus>("harbour.file.browser.FileOperations", 1, 0, "FileOpStatus", "This is only a container for an enumeration.");

    qmlRegisterSingletonType<FileOperationsModel>("harbour.file.browser.FileOperations", 1, 0, "FileOperations", [](QQmlEngine* engine, QJSEngine* scriptEngine) -> QObject* {
        Q_UNUSED(engine); Q_UNUSED(scriptEngine);
        return new FileOperationsModel();;
    });

    REGISTER_ENUMS(FileClipboard, "harbour.file.browser.FileClipboard", 1, 0)
    qmlRegisterUncreatableType<FileClipMode>("harbour.file.browser.FileClipboard", 1, 0, "FileClipMode", "This is only a container for an enumeration.");

    qmlRegisterSingletonType<FileClipboard>("harbour.file.browser.FileClipboard", 1, 0, "FileClipboard", [](QQmlEngine* engine, QJSEngine* scriptEngine) -> QObject* {
        Q_UNUSED(engine); Q_UNUSED(scriptEngine);
        return new FileClipboard();
    });

    // TODO replace "engine" context property by a singleton type
    // qmlRegisterSingletonType<Engine>("harbour.file.browser.Engine", 1, 0, "Engine", &Engine::qmlInstance);

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName("harbour-file-browser"); // needed for Sailjail
    app->setApplicationName("harbour-file-browser");
    runMigrations();

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    if (argc >= 2) {
        view->engine()->setProperty("cliForcedInitialDirectory", QString::fromUtf8(argv[1]));
        qDebug() << "initial directory set from command line:" << argv[1];
    } else {
        view->engine()->setProperty("cliForcedInitialDirectory", QLatin1Literal(""));
    }

    // setup global engine object
    // TODO use QML singleton instead
    QScopedPointer<Engine> engine(new Engine);
    view->rootContext()->setContextProperty("engine", engine.data()); // expose to QML

    // store a pointer to the engine to access it in any class
    // as singleton on the C++ side
    QVariant engineVariant = QVariant::fromValue(engine.data());
    qApp->setProperty("engine", engineVariant);

    // add module search path so Opal modules can be found
    view->engine()->addImportPath(SailfishApp::pathTo("qml/modules").toString());

    view->rootContext()->setContextProperty("APP_VERSION", QStringLiteral(APP_VERSION));
    view->rootContext()->setContextProperty("APP_RELEASE", QStringLiteral(APP_RELEASE));
    view->rootContext()->setContextProperty("RELEASE_TYPE", QStringLiteral(RELEASE_TYPE));

    // Setting NO_HARBOUR_COMPLIANCE doesn't do much at the moment, as most
    // features are allowed in Harbour by now - or they are at least not explicitly
    // forbidden. By disabling features based on whether the required files exist, we
    // can make sure nothing breaks more unexpectedly than to be expected.
    //
    // Sailjail magic happens in the desktop file which is generated based on the
    // HARBOUR_COMPLIANCE flag in rpm/harbour-file-browser.yaml.
    //
    // Some features can be disabled individually, making it impossible to enable
    // them at runtime by modifying QML files. If the capabilities they rely on
    // are not available (e.g. QML modules are not installed), then they will be
    // disabled dynamically anyways.
    //
    // Change these settings in rpm/harbour-file-browser.yaml.

#ifdef NO_HARBOUR_COMPLIANCE
    view->rootContext()->setContextProperty("BUILD_MESSAGE", QVariant::fromValue(QStringLiteral("no explicit Harbour compliance")));
    view->rootContext()->setContextProperty("HAVE_SAILJAIL", QVariant::fromValue(false));
#else
    view->rootContext()->setContextProperty("BUILD_MESSAGE", QVariant::fromValue(QStringLiteral("forced Harbour compliance")));
    view->rootContext()->setContextProperty("HAVE_SAILJAIL", QVariant::fromValue(true));
#endif

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
