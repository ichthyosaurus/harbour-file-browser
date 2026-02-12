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
import Opal.SortFilterProxyModel 1.0
import Opal.SmartScrollbar 1.0

import harbour.file.browser.FileData 1.0
import harbour.file.browser.Settings 1.0
import harbour.file.browser.FileClipboard 1.0

import "../components"
import "../js/paths.js" as Paths

Page {
    id: root

    readonly property string _fnElide: GlobalSettings.generalFilenameElideMode
    readonly property int _nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    readonly property int _nameElideMode: _nameTruncMode === TruncationMode.Fade ?
                                              Text.ElideNone : (_fnElide === 'middle' ?
                                                                    Text.ElideMiddle : Text.ElideRight)

    /* Button {
        z: 100000
        anchors {
            top: parent.top
            left: parent.left
            margins: Theme.horizontalPageMargin
        }

        text: "DEBUG!"

        onClicked: {
            FileClipboard.setPaths(["/home"+"/nemo/Documents", "/home"+"/nemo/Videos", "/home"+"/nemo/Downloads"], FileClipMode.Copy)
            FileClipboard.setPaths(["/usr", "/etc", "/bin"], FileClipMode.Link)
            FileClipboard.setPaths(["/usr/lib", "/usr/share", "/usr/lib/qt5"], FileClipMode.Cut)
        }
    } */

    SilicaListView {
        id: list
        anchors.fill: parent
        model: FileClipboard.pathsModel

        header: Column {
            width: parent ? parent.width : Screen.width

            PageHeader {
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

            FileClipModePicker {
                id: modePicker
                visible: FileClipboard.count > 0
                selectedMode: FileClipboard.mode
                width: parent.width

                Connections {
                    // TODO selecting a mode breaks the binding between
                    // selectedMode and FileClipboard.mode. This means clipboard
                    // changes are not properly synchronised. Refactoring this
                    // in FileClipModePicker requires changes in TransferActionBar though.
                    target: FileClipboard
                    onModeChanged: modePicker.selectedMode = FileClipboard.mode
                }

                onSelectedModeChanged: {
                    if (selectedMode != FileClipboard.mode) {
                        FileClipboard.mode = selectedMode
                    }
                }
            }
        }

        footer: Item {
            height: Theme.horizontalPageMargin
            width: parent.width
        }

        PullDownMenu {
            enabled: visible
            visible: FileClipboard.count > 0

            MenuItem {
                visible: FileClipboard.count > 0
                text: qsTr("Clear", "verb as in 'clear all contents from the clipboard'")
                onClicked: {
                    var remorse = Remorse.popupAction(root, qsTr("Clipboard cleared"), function () {
                        FileClipboard.clear() })
                }
            }
        }

        SmartScrollbar {
            property int currentIndex: list.indexAt(list.contentX, list.contentY) + 2

            flickable: list
            text: '%1 / %2'.arg(currentIndex).arg(list.count)

            smartWhen: list.count > 40
            quickScrollWhen: !smartWhen || list.count > 1000
        }

        section {
            property: "directory"
            criteria: ViewSection.FullString
            labelPositioning: ViewSection.InlineLabels
            delegate: SectionHeader {
                text: section
            }
        }

        delegate: ListItem {
            id: item
            property int index: model.index
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
                        highlighted: item.highlighted
                        file: fileData.file
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
                        visible: fileData.isDir
                        text: qsTr("Open this folder")
                        onClicked: navigate_goToFolder(item.path)
                    }
                    MenuItem {
                        text: qsTr("Open containing folder")
                        onClicked: navigate_goToFolder(item.directory)
                    }
                    MenuItem {
                        text: qsTr("Remove from clipboard")
                        onClicked: {
                            var path = item.path
                            var forget = FileClipboard.forgetPath
                            item.remorseDelete(function() { forget(path) })
                        }
                    }
                }
            }
        }

        ViewPlaceholder {
            id: viewPlaceholder
            enabled: FileClipboard.count === 0
            text: qsTr("Empty")
            hintText: qsTr("Cut or copied files will be shown here.")
        }
    }

    Component.onCompleted: {
        FileClipboard.validate()
    }
}
