/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
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

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.Settings 1.0
import Opal.About 1.0 as A
import Opal.SupportMe 1.0 as M

import "pages"
import "js/navigation.js" as Navigation

ApplicationWindow {
    id: main
    allowedOrientations: Orientation.All

    // We have to explicitly set the \c _defaultPageOrientations property
    // to \c Orientation.All so the page stack's default placeholder page
    // will be allowed to be in landscape mode. (The default value is
    // \c Orientation.Portrait.) Without this setting, pushing multiple pages
    // to the stack using \c animatorPush() while in landscape mode will cause
    // the view to rotate back and forth between orientations.
    // [as of 2021-02-17, SFOS 3.4.0.24, sailfishsilica-qt5 version 1.1.110.3-1.33.3.jolla]
    _defaultPageOrientations: Orientation.All

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

    property string coverText: "File Browser"
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    initialPage: GlobalSettings.runningAsRoot ? initialPage_RootMode : initialPage_UserMode

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

    function _doStartup() {
        console.log("[startup] pushing initial stack")
        Navigation.goToFolder(GlobalSettings.initialDirectory, true); // silent
        _startupDone = true
    }

    property bool _startupDone: false
    property bool _initialPageReady: false
    property bool _delayStackInit: false
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

    Rectangle {
        id: solidBackground
        anchors.fill: parent
        visible: opacity > 0.0
        z: -10000
        color: Theme.colorScheme === Theme.LightOnDark ?
                   Theme.highlightDimmerColor :
                   Theme.overlayBackgroundColor
        opacity: GlobalSettings.generalSolidWindowBackground ? 1.0 : 0.0
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

    Component.onCompleted: {
        console.log("running File Browser: version %1 (%2)".arg(
                        APP_VERSION+"-"+APP_RELEASE).arg(RELEASE_TYPE))
        console.log("info: " + BUILD_MESSAGE)
        console.log("enabled features: sharing = %1 (%2), PDF viewer = %3, storage settings = %4".arg(
            GlobalSettings.sharingEnabled).arg(GlobalSettings.sharingMethod).arg(
            GlobalSettings.pdfViewerEnabled).arg(GlobalSettings.systemSettingsEnabled))

        if (GlobalSettings.runningAsRoot) {
            console.log("warning: running as root")
        }
    }
}
