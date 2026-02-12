/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2019-2026 Mirian Margiani
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

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.Settings 1.0
import Opal.About 1.0 as A
import Opal.SupportMe 1.0 as M

import "pages"
import "js/navigation.js" as Navigation

ApplicationWindow {
    id: main

    /*
     * Some general configuration
     *
     */

    property string coverText: "File Browser"
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    // We have to explicitly set the \c _defaultPageOrientations property
    // to \c Orientation.All so the page stack's default placeholder page
    // will be allowed to be in landscape mode. (The default value is
    // \c Orientation.Portrait.) Without this setting, pushing multiple pages
    // to the stack using \c animatorPush() while in landscape mode will cause
    // the view to rotate back and forth between orientations.
    // [as of 2021-02-17, SFOS 3.4.0.24, sailfishsilica-qt5 version 1.1.110.3-1.33.3.jolla]
    _defaultPageOrientations: Orientation.All
    allowedOrientations: Orientation.All


    /*
     * App startup and initial page
     *
     */

    initialPage: GlobalSettings.runningAsRoot ? initialPage_RootMode : initialPage_UserMode

    function _doStartup() {
        console.log("[startup] pushing initial stack (%1)"
                    .arg(GlobalSettings.generalInitialPageMode))
        Navigation.goToFolder(GlobalSettings.initialDirectory, /*silent*/ true,
            GlobalSettings.generalInitialPageMode === InitialPageMode.Search ? "" : undefined,
            GlobalSettings.generalInitialPageMode === InitialPageMode.Shortcuts)
        _startupDone = true
        console.log("[startup] startup is done")
    }

    property bool _startupDone: false
    property bool _delayStackInit: false

    property bool _initialPageReady: false
    on_InitialPageReadyChanged: {
        if (!_initialPageReady) return

        if (pageStack.busy) {
            console.warn("[startup] page stack is busy, delaying initialization")
            console.warn("[startup] this stage should never be reached, please file a bug report")
            _delayStackInit = true
        } else {
            _doStartup()
        }
    }

    // Enable this if there are reports that startup failed because the page
    // stack was busy. The code is disabled as it would be run on every page
    // change, which may have a negative impact on performance.
    /* pageStack.onBusyChanged: {
        if (!_startupDone && _delayStackInit && !pageStack.busy) {
            console.warn("[startup] delayed initialization started")
            _delayStackInit = false
            _doStartup()
        }
    } */

    Component {
        id: initialPage_RootMode

        Page {
            id: page
            allowedOrientations: Orientation.All

            Loader {
                id: rootLockLoader
                anchors.fill: parent
                source: GlobalSettings.runningAsRoot ? Qt.resolvedUrl('pages/RootModeLockPage.qml') : ''
            }

            Connections {
                target: GlobalSettings.runningAsRoot ? rootLockLoader.item : null
                onAuthenticated: {
                    console.warn("[startup] root mode authenticated")
                    _initialPageReady = true  // to continue with startup
                    GlobalSettings.authenticatedForRoot = true
                }
            }
        }
    }

    Component {
        id: initialPage_UserMode

        Page {
            // We start with an empty placeholder page that will be replaced
            // by the actual array of pages for the directory in \c GlobalSettings.initialDirectory.
            // (\c Navigation.goToFolder() will replace the whole page stack if
            // the first page is not DirectoryPage { dir: '/' }.)
            // Starting with a DirectoryPage will make the page stack go crazy in horizontal
            // mode when the app is started in *portrait* mode and turned later.
            onStatusChanged: {
                if (status === PageStatus.Activating) {
                    console.log("[startup] initial page is activating")
                    // Setting this property will start the next step. This has to be
                    // delayed in case the page stack is still in \c busy state when
                    // the page is in \c Activating state (not yet \c Active).
                    _initialPageReady = true
                }
            }
        }
    }


    /*
     * File actions and notifications handling
     *
     */

    // TODO


    /*
     * Navigation handling
     *
     */

    // Navigation history: see navigation.js for details
    property var backStack: ([])
    property var forwardStack: ([])
    property var currentPage: ({type: "dir", path: GlobalSettings.initialDirectory})
    property var activePage: ({type: "dir", path: GlobalSettings.initialDirectory})
    onCurrentPageChanged: GlobalSettings.generalLastDirectoryPath = currentPage.path

    // Proxy functions for heavy libraries
    // The basic functions are proxied here. If more functions
    // are needed, the JS file should be loaded in the component.
    function navigate_goToFolder(folder) { return Navigation.goToFolder(folder); }
    function navigate_goBack() { return Navigation.goBack(); }
    function navigate_goForward() { return Navigation.goForward(); }
    function navigate_canGoBack() { return Navigation.canGoBack(); }
    function navigate_canGoForward() { return Navigation.canGoForward(); }
    function navigate_syncNavStack() { return Navigation.syncNavStack(); }

    function finishNavigationLater(target) {
        console.log("[navigation] app state:", Qt.application.state,
                    "expecting", Qt.ApplicationActive, "for", target.properties.dir)

        if (pageStack.busy) {
            navigationFinisher.targetPath = target.page
            navigationFinisher.targetProperties = target.properties
        }
    }

    Connections {
        id: navigationFinisher
        property string targetPath
        property var targetProperties: ({})

        target: !!targetPath ? pageStack : null

        onBusyChanged: {
            // When navigation occurs while the app is in the background,
            // the last page will not be pushed correctly and the stack gets
            // stuck showing only a fullscreen busy spinner while "busy" is "false".
            // To work around this issue, we wait for changes to "busy" and
            // verify that the top page has an "objectName". If it doesn't,
            // we replace the top page with the expected target page.
            // Only when navigation reaches a seemingly valid page, we reset
            // the watcher.
            //
            // This workaround fixes the issue where the app would only show
            // a busy spinner after startup. It also fixes the issue
            // where the app starts properly but the attached shortcuts page
            // is blank. It does not fix the issue where attached pages
            // sometimes become blank during navigation.
            //
            // Important: current valid navigation targets are DirectoryPage and
            // SearchPage, both of which have an "objectName".

            if (!pageStack.busy) {
                if (!pageStack.currentPage.objectName) {
                    console.log("[navigation] issue detected, replacing", pageStack.currentPage,
                                "with", targetProperties.dir)
                    pageStack.replace(targetPath, targetProperties)
                } else {
                    console.log("[navigation] navigation ended successfully with",
                                pageStack.currentPage.objectName)
                    targetPath = ''
                    targetProperties = {}
                }
            } else {
                console.log("[navigation] page stack is still busy, waiting...")
            }
        }
    }


    /*
     * Shared attached pages handling
     *
     */

    Connections {
        id: attachedWatcher
        target: pageStack

        // Attached pages sometimes become blank (visible == false)
        // during navigation. This is fixed by pushing them again
        // to the stack, however calling replace() is not sufficient.
        // Setting "visible" to "true" is also not enough.
        //
        // This only happens if the same object is used as attached
        // page multiple times. We still use shared attached page
        // objects because it is much faster than creating the
        // attached page chain for each directory page separately.
        //
        // The workaround is to simply pop the current attached page
        // from the stack and then let the AttachedPageManager
        // of the current page handle pushing it again.
        // It is a bit annoying having to swipe a second time if the
        // page pops suddenly, but that is less annoying than having
        // to navigate to a different folder before being able to use
        // the shortcuts page again, for example.
        //
        // This workaround cannot be implemented in the AttachedPageManager
        // component because it becomes inactive once its parent page
        // is no longer the top page on the stack. It must be global.

        onBusyChanged: {
            if (!pageStack.busy &&
                    !navigationFinisher.targetPath &&
                    !!pageStack.currentPage &&
                    !pageStack.currentPage.visible) {
                var currentPage = pageStack.currentPage
                console.warn("[navigation] issue detected: " +
                             "active page is invisible", currentPage)

                if (currentPage == shortcutsPage ||
                        currentPage == aboutPage ||
                        currentPage == settingsPage) {
                    pageStack.popAttached()
                    console.log("[navigation] workaround for known invisible page applied")
                } else {
                    console.error("[navigation] invisible page is unknown " +
                                  "and cannot be fixed automatically")
                }
            }
        }
    }

    property ShortcutsPage shortcutsPage: null
    Loader {
        id: shortcutsPageLoader
        asynchronous: false
        onStatusChanged: {
            if (status === Loader.Ready) shortcutsPage = shortcutsPageLoader.item
            console.log("[shortcuts loader] status:", status, shortcutsPage)
        }
        sourceComponent: Component {
            ShortcutsPage {
                currentPath: StandardPaths.home
            }
        }
    }

    property GlobalSettingsPage settingsPage: null
    Loader {
        id: settingsPageLoader
        asynchronous: true
        onStatusChanged: if (status === Loader.Ready) settingsPage = settingsPageLoader.item
        sourceComponent: Component {
            GlobalSettingsPage { }
        }
    }

    property AboutPage aboutPage: null
    Loader {
        id: aboutPageLoader
        asynchronous: true
        onStatusChanged: if (status === Loader.Ready) aboutPage = aboutPageLoader.item
        sourceComponent: Component {
            AboutPage { }
        }
    }


    /*
     * Popups and app background
     *
     */

    Rectangle {
        id: solidBackground
        anchors.fill: parent
        visible: opacity > 0.0
        z: -10000
        color: Theme.colorScheme === Theme.LightOnDark ?
                   (GlobalSettings.generalBlackBackground ? "black" : Theme.highlightDimmerColor) :
                   Theme.overlayBackgroundColor
        opacity: GlobalSettings.generalSolidWindowBackground || GlobalSettings.generalBlackBackground ?
                    1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 100 } }
    }

    A.ChangelogNews {
        changelogList: Qt.resolvedUrl("Changelog.qml")
    }

    M.AskForSupport {
        contents: Component {
            MySupportDialog {}
        }
    }

    M.AskForSupport {
        objectName: "sailjail-popup"
        enabled: GlobalSettings.runningInSailjail
        showOnInitialStart: true
        customConfigPath: "/apps/harbour-file-browser/sailjail-popup"
        interval: 1
        longInterval: 50

        contents: Component {
            SailjailInfoDialog {}
        }
    }


    /*
     * On completed
     *
     */

    Component.onCompleted: {
        console.log("running File Browser: version %1 (%2)".arg(
                        APP_VERSION+"-"+APP_RELEASE).arg(RELEASE_TYPE))
        console.log("info: " + BUILD_MESSAGE)
        console.log("enabled features: sailjail = %5, sharing = %1 (%2), PDF viewer = %3, storage settings = %4".arg(
            GlobalSettings.sharingEnabled).arg(GlobalSettings.sharingMethod).arg(
            GlobalSettings.pdfViewerEnabled).arg(GlobalSettings.systemSettingsEnabled).arg(
            GlobalSettings.runningInSailjail))

        if (GlobalSettings.runningAsRoot) {
            console.log("warning: running as root")
        }
    }
}
