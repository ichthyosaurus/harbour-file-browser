/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2016, 2018 Kari Pihkala
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

CoverBackground {
    anchors.fill: parent

    Image {
        id: bgIcon
        y: Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0.4
        width: Theme.iconSizeLarge
        height: width
        source: runningAsRoot ? "../images/harbour-file-browser-root.png"
                              : "../images/harbour-file-browser.png"
    }

    Label {
        visible: runningAsRoot
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
        enabled: !runningAsRoot || authenticatedForRoot

        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: {
                var current = pageStack.currentPage;

                if (current && current.currentDirectory && current.dir) {
                    // we assume it's already the search page
                    main.activate();
                    return;
                }

                var path = StandardPaths.home;
                var next = pageStack.nextPage();

                if (current && (current.dir || current.currentPath)) {
                    path = current.dir ? current.dir : current.currentPath;
                } else if (next && next.currentPath) {
                    path = next.currentPath;
                }

                pageStack.push(Qt.resolvedUrl("../pages/SearchPage.qml"),
                               { dir: path }, PageStackAction.Immediate);
                main.activate();
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-favorite"
            onTriggered: {
                var current = pageStack.currentPage;
                var next = pageStack.nextPage();

                if (current && current.currentPath) {
                    main.activate();
                    return;
                } else if (next && next.currentPath) {
                    pageStack.navigateForward(PageStackAction.Immediate);
                } else {
                    pageStack.push(Qt.resolvedUrl("../pages/ShortcutsPage.qml"),
                                   { currentPath: StandardPaths.home },
                                   PageStackAction.Immediate);
                }

                main.activate();
            }
        }
    }
}
