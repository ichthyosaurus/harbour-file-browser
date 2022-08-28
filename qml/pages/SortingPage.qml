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
import harbour.file.browser.FileModel 1.0
import harbour.file.browser.DirectorySettings 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string dir
    property bool _initialized: false

    DirectorySettings {
        id: prefs
        path: dir
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                id: header
                title: qsTr("Sorting and View")
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.pop();
                }
            }

            SelectableListView {
                id: sortList
                title: qsTr("Sort by...")
                onSelectionChanged: prefs.viewSortRole = newValue.toString()

                model: ListModel {
                    ListElement { label: qsTr("Name"); value: "name" }
                    ListElement { label: qsTr("Size"); value: "size" }
                    ListElement { label: qsTr("Modification time"); value: "modificationtime" }
                    ListElement { label: qsTr("File type"); value: "type" }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            SelectableListView {
                id: orderList
                title: qsTr("Order...")
                onSelectionChanged: prefs.viewSortOrder = newValue.toString()

                model: ListModel {
                    ListElement { label: qsTr("default"); value: "default" }
                    ListElement { label: qsTr("reversed"); value: "reversed" }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            SelectableListView {
                id: thumbList
                title: qsTr("Preview images...")

                model: ListModel {
                    ListElement { label: qsTr("none"); value: "none" }
                    ListElement { label: qsTr("small"); value: "small" }
                    ListElement { label: qsTr("medium"); value: "medium" }
                    ListElement { label: qsTr("large"); value: "large" }
                    ListElement { label: qsTr("huge"); value: "huge" }
                }

                onSelectionChanged: {
                    if (newValue.toString() === "none") prefs.viewPreviewsShown = false
                    else prefs.viewPreviewsShown = true
                    prefs.viewPreviewsSize = newValue.toString()
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            TextSwitch {
                id: showHiddenFiles
                text: qsTr("Show hidden files")
                onCheckedChanged: prefs.viewHiddenFilesShown = checked
            }
            TextSwitch {
                id: enableGallery
                text: qsTr("Enable gallery mode")
                description: qsTr("In gallery mode, images will be shown comfortably large, "
                    + "and all entries except for images, videos, and directories will be hidden.")
                onCheckedChanged: prefs.viewViewMode = (checked ? "gallery" : "list")
            }
            TextSwitch {
                id: showDirsFirst
                text: qsTr("Show folders first")
                onCheckedChanged: prefs.viewShowDirectoriesFirst = checked
            }
            TextSwitch {
                id: sortCaseSensitive
                text: qsTr("Sort case-sensitively")
                onCheckedChanged: prefs.viewSortCaseSensitively = checked
            }
        }
    }

    function updateShownSettings() {
        if (prefs.viewUseLocalSettings) header.description = qsTr("Local preferences");
        else header.description = qsTr("Global preferences");

        sortList.initial = prefs.viewSortRole
        orderList.initial = prefs.viewSortOrder

        showDirsFirst.checked = prefs.viewShowDirectoriesFirst
        enableGallery.checked = (prefs.viewViewMode === "gallery")
        sortCaseSensitive.checked = prefs.viewSortCaseSensitively
        showHiddenFiles.checked = prefs.viewHiddenFilesShown

        if (prefs.viewPreviewsShown) thumbList.initial = prefs.viewPreviewsSize
        else thumbList.initial = "none";

        if (!_initialized) _initialized = true;
    }

    Component.onCompleted: {
        updateShownSettings();
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            pageStack.pushAttached(Qt.resolvedUrl("SettingsPage.qml"));
        }
    }
}
