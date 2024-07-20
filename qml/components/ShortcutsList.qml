/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2024 Mirian Margiani
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

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.Settings 1.0

import "../js/paths.js" as Paths

SilicaListView {
    id: root

    property bool selectable: false
    property bool multiSelect: false
    property bool preselectTemporary: false
    property bool allowDeleteBookmarks: true
    property bool editable: true

    property var sections: [
        BookmarkGroup.Temporary,
        BookmarkGroup.Location,
        BookmarkGroup.External,
        BookmarkGroup.Bookmark
    ]

    readonly property var selectedLocations: selectionModel.hasSelection ?
        GlobalSettings.bookmarks.pathsForIndexes(selectionModel.selectedIndexes) : []
    function resetSelectedLocations() { selectionModel.clearSelection() }

    signal itemClicked(var clickedIndex, var path)

    onSectionsChanged: GlobalSettings.bookmarks.sortFilter(sections)

    model: GlobalSettings.bookmarks

    ItemSelectionModel {
        id: selectionModel
        model: GlobalSettings.bookmarks
    }

    Connections {
        target: GlobalSettings.bookmarks
        onTemporaryAdded: {
            if (!preselectTemporary) return
            selectionModel.select(modelIndex, ItemSelectionModel.Select)
        }
    }

    delegate: ListItem {
        id: listItem
        property var modelIndex: GlobalSettings.bookmarks.index(index, 0)
        property int intIndex: index
        property bool selected: selectionModel.hasSelection && selectionModel.isSelected(modelIndex)
        property string shortcutPath: Paths.unicodeArrow() + " " + model.path
        property var alternativePaths: model.alternatives
        property var alternativeDevices: model.devices
        property string selectedPath: ""

        ListView.onRemove: animateRemoval(listItem) // enable animated list item removals
        menu: {
            if (!editable && model.group !== BookmarkGroup.Location) return

            if (model.group === BookmarkGroup.External &&
                    !GlobalSettings.runningAsRoot &&
                    GlobalSettings.systemSettingsEnabled) {
                return settingsContextMenu
            } else if (model.group === BookmarkGroup.Bookmark) {
                return bookmarkContextMenu
            } else if (model.group === BookmarkGroup.Location &&
                       model.alternatives.length > 0) {
                console.log(model.name, "shortcut alternatives:", model.alternatives)
                return alternativesMenu
            } else {
                return null
            }
        }

        Component {
            id: alternativesMenu

            ContextMenu {
                Repeater {
                    model: listItem.alternativePaths

                    MenuItem {
                        text: modelData.name
                        onClicked: {
                            itemClicked(listItem.intIndex, modelData.path)

                            if (root.selectable) {
                                listItem.selectedPath = modelData.path

                                if (root.multiSelect) {
                                    selectionModel.select(listItem.modelIndex, ItemSelectionModel.Toggle)
                                } else {
                                    selectionModel.select(listItem.modelIndex, ItemSelectionModel.ClearAndSelect)
                                }
                            }
                        }
                    }
                }
            }
        }

        openMenuOnPressAndHold: false

        width: root.width
        contentHeight: Theme.itemSizeSmall

        onClicked: {
            if (!!alternativePaths && alternativePaths.length > 0) {
                openMenu()
            } else {
                itemClicked(index, model.path)

                if (selectable) {
                    if (multiSelect) {
                        selectionModel.select(modelIndex, ItemSelectionModel.Toggle)
                    } else {
                        selectionModel.select(modelIndex, ItemSelectionModel.ClearAndSelect)
                    }
                }
            }
        }

        Binding on highlighted {
            when: selected || down
            value: true
        }

        HighlightImage {
            id: icon
            width: height
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: Theme.paddingMedium
            }

            source: "image://theme/" + model.thumbnail
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            id: shortcutLabel
            font.pixelSize: Theme.fontSizeMedium
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
            text: model.name
            truncationMode: TruncationMode.Fade
            anchors {
                left: icon.right
                leftMargin: Theme.paddingMedium
                top: parent.top
                topMargin: model.path === model.name ? (parent.height / 2) - (height / 2) : 5
            }
            width: root.width - x - Theme.horizontalPageMargin
        }

        Row {
            id: infoRow
            spacing: 0
            anchors {
                left: icon.right
                leftMargin: Theme.paddingMedium
                top: shortcutLabel.bottom
                topMargin: 2
                right: shortcutLabel.right
            }

            Loader {
                id: loader_sizeInfo
                width: parent.width
                asynchronous: true
                Component.onCompleted: {
                    if (model.showSize) {
                        // WARNING does not react to changes in model.showSize
                        setSource(Qt.resolvedUrl("StorageSizeBar.qml"), {'path': model.path})
                    }
                }
            }

            Text {
                id: shortcutPathLabel
                width: parent.width
                font.pixelSize: Theme.fontSizeExtraSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                text: {
                    if (!!listItem.selectedPath) {
                        return Paths.unicodeArrow() + " " + listItem.selectedPath
                    } else if (listItem.alternativePaths.length > 0) {
                        return listItem.alternativeDevices.join(", ") // qsTr("%n alternatives", "", listItem.alternativePaths.length)
                    } else {
                        return Paths.unicodeArrow() + " " + model.path
                    }
                }
                visible: model.path !== model.name && !model.showSize
                elide: Text.ElideMiddle
            }
        }

        onPressAndHold: {
            if (menu != null && menu != undefined) {
                openMenu({'pathLabel': shortcutPath, 'path': model.path, 'listItem': listItem})
            }
        }
    }

    Component {
        id: settingsContextMenu

        ContextMenu {
            id: menu
            property string pathLabel

            MenuLabel {
                text: pathLabel
            }

            MenuItem {
                text: qsTr("Open system settings");
                onClicked: {
                    pageStack.push(Qt.resolvedUrl(GlobalSettings.storageSettingsPath));
                }
            }
        }
    }

    Component {
        id: bookmarkContextMenu

        ContextMenu {
            id: menu
            property ListItem listItem
            property string pathLabel
            property string path

            MenuItem {
                text: qsTr("Rename")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../pages/BookmarksRenameDialog.qml"),
                                   {'startAt': menu.path})
                }
            }
            MenuItem {
                text: qsTr("Sort")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../pages/BookmarksSortPage.qml"))
                }
            }
            MenuItem {
                text: qsTr("Remove")
                onClicked: {
                    var path = menu.path
                    var forget = GlobalSettings.bookmarks.remove
                    listItem.remorseDelete(function() { forget(path) })
                }
            }
            MenuLabel {
                text: pathLabel
            }
        }
    }

    section {
        property: 'group'
        delegate: SectionHeader {
            height: Theme.itemSizeExtraSmall
            text: {
                if (section == BookmarkGroup.Bookmark) qsTr("Bookmarks")
                else if (section == BookmarkGroup.External) qsTr("Storage devices")
                else if (section == BookmarkGroup.Location) qsTr("Locations")
                else if (section == BookmarkGroup.Temporary) qsTr("Custom")
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            GlobalSettings.bookmarks.sortFilter(sections)
        }
    }
}
