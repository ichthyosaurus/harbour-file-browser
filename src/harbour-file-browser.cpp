/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2016 Kari Pihkala
 * SPDX-FileCopyrightText: 2014 jklingen
 * SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
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
#include "filemodel.h"
#include "filedata.h"
#include "searchengine.h"
#include "engine.h"
#include "consolemodel.h"
#include "settingshandler.h"
#include "texteditor.h"

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
    qmlRegisterType<FileModel>("harbour.file.browser.FileModel", 1, 0, "FileModel");
    qmlRegisterType<FileData>("harbour.file.browser.FileData", 1, 0, "FileData");
    qmlRegisterType<DirectorySettings>("harbour.file.browser.Settings", 1, 0, "DirectorySettings");
    qmlRegisterType<SearchEngine>("harbour.file.browser.SearchEngine", 1, 0, "SearchEngine");
    qmlRegisterType<ConsoleModel>("harbour.file.browser.ConsoleModel", 1, 0, "ConsoleModel");
    qmlRegisterType<TextEditor>("harbour.file.browser.TextEditor", 1, 0, "TextEditor");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName("harbour-file-browser"); // needed for Sailjail
    app->setApplicationName("harbour-file-browser");
    runMigrations();

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // setup global settings object
    QScopedPointer<RawSettingsHandler> settings(RawSettingsHandler::instance());
    QVariant settingsVariant = QVariant::fromValue(settings.data());
    qApp->setProperty("rawSettings", settingsVariant); // store as singleton
    view->rootContext()->setContextProperty("rawSettings", settings.data()); // expose to QML

    // setup global engine object
    QScopedPointer<Engine> engine(new Engine);
    QVariant engineVariant = QVariant::fromValue(engine.data());
    qApp->setProperty("engine", engineVariant); // store as singleton
    view->rootContext()->setContextProperty("engine", engine.data()); // expose to QML

    QString initialDirectory = QDir::homePath();
    if (argc >= 2) {
        QFileInfo info(QString::fromUtf8(argv[1]));

        if (info.exists() && info.isDir()) {
            initialDirectory = info.absoluteFilePath();
        }
    }

    view->rootContext()->setContextProperty("initialDirectory", initialDirectory);
    view->rootContext()->setContextProperty("APP_VERSION", QStringLiteral(APP_VERSION));
    view->rootContext()->setContextProperty("APP_RELEASE", QStringLiteral(APP_RELEASE));
    view->rootContext()->setContextProperty("RELEASE_TYPE", QStringLiteral(RELEASE_TYPE));

    // BEGIN FEATURE CONFIGURATION

    // Setting NO_HARBOUR_COMPLIANCE doesn't do much at the moment, as most
    // features are allowed in Harbour by now - or they are at least not explicitly
    // forbidden. By disabling features based on whether the required files exist, we
    // can make sure nothing breaks more unexpectedly than to be expected.
    //
    // Sailjail magic happens in the desktop file which is generated based on the
    // HARBOUR_COMPLIANCE flag in rpm/harbour-file-browser.yaml.

#ifdef NO_HARBOUR_COMPLIANCE
    view->rootContext()->setContextProperty("buildMessage", QVariant::fromValue(QStringLiteral("no explicit Harbour compliance")));
#else
    view->rootContext()->setContextProperty("buildMessage", QVariant::fromValue(QStringLiteral("forced Harbour compliance")));
#endif

    // Some features can be disabled individually, making it impossible to enable
    // them at runtime by modifying QML files. There is no reason to do that, though.
    //
    // Change these settings in rpm/harbour-file-browser.yaml.

#ifdef NO_FEATURE_PDF_VIEWER
    view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(false));
#else
    if (!engine->pdfViewerPath().isEmpty()) {
        // we enable PDF viewer integration only if sailfish-office is installed and accessible
        view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(true));
    } else {
        view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(false));
        qDebug() << "system documents viewer not available";
    }
#endif

#ifdef NO_FEATURE_STORAGE_SETTINGS
    view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(false));
#else
    if (!engine->storageSettingsPath().isEmpty()) {
        // we enable system (storage) settings only if the module is available
        view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(true));
    } else {
        view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(false));
        qDebug() << "system storage settings not available";
    }
#endif

#ifdef NO_FEATURE_SHARING
    view->rootContext()->setContextProperty("sharingEnabled", QVariant::fromValue(false));
    view->rootContext()->setContextProperty("sharingMethod", QVariant::fromValue(QStringLiteral("disabled")));
#else
    {
        QString method = QStringLiteral("disabled");

        if (QFileInfo::exists(
                    QStringLiteral("/usr/lib/") +
                    QStringLiteral("qt5/qml/Sailfish/Share/qmldir"))) {
            method = QStringLiteral("Share");
        } else if (QFileInfo::exists(
                       QStringLiteral("/usr/lib/") +
                       QStringLiteral("qt5/qml/Sailfish/TransferEngine/qmldir"))) {
            method = QStringLiteral("TransferEngine");
        }

        view->rootContext()->setContextProperty("sharingMethod", QVariant::fromValue(method));

        if (method == QStringLiteral("disabled")) {
            view->rootContext()->setContextProperty("sharingEnabled", QVariant::fromValue(false));
            qDebug() << "no supported sharing system found";
        } else {
            view->rootContext()->setContextProperty("sharingEnabled", QVariant::fromValue(true));
        }
    }
#endif

    // END FEATURE CONFIGURATION

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
