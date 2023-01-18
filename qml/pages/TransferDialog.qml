/*
 * This file is part of File Browser.
 *
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.Settings 1.0
import "../js/paths.js" as Paths

import "../components"

Dialog {
    id: dialog
    property var toTransfer: []
    property var targets: []
    property string selectedAction: ""
    property bool goToTarget: false
    property string errorMessage: ""

    allowedOrientations: Orientation.All
    canAccept: selectedAction !== "" && shortcutsView.selectedLocations.length > 0

    NotificationPanel {
        id: notificationPanel
        z: 100
        page: page
    }

        ShortcutsList {
            id: shortcutsView
            anchors.fill: parent
            sections: [
                BookmarkGroup.Temporary,
                BookmarkGroup.Bookmark,
                BookmarkGroup.Location,
                BookmarkGroup.External
            ]
            editable: false
            selectable: true
            multiSelect: true
            preselectTemporary: true

            VerticalScrollDecorator { flickable: shortcutsView }

            PullDownMenu {
                MenuItem {
                    text: qsTr("Enter target path")
                    onClicked: {
                        var start = Paths.dirName(toTransfer[0])
                        start = start.replace(/\/+/g, '/')
                        start = start.replace(/\/$/, '')
                        pageStack.animatorPush(Qt.resolvedUrl("../pages/PathEditDialog.qml"),
                                       { path: toTransfer.length === 0 ? StandardPaths.home :
                                                                         start,
                                           acceptCallback: function(path) {
                                               path = path.replace(/\/+/g, '/')
                                               path = path.replace(/\/$/, '')
                                               GlobalSettings.bookmarks.addTemporary(path)
                                           },
                                           acceptText: qsTr("Select")
                                       })
                    }
                }
            }

            header: Item {
                width: dialog.width
                height: head.height + col.height + Theme.paddingLarge

                DialogHeader { id: head }

                Column {
                    id: col
                    anchors.top: head.bottom
                    width: parent.width
                    spacing: Theme.paddingLarge

                    Label {
                        id: statusLabel
                        text: qsTr("%n item(s) selected for transferring", "", toTransfer.length) +
                              "\n" + qsTr("%n destinations(s) selected", "",
                                          shortcutsView.selectedLocations.length)
                        x: Theme.horizontalPageMargin
                        color: Theme.secondaryHighlightColor
                    }

                    TransferActionBar {
                        id: action
                        width: parent.width
                        height: Theme.itemSizeMedium
                        onSelectionChanged: dialog.selectedAction = selection
                    }

                    TextSwitch {
                        id: goToTargetSwitch
                        text: qsTr("Switch to target directory")
                        enabled: shortcutsView.selectedLocations.length <= 1
                        onCheckedChanged: goToTarget = checked
                    }
                }
            }

            footer: Spacer { height: Theme.horizontalPageMargin }
        }

    onAccepted: {
        targets = shortcutsView.selectedLocations.slice()
        GlobalSettings.bookmarks.clearTemporary()
        goToTarget = (goToTarget && targets.length <= 1)

        // the transfer has to be completed on the destination page
        // (e.g. using TransferPanel)
    }

    onRejected: {
        GlobalSettings.bookmarks.clearTemporary()
    }

    Component.onCompleted: {
        if (!toTransfer.length) {
            canAccept = false;
            notificationPanel.showTextWithTimer(qsTr("Nothing selected to transfer"), "");
        }
    }
}
