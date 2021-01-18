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
import harbour.file.browser.FileData 1.0

Item {
    id: base
    width: isUpright ? Screen.width : Screen.height
    height: isUpright ? (showLabel ? label.height : 0)+groupA.height+groupB.height :
                        _itemSize+Theme.paddingLarge

    property var selectedFiles: function() {
        // function returning a list of selected files (has to be provided)
        console.log("error: missing implementation of FileActions::selectedFiles()!")
        return -1;
    }
    property var errorCallback: function(errorMsg) { console.error("FileActions:", errorMsg); }
    property int selectedCount
    property alias labelText: label.text
    property bool isUpright: main.orientation === Orientation.Portrait ||
                             main.orientation === Orientation.PortraitInverted
    property bool enabled: true
    property bool showLabel: true
    property bool displayClose: false

    property bool showSelection: true
    property bool showCut: true
    property bool showCopy: true
    property bool showDelete: true
    property bool showProperties: true

    property bool showRename: true
    property bool showShare: true
    property bool showTransfer: true
    property bool showCompress: true
    property bool showEdit: true

    property int _itemSize: Theme.iconSizeMedium

    // emitted after the action has been completed
    signal selectAllTriggered
    signal cutTriggered
    signal copyTriggered
    signal deleteTriggered // <- action has to be executed by caller
    signal closeTriggered
    signal propertiesTriggered
    signal renameTriggered(var oldFiles, var newFiles)
    signal shareTriggered
    signal transferTriggered(var toTransfer, var targets, var selectedAction, var goToTarget)
    signal compressTriggered
    signal editTriggered

    onSelectedCountChanged: {
        labelText = qsTr("%n file(s) selected", "", selectedCount);
    }

    FileData {
        id: fileData
    }

    Label {
        id: label
        visible: showLabel
        height: showLabel ? (isUpright ? _itemSize : _itemSize+Theme.paddingLarge) : 1
        width: showLabel ? (isUpright ? parent.width : 2*Theme.itemSizeLarge) : (
            (parent.width-(groupA.width+groupB.width))/2-groupA.anchors.leftMargin
                           )
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
    }

    FileActionsRow {
        id: groupA
        tiedTo: label

        IconButton {
            visible: showSelection
            enabled: base.enabled; icon.width: _itemSize; icon.height: _itemSize
            icon.source: displayClose ? "image://theme/icon-m-clear"
                                      : "../images/toolbar-select-all.png"
                                   // : "image://theme/icon-m-select-all" -- does not feel intuitive
            icon.color: Theme.primaryColor
            onPressAndHold: {
                if (displayClose) labelText = qsTr("clear selection");
                else labelText = qsTr("select all");
            }
            onClicked: { displayClose ? closeTriggered() : selectAllTriggered(); }
        }
        IconButton {
            visible: showCut
            enabled: base.enabled && selectedCount > 0; icon.width: _itemSize; icon.height: _itemSize
            icon.source: "../images/toolbar-cut.png"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("cut file(s)", "", selectedCount);
            onClicked: {
                var files = selectedFiles();
                engine.cutFiles(files);
                labelText = qsTr("%n file(s) cut", "", engine.clipboardCount);
                cutTriggered();
            }
        }
        IconButton {
            visible: showCopy
            enabled: base.enabled && selectedCount > 0; icon.width: _itemSize; icon.height: _itemSize
            icon.source: "../images/toolbar-copy.png"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("copy file(s)", "", selectedCount);
            onClicked: {
                var files = selectedFiles();
                engine.copyFiles(files);
                labelText = qsTr("%n file(s) copied", "", engine.clipboardCount);
                copyTriggered();
            }
        }
        IconButton {
            visible: showTransfer
            enabled: base.enabled && selectedCount > 0; icon.width: _itemSize; icon.height: _itemSize
            icon.source: "image://theme/icon-m-shuffle"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("transfer file(s)", "", selectedCount);
            onClicked: {
                var files = selectedFiles();
                var dialog = pageStack.push(Qt.resolvedUrl("../pages/TransferDialog.qml"),
                                            { toTransfer: files });
                dialog.accepted.connect(function() {
                    if (dialog.errorMessage === "") {
                        transferTriggered(dialog.toTransfer, dialog.targets, dialog.selectedAction, dialog.goToTarget);
                    } else {
                        errorCallback(dialog.errorMessage);
                    }
                });
            }
        }
        IconButton {
            visible: showDelete
            enabled: base.enabled && selectedCount > 0; icon.width: _itemSize; icon.height: _itemSize
            icon.source: "image://theme/icon-m-delete"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("delete file(s)", "", selectedCount);
            onClicked: { deleteTriggered(); }
        }
    }

    FileActionsRow {
        id: groupB
        tiedTo: groupA

        IconButton {
            visible: showRename
            enabled: selectedCount > 0 && selectedCount <= 20
            icon.width: _itemSize; icon.height: _itemSize
            icon.source: "../images/toolbar-rename.png"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("rename file(s)", "", selectedCount);
            onClicked: {
                var files = selectedFiles();
                var dialog = pageStack.push(Qt.resolvedUrl("../pages/RenameDialog.qml"),
                                            { 'files': files })
                dialog.accepted.connect(function() {
                    // TODO show all error messages
                    if (dialog.errorMessages.length !== 0) errorCallback(dialog.errorMessage[0]);
                    renameTriggered(files, dialog.newFiles);
                })
            }
        }
        IconButton {
            visible: showShare && sharingEnabled
            // sadly, SharePage can only handle one sole single lone and lonely orientation
            enabled: selectedCount === 1 && main.orientation === Orientation.Portrait
            icon.width: _itemSize; icon.height: _itemSize
            icon.source: "image://theme/icon-m-share"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("share file(s)", "", selectedCount);
            onClicked: {
                var files = selectedFiles();
                fileData.file = files[0];
                fileData.refresh();
                pageStack.animatorPush("Sailfish.TransferEngine.SharePage", {
                    source: Qt.resolvedUrl(files[0]),
                    mimeType: fileData.mimeType,
                    serviceFilter: ["sharing", "e-mail"]
                })
                shareTriggered();
            }
        }
        IconButton { // NOT IMPLEMENTED YET
            visible: showCompress && false
            enabled: false && selectedCount > 0; icon.width: _itemSize; icon.height: _itemSize
            icon.source: "image://theme/icon-m-file-archive-folder"
            icon.color: Theme.primaryColor
            onClicked: { compressTriggered(); }
            onPressAndHold: {
                labelText = qsTr("compress file(s)", "", selectedCount);
            }
        }
        IconButton { // NOT IMPLEMENTED YET
            visible: showEdit && false
            enabled: false && selectedCount > 0; icon.width: _itemSize; icon.height: _itemSize
            icon.source: "image://theme/icon-m-edit"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("edit file(s)", "", selectedCount);
            onClicked: { editTriggered(); }
        }
        IconButton {
            visible: showProperties
            enabled: base.enabled && selectedCount > 0
            icon.width: _itemSize; icon.height: _itemSize
            icon.source: "image://theme/icon-m-about"
            icon.color: Theme.primaryColor
            onPressAndHold: labelText = qsTr("show file properties");
            onClicked: {
                var files = selectedFiles();

                if (files.length > 1) {
                    pageStack.animatorPush(Qt.resolvedUrl("../pages/MultiFilePage.qml"), { files: files });
                } else {
                    pageStack.animatorPush(Qt.resolvedUrl("../pages/FilePage.qml"), { file: files[0] });
                }

                propertiesTriggered();
            }
        }
    }
}
