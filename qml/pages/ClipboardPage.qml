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

import "../components"
import "../js/paths.js" as Paths

Page {
    id: root

    // TODO
    // - show clipboard history and allow copying files again
    // - simplify the layout and merge it back into DirectoryPageEntry{}
    // - store clipboard contents somewhere and share the clipboard with
    //   other windows of File Browser (through dconf?)

    property string _fnElide: main.globalSettings.generalFilenameElideMode
    property int _nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    property int _nameElideMode: _nameTruncMode === TruncationMode.Fade ?
                                    Text.ElideNone : (_fnElide === 'middle' ?
                                                          Text.ElideMiddle : Text.ElideRight)

    SilicaListView {
        id: list
        anchors.fill: parent
        model: engine.clipboardContents

        header: Item {
            width: list.width
            height: head.height + combo.height + dirName.height + Theme.paddingLarge

            PageHeader {
                id: head
                title: qsTr("Clipboard")
                description: engine.clipboardCount > 0 ?
                                 (engine.clipboardContainsCopy ?
                                      qsTr("%n item(s) to be copied", "", engine.clipboardCount) :
                                      qsTr("%n item(s) to be moved", "", engine.clipboardCount)) : ""
            }

            ComboBox {
                id: combo
                visible: engine.clipboardCount > 0
                width: parent.width
                anchors.top: head.bottom
                label: qsTr("Current selection", "as in 'currently selected files'")

                onCurrentIndexChanged: {
                    engine.clipboardContainsCopy = (currentIndex == 0)
                }
                Component.onCompleted: {
                    currentIndex = (engine.clipboardContainsCopy ? 0 : 1)
                }

                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("copy", "as in 'please copy these files'")
                    }
                    MenuItem {
                        text: qsTr("cut", "as in 'please cut these files'")
                    }
                }
            }

            SectionHeader {
                id: dirName
                anchors.top: combo.bottom
                visible: text !== ""
                text: engine.clipboardCount > 0 ? Paths.dirName(engine.clipboardContents[0]) : ""
            }
        }

        PullDownMenu {
            enabled: visible
            visible: engine.clipboardCount > 0

            MenuItem {
                text: qsTr("Clear", "as in 'clear the current clipboard contents'")
                onClicked: engine.clearClipboard()
            }
        }

        VerticalScrollDecorator { flickable: list }

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
                        onClicked: engine.forgetClipboardEntry(modelData)
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

        ViewPlaceholder {
            enabled: engine.clipboardCount === 0
            text: qsTr("Empty")
            hintText: qsTr("Cut or copied files will be shown here.")
        }
    }
}
