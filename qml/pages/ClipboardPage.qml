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
import harbour.file.browser.FileData 1.0
import harbour.file.browser.Settings 1.0
import harbour.file.browser.FileClipboard 1.0

import "../components"
import "../js/paths.js" as Paths

Page {
    id: root

    // TODO
    // - show clipboard history and allow copying files again
    // - simplify the layout and merge it back into DirectoryPageEntry{}
    // - store clipboard contents somewhere and share the clipboard with
    //   other windows of File Browser (through dconf?)

    property string _fnElide: GlobalSettings.generalFilenameElideMode
    property int _nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    property int _nameElideMode: _nameTruncMode === TruncationMode.Fade ?
                                     Text.ElideNone : (_fnElide === 'middle' ?
                                                           Text.ElideMiddle : Text.ElideRight)

    SilicaListView {
        id: list
        anchors.fill: parent
        model: FileClipboard.model

        header: Item {
            width: list.width
            height: head.height + combo.height + Theme.paddingLarge

            PageHeader {
                id: head
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

            ComboBox {
                id: combo
                visible: FileClipboard.count > 0
                width: parent.width
                anchors.top: head.bottom
                label: qsTr("Current selection", "as in 'currently selected files'")

                onCurrentIndexChanged: {
                    if (currentIndex === 0) {
                        FileClipboard.mode = FileClipMode.Copy
                    } else if (currentIndex === 1) {
                        FileClipboard.mode = FileClipMode.Link
                    } else {
                        FileClipboard.mode = FileClipMode.Cut
                    }
                }

                Component.onCompleted: {
                    if (FileClipboard.mode === FileClipMode.Copy) {
                        currentIndex = 0
                    } else if (FileClipboard.mode === FileClipMode.Link) {
                        currentIndex = 1
                    } else {
                        currentIndex = 2
                    }
                }

                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("copy", "as in 'please copy these files'")
                    }
                    MenuItem {
                        text: qsTr("link", "as in 'please create symlinks of these files'")
                    }
                    MenuItem {
                        text: qsTr("cut", "as in 'please cut these files'")
                    }
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

        delegate: Item {
            property var paths: model.paths
            property var pathsCount: model.count

            width: parent.width
            height: sublist.height + dirName.height

            SectionHeader {
                id: dirName
                anchors.top: parent.top
                visible: text !== ""
                text: parent.pathsCount > 0 ? Paths.dirName(parent.paths[0]) : ""
            }

            SilicaListView {
                id: sublist

                anchors.top: dirName.bottom
                model: parent.paths
                width: parent.width
                height: contentHeight

                Component.onCompleted: console.log("PATHS:", paths)

                delegate: ListItem {
                    id: item
                    width: ListView.view.width
                    contentHeight: Theme.itemSizeMedium
                    menu: contextMenu

                    property color _detailsColor: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    property alias _listLabelWidth: listLabel.width

                    FileData {
                        id: fileData
                        file: modelData
                        property string category
                        Component.onCompleted: category = typeCategory()
                    }

                    onClicked: {
                        pageStack.animatorPush(Qt.resolvedUrl("FilePage.qml"), {
                                                   'file': modelData,
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
                                highlighted: item.highlighted
                                file: modelData
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
                                when: _listLabelWidth >= 2*item.width/3
                                PropertyChanges { target: listLabel; wrapMode: Text.NoWrap; maximumLineCount: 1 }
                                PropertyChanges { target: sizeLabel; width: (fileData.isSymLink ? _listLabelWidth/3*2 : _listLabelWidth/3); horizontalAlignment: Text.AlignLeft }
                                PropertyChanges { target: permsLabel; width: _listLabelWidth/3; horizontalAlignment: Text.AlignHCenter }
                                PropertyChanges { target: datesLabel; width: _listLabelWidth/3; horizontalAlignment: Text.AlignRight }
                            },
                            State {
                                when: _listLabelWidth < 2*item.width/3
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
                                text: qsTr("Remove from clipboard")
                                onClicked: FileClipboard.forgetPath(modelData)
                            }
                            MenuItem {
                                visible: fileData.isDir
                                text: qsTr("Open this folder")
                                onClicked: navigate_goToFolder(modelData)
                            }
                            MenuItem {
                                text: qsTr("Open containing folder")
                                onClicked: navigate_goToFolder(fileData.absolutePath)
                            }
                        }
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: FileClipboard.count === 0
            text: qsTr("Empty")
            hintText: qsTr("Cut or copied files will be shown here.")
        }
    }
}
