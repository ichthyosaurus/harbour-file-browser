/*
 * This file is part of File Browser.
 *
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
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
    canAccept: false

    NotificationPanel {
        id: notificationPanel
        z: 100
        page: page
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        VerticalScrollDecorator { }

        ShortcutsList {
            id: shortcutsView
            width: flickable.width
            height: flickable.height - 2*Theme.horizontalPageMargin
            sections: ["custom", "bookmarks", "locations", "external"]
            customEntries: ([])
            editable: false
            selectable: true
            multiSelect: true
            onItemSelected: dialog.updateStatus()
            onItemDeselected: dialog.updateStatus()

            PullDownMenu {
                MenuItem {
                    text: qsTr("Enter path")
                    onClicked: {
                        var start = Paths.dirName(toTransfer[0])
                        start = start.replace(/\/+/g, '/')
                        start = start.replace(/\/$/, '')
                        pageStack.push(Qt.resolvedUrl("../pages/PathEditDialog.qml"),
                                       { path: toTransfer.length === 0 ? StandardPaths.home :
                                                                         start,
                                           acceptCallback: function(path) {
                                               path = path.replace(/\/+/g, '/')
                                               path = path.replace(/\/$/, '')
                                               shortcutsView.customEntries.push(path)
                                               shortcutsView.updateModel()
                                               // TODO find a way to immediately select the new entry
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
                        text: updateText()
                        x: Theme.horizontalPageMargin
                        color: Theme.secondaryColor

                        function updateText() {
                            text = qsTr("%n item(s) selected for transferring", "", toTransfer.length) +
                                   "\n" + qsTr("%n destinations(s) selected", "",
                                               shortcutsView._selectedIndex.length)
                        }

                        Connections {
                            target: shortcutsView;
                            onItemSelected: statusLabel.updateText()
                            onItemDeselected: statusLabel.updateText()
                        }
                    }

                    TransferActionBar {
                        id: action
                        width: parent.width
                        height: Theme.itemSizeMedium
                        onSelectionChanged: {
                            dialog.selectedAction = selection
                            dialog.updateStatus();
                        }
                    }

                    TextSwitch {
                        id: goToTargetSwitch
                        text: qsTr("Switch to target directory")
                        enabled: shortcutsView._selectedIndex.length <= 1
                        onCheckedChanged: goToTarget = checked;
                        Connections {
                            target: shortcutsView;
                            onItemSelected: goToTargetSwitch.enabled = (shortcutsView._selectedIndex.length <= 1)
                            onItemDeselected: goToTargetSwitch.enabled = (shortcutsView._selectedIndex.length <= 1)
                        }
                    }
                }
            }
        }
    }

    function updateStatus() {
        if (selectedAction !== "" && shortcutsView._selectedIndex.length > 0) {
            canAccept = true;
        } else {
            canAccept = false;
        }
    }

    onAccepted: {
        targets = shortcutsView.getSelectedLocations();
        goToTarget = (goToTarget && targets.length <= 1);

        // the transfer has to be completed on the destination page
        // (e.g. using TransferPanel)
    }

    Component.onCompleted: {
        if (!toTransfer.length) {
            canAccept = false;
            notificationPanel.showTextWithTimer(qsTr("Nothing selected to transfer"), "");
        }
    }
}
