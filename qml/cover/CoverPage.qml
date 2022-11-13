/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2016-2018 Kari Pihkala
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

CoverBackground {
    anchors.fill: parent

    // Drop all pages above the last directory page and push another
    // page instead, then activate the app.
    //
    // newPage: new page to push on the stack, can be a URL or anything accepted by pageStack.push
    // pathKey: property name using which the current directory will be passed to the new page
    // stayAtPage: object name of a page that will be activated if it is found (instead of pushing)
    //
    // If any page has a property called __critical_process_page, then nothing will
    // be pushed and the app will be activated. This can be used to avoid accidentally
    // closing an important dialog.
    function activatePage(newPage, pathKey, stayAtPage) {
        var checkPage = pageStack.currentPage

        console.log("page A:", pageStack.currentPage.objectName)

        do {
            if (!!stayAtPage && checkPage.objectName === stayAtPage) {
                console.log("staying at", stayAtPage, checkPage.objectName, pageStack.currentPage.objectName)
                main.activate()
                return
            } else if (checkPage.hasOwnProperty('__critical_process_page')) {
                console.log("critical")
                main.activate()
                return
            } else if (checkPage.objectName === 'DirectoryPage') {
                console.log("found dir", checkPage.dir)
                break
            } else {
                checkPage = pageStack.previousPage(checkPage)
            }
        } while (checkPage !== null)

        if (checkPage === null) {
            console.log("is null")
            // this should never happen as the root page should always be
            // the root directory page
            main.activate()
            return
        }

        var props = {}
        props[pathKey] = checkPage.dir

        console.log("page B:", pageStack.currentPage.objectName)
        if (checkPage === pageStack.currentPage) {
            console.log("pushing")
            pageStack.animatorPush(newPage, props, PageStackAction.Immediate)
        } else {
            console.log("replacing")
            pageStack.replaceAbove(checkPage, newPage, props, PageStackAction.Immediate)
        }

        main.activate()
    }

    Image {
        id: bgIcon
        y: Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0.4
        width: Theme.iconSizeLarge
        height: width
        source: GlobalSettings.runningAsRoot ?
                    "../images/harbour-file-browser-root.png" :
                    "../images/harbour-file-browser.png"
    }

    Label {
        visible: GlobalSettings.runningAsRoot
        anchors.centerIn: bgIcon
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        textFormat: Text.RichText
        text: "<b>" + qsTr("Root Mode") + "</b>"
        color: Theme.highlightColor
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - (Screen.sizeCategory > Screen.Medium
                                   ? 2*Theme.paddingMedium : 2*Theme.paddingLarge)
        height: width
        color: Theme.secondaryColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        fontSizeMode: Text.Fit
        text: main.coverText
    }

    CoverActionList {
        enabled: !GlobalSettings.runningAsRoot || GlobalSettings.authenticatedForRoot

        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: activatePage(Qt.resolvedUrl("../pages/SearchPage.qml"), 'dir', 'SearchPage')
        }
        CoverAction {
            iconSource: "image://theme/icon-cover-favorite"
            // Note: the "current page" stays the same on the page stack when an attached
            // page is being shown. That means we cannot stay when 'ShortcutsPage' is the
            // current page. Instead, we have to push a new instance of the shortcuts page
            // that will be destroyed once the user navigates back. We cannot use main.shortcutsPage
            // either, because that would mean pushing the same page twice onto the stack
            // when it is actually being shown currently.
            onTriggered: activatePage(Qt.resolvedUrl("../pages/ShortcutsPage.qml"), 'currentPath', null)
        }
    }
}
