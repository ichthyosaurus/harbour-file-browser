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
import harbour.file.browser.Settings 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string dir

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
                description: prefs.viewUseLocalSettings ?
                                 qsTr("Settings apply only to the current folder. Swipe right to change default values.") :
                                 qsTr("Settings apply to all folders.")
                descriptionWrapMode: Text.Wrap
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.pop()
                }
            }

            SelectableListView {
                id: sortList
                title: qsTr("Sort by...")
                onSelectionChanged: prefs.viewSortRole = newValue.toString()

                model: ListModel {
                    ListElement { label: qsTr("Name"); value: "name" }
                    ListElement { label: qsTr("Size"); value: "size" }
                    ListElement { label: qsTr("File age"); value: "modificationtime" }
                    ListElement { label: qsTr("File type"); value: "type" }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            SelectableListView {
                id: orderList
                title: qsTr("Order...")
                onSelectionChanged: prefs.viewSortOrder = newValue.toString()

                model: ListModel {
                    ListElement { label: qsTr("ascending"); value: "default" }
                    ListElement { label: qsTr("descending"); value: "reversed" }
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

            SettingsSwitch {
                text: qsTr("Show hidden files")
                key: "viewHiddenFilesShown"
                description: qsTr('Show files with names starting with a full stop (“.”).')
                settingsContainer: prefs
            }
            TextSwitch {
                text: qsTr("Enable gallery mode")
                description: qsTr("In gallery mode, images will be shown comfortably large, " +
                                  "and all entries except for images, videos, and directories will be hidden.")
                automaticCheck: false
                checked: prefs.viewViewMode === "gallery"
                onClicked: {
                    // writing the new value will update "checked"
                    prefs.viewViewMode = (checked ? "gallery" : "list")
                }
            }
            SettingsSwitch {
                text: qsTr("Sort case-sensitively")
                key: "viewSortCaseSensitively"
                description: qsTr("Show files with names starting with a capital letter first.")
                visible: settingsContainer.viewSortRole == "name"
                settingsContainer: prefs
            }
            SettingsSwitch {
                text: qsTr("Show folders first")
                key: "viewShowDirectoriesFirst"
                description: qsTr("Always show folders at the top of the file list.")
                settingsContainer: prefs
            }
            SettingsSwitch {
                text: qsTr("Show hidden files last")
                key: "viewShowHiddenLast"
                description: qsTr("Always show files starting with a full stop (“.”) at the end of the file list.")
                settingsContainer: prefs
            }
        }
    }

    function updateShownSettings() {
        sortList.initial = prefs.viewSortRole
        orderList.initial = prefs.viewSortOrder

        if (prefs.viewPreviewsShown) thumbList.initial = prefs.viewPreviewsSize
        else thumbList.initial = "none";
    }

    Component.onCompleted: {
        updateShownSettings();
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            pageStack.pushAttached(main.settingsPage);
        }
    }
}
