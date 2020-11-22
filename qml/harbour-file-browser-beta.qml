/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
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

import "pages"
import "js/navigation.js" as Navigation
import "js/bookmarks.js" as Bookmarks

ApplicationWindow {
    id: main
    signal bookmarkAdded(var path)
    signal bookmarkRemoved(var path)
    signal bookmarkMoved(var path)

    // note: version number has to be updated only in harbour-file-browser.yaml!
    readonly property string versionString: qsTr("Version %1").arg(APP_VERSION+"-"+APP_RELEASE)
    readonly property bool runningAsRoot: engine.runningAsRoot()
    readonly property string sourceCodeLink: 'https://github.com/ichthyosaurus/harbour-file-browser'

    // Proxy functions for heavy libraries
    // The basic functions are proxied here. If more functions
    // are needed, the JS file should be loaded in the component.
    function navigate_goToFolder(folder) { return Navigation.goToFolder(folder); }
    function navigate_goBack() { return Navigation.goBack(); }
    function navigate_goForward() { return Navigation.goForward(); }
    function navigate_canGoBack() { return Navigation.canGoBack(); }
    function navigate_canGoForward() { return Navigation.canGoForward(); }
    function bookmarks_hasBookmark(path) { return Bookmarks.hasBookmark(path); }
    function bookmarks_addBookmark(path, name) { return Bookmarks.addBookmark(path, name); }
    function bookmarks_removeBookmark(path) { return Bookmarks.removeBookmark(path); }

    property string coverText: "File Browser"
    cover: Qt.resolvedUrl("cover/FileBrowserCover.qml")
    initialPage: Component {
        DirectoryPage {
            dir: "";

            property bool initial: true
            onStatusChanged: {
                if (status === PageStatus.Activating && initial) {
                    initial = false;
                    pageStack.completeAnimation();
                    Navigation.goToFolder(initialDirectory);
                }
            }
        }
    }
}
