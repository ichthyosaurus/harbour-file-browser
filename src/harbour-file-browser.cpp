/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014, 2016 Kari Pihkala
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
#include <QQmlEngine>
#include <QGuiApplication>
#include <QTranslator>
#include <QQmlContext>
#include <QStandardPaths>
#include <QtQuick/QQuickPaintedItem>

#include "requires_defines.h"
#include "filemodel.h"
#include "filedata.h"
#include "searchengine.h"
#include "engine.h"
#include "consolemodel.h"
#include "settingshandler.h"

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
        }

        return false;
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
    qmlRegisterType<SearchEngine>("harbour.file.browser.SearchEngine", 1, 0, "SearchEngine");
    qmlRegisterType<ConsoleModel>("harbour.file.browser.ConsoleModel", 1, 0, "ConsoleModel");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName("harbour-file-browser"); // needed for Sailjail
    app->setApplicationName("harbour-file-browser");
    runMigrations();

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // setup global settings object
    QScopedPointer<Settings> settings(new Settings);
    QVariant settingsVariant = qVariantFromValue(settings.data());
    qApp->setProperty("settings", settingsVariant); // store as singleton
    view->rootContext()->setContextProperty("settings", settings.data()); // expose to QML

    // setup global engine object
    QScopedPointer<Engine> engine(new Engine);
    QVariant engineVariant = qVariantFromValue(engine.data());
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
    view->rootContext()->setContextProperty("APP_VERSION", QString(APP_VERSION));
    view->rootContext()->setContextProperty("APP_RELEASE", QString(APP_RELEASE));
    view->rootContext()->setContextProperty("RELEASE_TYPE", QString(RELEASE_TYPE));

#ifdef NO_HARBOUR_COMPLIANCE
    view->rootContext()->setContextProperty("buildMessage", QVariant::fromValue(QStringLiteral("no explicit Harbour compliance")));

    {
        QString method = QStringLiteral("disabled");

        if (QFileInfo(QStringLiteral("/usr/lib/") +
                      QStringLiteral("qt5/qml/Sailfish/Share/qmldir")).exists()) {
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

    if (!engine->pdfViewerPath().isEmpty()) {
        // we enable PDF viewer integration only if sailfish-office is installed and accessible
        view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(true));
    } else {
        view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(false));
        qDebug() << "system documents viewer not available";
    }

    if (!engine->storageSettingsPath().isEmpty()) {
        // we enable system (storage) settings only if the module is available
        view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(true));
    } else {
        view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(false));
        qDebug() << "system storage settings not available";
    }
#else
    view->rootContext()->setContextProperty("buildMessage", QVariant::fromValue(QStringLiteral("forced Harbour compliance")));
    view->rootContext()->setContextProperty("sharingEnabled", QVariant::fromValue(false));
    view->rootContext()->setContextProperty("sharingMethod", QVariant::fromValue(QStringLiteral("disabled")));
    view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(false));
    view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(false));
#endif

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
