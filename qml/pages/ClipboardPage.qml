/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
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
import Sailfish.Silica 1.0
import SortFilterProxyModel 0.2
import harbour.file.browser.FileData 1.0
import harbour.file.browser.Settings 1.0
import harbour.file.browser.FileClipboard 1.0

import "../components"
import "../js/paths.js" as Paths

Page {
    id: root

    // TODO
    // - store clipboard contents somewhere and share the clipboard with
    //   other windows of File Browser (through dconf?)
    // - drawers break when clearing the current selection

    readonly property string _fnElide: GlobalSettings.generalFilenameElideMode
    readonly property int _nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    readonly property int _nameElideMode: _nameTruncMode === TruncationMode.Fade ?
                                              Text.ElideNone : (_fnElide === 'middle' ?
                                                                    Text.ElideMiddle : Text.ElideRight)

    property bool _showCurrent: true
    property bool _showHistory: true // false

    Button {
        z: 100000
        anchors {
            top: parent.top
            left: parent.left
            margins: Theme.horizontalPageMargin
        }

        text: "DEBUG!"

        onClicked: {
            FileClipboard.setPaths(["/home/nemo/Documents", "/home/nemo/Videos", "/home/nemo/Downloads"], FileClipMode.Copy)
            FileClipboard.setPaths(["/usr", "/etc", "/bin"], FileClipMode.Link)
            FileClipboard.setPaths(["/usr/lib", "/usr/share", "/usr/lib/qt5"], FileClipMode.Cut)
        }
    }

    SortFilterProxyModel {
        id: filteredModel
        sourceModel: FileClipboard.model
        filters: IndexFilter {
            minimumIndex: 0
            maximumIndex: _showHistory ? -1 : 0
        }
    }

    Component {
        id: currentDrawerComp

        GroupedDrawer {
            width: list.width
            title: FileClipboard.count > 0 ?
                       qsTr("Current selection") :
                       qsTr("Current selection (empty)")
            open: true
            onOpenChanged: _showCurrent = open

            onTitleChanged: {
                if (FileClipboard.count > 0) {
                    open = true
                    enabled = true
                } else {
                    open = false
                    enabled = false
                }
            }

//            contents: FileClipModePicker {
//                selectedMode: FileClipboard.mode
//                width: parent.width

//                onSelectedModeChanged: {
//                    FileClipboard.mode = selectedMode
//                }
//            }
        }
    }

    Component {
        id: historyDrawerComp

        GroupedDrawer {
            width: list.width
            title: qsTr("History", "as in 'list of elements that once were activated but are disabled now'")
            open: _showHistory || FileClipboard.count == 0
            onOpenChanged: _showHistory = open
        }
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: filteredModel

        header: PageHeader {
            title: qsTr("Clipboard")
            description: {
                if (FileClipboard.count == 0) {
                    return ""
                } else if (FileClipboard.mode === FileClipMode.Copy) {
                    return qsTr("%n item(s) to be copied", "", FileClipboard.count)
                } else if (FileClipboard.mode === FileClipMode.Cut) {
                    return qsTr("%n item(s) to be moved", "", FileClipboard.count)
                } else if (FileClipboard.mode === FileClipMode.Link) {
                    return qsTr("%n item(s) to be linked", "", FileClipboard.count)
                } else {
                    return ""
                }
            }
        }

        PullDownMenu {
            enabled: visible
            visible: FileClipboard.count > 0 || FileClipboard.model.historyCount > 0

            MenuItem {
                visible: FileClipboard.model.historyCount > 0
                text: qsTr("Clear all", "as in 'clear all clipboard contents, including history'")
                onClicked: FileClipboard.model.clearAll()
            }
            MenuItem {
                visible: FileClipboard.count > 0
                text: qsTr("Clear current", "as in 'clear the current clipboard contents'")
                onClicked: FileClipboard.model.clearCurrent()
            }
        }

        VerticalScrollDecorator { flickable: list }

        delegate: Column {
            id: item
            property var paths: model.paths
            property var pathsModel: model.pathsModel
            property var pathsCount: model.count
            property int index: model.index

            width: parent.width
            height: childrenRect.height + Theme.paddingLarge
            spacing: Theme.paddingSmall

            Loader {
                id: currentDrawerLoader
                enabled: item.index === 0
                sourceComponent: enabled ? currentDrawerComp : null
            }

            Item {
                width: parent.width
//                visible: item.index > 0
                height: historyPicker.height

                FileClipModePicker {
                    id: historyPicker
                    selectedMode: item.index === 0 ? FileClipboard.mode : -1
                    anchors {
                        left: parent.left
                        right: clearIcon.left
                        rightMargin: Theme.horizontalPageMargin
                    }

                    onSelectedModeChanged: {
                        if (item.index === 0) {
                            if (selectedMode == FileClipboard.mode) return
                            FileClipboard.mode = selectedMode
                        } else {
                            FileClipboard.model.selectGroup(item.index, selectedMode)
                            list.scrollToTop()
                        }
                    }
                }

//                IconButton {
//                    id: clearIcon
//                    visible: item.index > 0
//                    onClicked: FileClipboard.model.forgetGroup(item.index)

//                    anchors {
//                        right: parent.right
//                        rightMargin: Theme.horizontalPageMargin
//                        verticalCenter: parent.verticalCenter
//                    }
//                    opacity: Theme.opacityHigh
//                    icon.source: "image://theme/icon-m-clear"
//                }
            }

            SilicaListView {
                id: sublist

                model: parent.pathsModel
                width: parent.width
                height: item.index === 0 ? (_showCurrent ? contentHeight : 0) : contentHeight
                visible: height > 0

                // Required to make sure the page scrolls properly when opening
                // a context menu at the very bottom of the page.
                property var __silica_hidden_flickable: null

                section {
                    property: "directory"
                    criteria: ViewSection.FullString
                    labelPositioning: ViewSection.InlineLabels
                    delegate: SectionHeader {
                        text: section
                    }
                }

                delegate: ListItem {
                    id: sublistItem
                    property string path: model.path
                    property string directory: model.directory

                    width: ListView.view.width
                    contentHeight: Theme.itemSizeMedium
                    menu: contextMenu

                    property color _detailsColor: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    property alias _listLabelWidth: listLabel.width

                    FileData {
                        id: fileData
                        file: path
                        property string category
                        Component.onCompleted: category = typeCategory()
                    }

                    onClicked: {
                        pageStack.animatorPush(Qt.resolvedUrl("FilePage.qml"), {
                                                   'file': path,
                                                   'allowMoveDelete': false,
                                                   'enableOpenFolder': true,
                                               })
                    }

                    Loader {
                        id: listIcon
                        x: Theme.paddingLarge
                        width: Theme.itemSizeMedium
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: Component {
                            id: listIconComponent
                            FileIcon {
                                showThumbnail: true
                                highlighted: sublistItem.highlighted
                                file: sublistItem.path
                                isDirectory: fileData.isDir
                                mimeTypeCallback: function() { return fileData.mimeType; }
                                fileIconCallback: function() { return fileData.icon; }
                            }
                        }
                        asynchronous: index > 20
                    }

                    Label {
                        id: listLabel
                        y: Theme.paddingSmall
                        anchors {
                            left: listIcon.right; leftMargin: Theme.paddingMedium
                            right: parent.right; rightMargin: Theme.paddingLarge
                            top: parent.top; topMargin: Theme.paddingSmall
                        }
                        text: fileData.name
                        textFormat: Text.PlainText
                        truncationMode: _nameTruncMode
                        elide: _nameElideMode
                    }

                    Flow {
                        anchors {
                            left: listIcon.right; leftMargin: Theme.paddingMedium
                            right: parent.right; rightMargin: Theme.paddingLarge
                            top: listLabel.bottom; bottom: parent.bottom
                        }

                        Label {
                            id: sizeLabel
                            property string size: fileData.isDir ? fileData.dirSize : fileData.size

                            text: fileData.isSymLink ? (size + " " + Paths.unicodeArrow() + " " + fileData.symLinkTarget) : size
                            color: _detailsColor
                            truncationMode: TruncationMode.Fade
                            elide: Text.ElideMiddle
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        Label {
                            id: permsLabel
                            visible: !fileData.isSymLink
                            text: fileData.kind + fileData.permissions
                            color: _detailsColor
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        Label {
                            id: datesLabel
                            text: fileData.modified
                            color: _detailsColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        states: [
                            State {
                                when: _listLabelWidth >= 2*sublistItem.width/3
                                PropertyChanges { target: listLabel; wrapMode: Text.NoWrap; maximumLineCount: 1 }
                                PropertyChanges { target: sizeLabel; width: (fileData.isSymLink ? _listLabelWidth/3*2 : _listLabelWidth/3); horizontalAlignment: Text.AlignLeft }
                                PropertyChanges { target: permsLabel; width: _listLabelWidth/3; horizontalAlignment: Text.AlignHCenter }
                                PropertyChanges { target: datesLabel; width: _listLabelWidth/3; horizontalAlignment: Text.AlignRight }
                            },
                            State {
                                when: _listLabelWidth < 2*sublistItem.width/3
                                PropertyChanges { target: listLabel; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; maximumLineCount: 2 }
                                PropertyChanges { target: sizeLabel; width: _listLabelWidth; horizontalAlignment: Text.AlignLeft }
                                PropertyChanges { target: permsLabel; width: _listLabelWidth; horizontalAlignment: Text.AlignLeft }
                                PropertyChanges { target: datesLabel; width: _listLabelWidth; horizontalAlignment: Text.AlignLeft }
                            }
                        ]
                    }

                    Component {
                        id: contextMenu
                        ContextMenu {
                            MenuItem {
                                visible: !FileClipboard.isInCurrentSelection(sublistItem.path)
                                text: qsTr("Add to current selection")
                                onClicked: FileClipboard.appendPath(sublistItem.path)
                            }
                            MenuItem {
                                visible: fileData.isDir
                                text: qsTr("Open this folder")
                                onClicked: navigate_goToFolder(sublistItem.path)
                            }
                            MenuItem {
                                text: qsTr("Open containing folder")
                                onClicked: navigate_goToFolder(sublistItem.directory)
                            }
                            MenuItem {
                                text: qsTr("Remove from clipboard")
                                onClicked: {
                                    if (item.pathsCount > 1) {
                                        FileClipboard.model.forgetPath(item.index, sublistItem.path)
                                    } else {
                                        FileClipboard.model.forgetGroup(item.index)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                id: historyDrawerLoader
                // only show if there are more entries than the active selection
                enabled: item.index === 0 && FileClipboard.model.historyCount > 1
                sourceComponent: enabled ? historyDrawerComp : null
            }
        }

        ViewPlaceholder {
            id: viewPlaceholder
            enabled: FileClipboard.count === 0 && FileClipboard.model.historyCount === 0
            text: qsTr("Empty")
            hintText: qsTr("Cut or copied files will be shown here.")
        }
    }
}
