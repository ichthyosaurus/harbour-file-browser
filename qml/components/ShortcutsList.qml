/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2023 Mirian Margiani
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
import SortFilterProxyModel 0.2

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

    readonly property var selectedLocations: {
        if (!selectionModel.hasSelection) return []

        var ret = []
        for (var i in selectionModel.selectedIndexes) {
            ret.push(sortedModel.data(selectionModel.selectedIndexes[i],
                                      sortedModel.roleForName("path")))
        }
        return ret
    }

    signal itemClicked(var clickedIndex, var path)

    property bool _isEditing: false
    function _editBookmarks() { if (editable) _isEditing = true; }
    function _finishEditing() { _isEditing = false; }

    onSectionsChanged: _updateOrderMap()
    property var _orderMap: ({})
    function _updateOrderMap() {
        var order = {}

        for (var i = 0; i < sections.length; ++i) {
            order[sections[i]] = i
        }

        _orderMap = order
    }

    model: SortFilterProxyModel {
        id: sortedModel
        sourceModel: GlobalSettings.bookmarks

        filters: ExpressionFilter {
            expression: _orderMap.hasOwnProperty(model.group)
        }

        sorters: ExpressionSorter {
            expression: _orderMap[modelLeft.group] < _orderMap[modelRight.group]
        }

        onRowsInserted: {
            if (!preselectTemporary) return

            for (var i = first; i <= last; i++) {
                var modelIndex = index(i, 0)
                if (data(modelIndex, roleForName("group")) === BookmarkGroup.Temporary) {
                    selectionModel.select(modelIndex, ItemSelectionModel.Select)
                }
            }
        }
    }

    ItemSelectionModel {
        id: selectionModel
        model: sortedModel
    }

    delegate: ListItem {
        id: listItem
        property var modelIndex: sortedModel.index(index, 0)
        property bool selected: selectionModel.hasSelection && selectionModel.isSelected(modelIndex)
        property string shortcutPath: Paths.unicodeArrow() + " " + model.path

        ListView.onRemove: animateRemoval(listItem) // enable animated list item removals
        menu: (model.group === BookmarkGroup.External &&
               !GlobalSettings.runningAsRoot &&
               GlobalSettings.systemSettingsEnabled) ?
                  settingsContextMenu : null
        openMenuOnPressAndHold: false

        width: root.width
        contentHeight: Theme.itemSizeSmall

        enabled: !_isEditing || !model.userDefined
        onClicked: {
            if (!_isEditing) {
                itemClicked(index, model.path)

                if (selectable) {
                    if (multiSelect) {
                        selectionModel.select(modelIndex, ItemSelectionModel.Toggle)
                    } else {
                        selectionModel.select(modelIndex, ItemSelectionModel.ClearAndSelect)
                    }
                }
            } else {
                _finishEditing()
            }
        }

        Binding on highlighted {
            when: selected || down
            value: true
        }

        Item {
            id: icon
            width: height
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: Theme.paddingMedium
            }

            Image {
                anchors.fill: parent
                source: "image://theme/" + model.thumbnail + "?" + (
                            listItem.highlighted ? Theme.highlightColor : Theme.primaryColor)

                property bool shown: !_isEditing || !model.userDefined
                opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            IconButton {
                anchors.fill: parent
                icon.source: "image://theme/icon-m-up"

                property bool shown: _isEditing && model.userDefined
                opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
                Behavior on opacity { NumberAnimation { duration: 100 } }

                onClicked: {
                    if (!model.userDefined || !model.path) return;
                    GlobalSettings.bookmarks.moveUp(model.path);
                }
            }
        }

        Label {
            id: shortcutLabel
            font.pixelSize: Theme.fontSizeMedium
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            text: model.name
            truncationMode: TruncationMode.Fade
            anchors {
                left: icon.right
                leftMargin: Theme.paddingMedium
                top: parent.top
                topMargin: model.path === model.name ? (parent.height / 2) - (height / 2) : 5
            }

            // waiting for deleteBookmarkBtn.opacity === 1.0, ie. waiting for the
            // transition to finish, makes sure we don't see graphical glitches
            // when changing from/to edit mode
            width: root.width - x -
                   (deleteBookmarkBtn.opacity === 1.0 ? deleteBookmarkBtn.width : Theme.horizontalPageMargin)

            property bool shown: true
            opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        TextField {
            id: editLabel

            property bool shown: !shortcutLabel.shown
            opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }

            z: infoRow.z-1
            placeholderText: model.name
            text: model.name
            labelVisible: false
            textTopMargin: 0
            textMargin: 0
            anchors {
                left: icon.right
                leftMargin: Theme.paddingMedium
                top: parent.top
                topMargin: model.path === model.name ? (parent.height / 2) - (height / 2) : 5
            }
            width: root.width - x -
                   (deleteBookmarkBtn.visible ? deleteBookmarkBtn.width : Theme.horizontalPageMargin)
            Connections { target: editLabel._editor; onAccepted: _finishEditing(); }
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

            property bool shown: true
            opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }

            Row {
                id: sizeInfo
                visible: model.showSize
                width: parent.width
                spacing: Theme.paddingMedium

                property int diskSpaceHandle: -1
                property var diskSpaceInfo: ['']

                onVisibleChanged: {
                    if (visible) {
                        diskSpaceHandle = engine.requestDiskSpaceInfo(model.path)
                    }
                }

                Component.onCompleted: {
                    if (model.showSize) {
                        diskSpaceHandle = engine.requestDiskSpaceInfo(model.path)
                    }
                }

                Connections {
                    target: model.showSize ? engine : null
                    onDiskSpaceInfoReady: {
                        if (sizeInfo.diskSpaceHandle == handle) {
                            sizeInfo.diskSpaceHandle = -1

                            /* debugDelayer.info = info
                            debugDelayer.start() */
                            sizeInfo.diskSpaceInfo = info
                        }
                    }
                }

                /* Timer {
                    id: debugDelayer
                    property var info
                    onTriggered: sizeInfo.diskSpaceInfo = info
                    interval: 2000
                } */

                Rectangle {
                    width: parent.width - calculating.width
                    height: Theme.paddingSmall
                    anchors.verticalCenter: calculating.verticalCenter
                    color: Theme.rgba(highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor,
                                      Theme.opacityLow)
                    radius: 50

                    Rectangle {
                        anchors.left: parent.left
                        width: parent.width / 100 * parseInt(sizeInfo.diskSpaceInfo[1], 10)
                        Behavior on width { NumberAnimation { duration: 200 } }
                        height: parent.height
                        color: highlighted ? Theme.highlightColor : Theme.primaryColor
                        radius: 50
                    }
                }

                Row {
                    id: calculating

                    BusyIndicator {
                        size: BusyIndicatorSize.ExtraSmall
                        visible: sizeInfo.diskSpaceInfo[0] === ''
                        running: visible
                    }

                    Label {
                        visible: sizeInfo.diskSpaceInfo[0] !== ''
                        text: qsTr("%1 free").arg(sizeInfo.diskSpaceInfo[3])
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }
                }
            }

            Text {
                id: shortcutPathLabel
                width: parent.width - (sizeInfo.visible ? sizeInfo.width : 0)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                text: Paths.unicodeArrow() + " " + model.path
                visible: (model.path === model.name || model.showSize) ? false : true
                elide: Text.ElideMiddle
            }
        }

        onPressAndHold: {
            if (model.userDefined ? true : false) {
                _editBookmarks();
            } else if (menu !== null && menu !== undefined) {
                openMenu({'shortcutPath': shortcutPath})
            }
        }

        IconButton {
            id: deleteBookmarkBtn
            width: Theme.itemSizeSmall
            height: Theme.itemSizeSmall
            icon.source: "image://theme/icon-m-remove"

            property bool shown: false
            opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }

            anchors {
                top: parent.top
                right: parent.right
                rightMargin: Theme.paddingSmall
                leftMargin: Theme.paddingSmall
            }

            onClicked: {
                if (!model.userDefined || !model.path) return;
                GlobalSettings.bookmarks.remove(model.path);
            }
        }

        states: [
            State {
                name: "" // default state
                PropertyChanges { target: infoRow; shown: true; }
                PropertyChanges { target: shortcutLabel; shown: true; }
                PropertyChanges { target: deleteBookmarkBtn; shown: false; }
                PropertyChanges { target: editLabel; readOnly: true; }
            },
            State {
                name: "editing"
                when: _isEditing && model.userDefined === true;
                PropertyChanges { target: infoRow; shown: false; }
                PropertyChanges { target: shortcutLabel; shown: false; }
                PropertyChanges { target: deleteBookmarkBtn; shown: allowDeleteBookmarks; }
                PropertyChanges { target: editLabel; readOnly: false; text: model.name; }
            }
        ]

        onStateChanged: {
            if (state !== "") return;
            var oldText = model.name;
            var newText = editLabel.text;

            if (newText === "" || oldText === newText || model.path === "" || !model.path) {
                return;
            }

            model.name = newText;
            GlobalSettings.bookmarks.rename(model.path, newText);
        }
    }

    Component {
        id: settingsContextMenu

        ContextMenu {
            property string shortcutPath

            MenuLabel {
                text: shortcutPath
            }

            MenuItem {
                text: qsTr("Open system settings");
                onClicked: {
                    pageStack.push(Qt.resolvedUrl(GlobalSettings.storageSettingsPath));
                }
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

    Component.onCompleted: {
        _updateOrderMap()
    }
}
