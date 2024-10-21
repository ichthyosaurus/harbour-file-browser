/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2019-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
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
                                 qsTr("Settings apply only to the current folder. Swipe from the right to change default values.") :
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
                    ListElement { label: qsTr("Modification date"); value: "modificationtime" }
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
            SettingsSwitch {
                text: qsTr("Enable gallery mode")
                key: "viewViewMode"
                description: qsTr("In gallery mode, images will be shown to fit the screen. " +
                                  "Other files are shown without preview thumbnails.")
                settingsContainer: prefs

                // @disable-check M4
                checkedValue: "gallery"

                clickHandler: function() {
                    if (settingsContainer[key] === "gallery") {
                        settingsContainer[key] = "list"
                    } else {
                        settingsContainer[key] = "gallery"
                    }
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
