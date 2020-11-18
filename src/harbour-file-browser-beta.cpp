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
#include <QtQuick/QQuickPaintedItem>

#include "requires_defines.h"
#include "filemodel.h"
#include "filedata.h"
#include "searchengine.h"
#include "engine.h"
#include "consolemodel.h"
#include "settingshandler.h"

int main(int argc, char *argv[])
{
    // CONFIG += sailfishapp sets up QCoreApplication::OrganizationName and ApplicationName
    // so that QSettings can access the app's config file at
    // /home/USER/.config/harbour-file-browser/harbour-file-browser.conf

    qmlRegisterType<FileModel>("harbour.file.browser.FileModel", 1, 0, "FileModel");
    qmlRegisterType<FileData>("harbour.file.browser.FileData", 1, 0, "FileData");
    qmlRegisterType<SearchEngine>("harbour.file.browser.SearchEngine", 1, 0, "SearchEngine");
    qmlRegisterType<ConsoleModel>("harbour.file.browser.ConsoleModel", 1, 0, "ConsoleModel");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
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

#ifdef NO_HARBOUR_COMPLIANCE
    view->rootContext()->setContextProperty("sharingEnabled", QVariant::fromValue(true));
    view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(true));
    view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(true));
#else
    view->rootContext()->setContextProperty("sharingEnabled", QVariant::fromValue(false));
    view->rootContext()->setContextProperty("pdfViewerEnabled", QVariant::fromValue(false));
    view->rootContext()->setContextProperty("systemSettingsEnabled", QVariant::fromValue(false));
#endif

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
