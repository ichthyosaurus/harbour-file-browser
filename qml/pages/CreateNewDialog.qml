/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014, 2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2020-2022 Mirian Margiani
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

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileData 1.0
import "../components"

Dialog {
    id: root

    property string path: "/"  // parent directory of the new entry
    property string errorMessage: ""  // return value

    allowedOrientations: Orientation.All
    canAccept: parentData.isWritable && folderName.text !== "" && !folderName.errorHighlight

    onAccepted: {
        errorMessage = _createFolder ?
                    engine.createDirectory(path, folderName.text) :
                    engine.createFile(path, folderName.text)
    }

    property bool _createFolder: typeCombo.currentIndex == 0

    FileData {
        id: parentData
        file: root.path
    }

    FileData {
        id: fileData
        file: root.path + '/' + folderName.text
    }

    DialogHeader {
        id: dialogHeader
        acceptText: qsTr("Create")
    }

    SilicaFlickable {
        id: flickable
        anchors {
            top: dialogHeader.bottom
            left: parent.left; right: parent.right
            bottom: parent.bottom
        }
        clip: true
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        ViewPlaceholder {
            enabled: !parentData.isWritable
            text: qsTr("Not permitted")
            hintText: qsTr("You don't have permission to change the contents of this directory.")
        }

        Column {
            id: column
            visible: parentData.isWritable
            anchors {
                left: parent.left
                right: parent.right
            }

            ComboBox {
                id: typeCombo
                label: qsTr("Create new")
                description: (currentIndex == 0 ?
                                 qsTr("The new folder will be created under “%1”") :
                                 qsTr("The new text file will be created under “%1” and can be edited later.")
                              ).arg(path + (path != "/" ? "/" : ""))
                onCurrentItemChanged: folderName.forceActiveFocus()
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("folder")
                    }
                    MenuItem {
                        text: qsTr("empty text file")
                    }
                }
            }

            Spacer {
                height: Theme.paddingLarge
            }

            TextField {
                id: folderName
                width: parent.width
                label: _createFolder ? qsTr("Folder name") : qsTr("File name")
                placeholderText: label
                focus: true
                text: ""
                errorHighlight: text !== "" && (engine.exists(path + "/" + text) || (!_createFolder && text.indexOf('/') >= 0))
                EnterKey.enabled: folderName.text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: root.accept()
            }

            Label {
                anchors {
                    left: parent.left; leftMargin: folderName.textLeftMargin
                    right: parent.right; rightMargin: folderName.textRightMargin
                }

                text: {
                    if (folderName.errorHighlight) {
                        if (!_createFolder && folderName.text.indexOf('/') >= 0) {
                            return qsTr("File names must not contain slashes. " +
                                        "To create a new file in a folder below “%1”, " +
                                        "first create a folder and then create the file.").arg(parentData.file)
                        } else {
                            return qsTr("A file or folder with this name already exists.")
                        }
                    } else if (folderName.text.indexOf('/') >= 0){
                        var a = qsTr("Using slashes in folder names will create sub-folders, like so:")
                        var b = '\t' + parentData.file + '/\n'
                        var split = fileData.file.slice(path.length + 1).split('/')

                        for (var i in split) {
                            if (split[i] === '') continue

                            b += '\t└'
                            for (var j = 1; j <= i; j++) {
                                b += '─'
                            }
                            b += ' ' + split[i] + '/\n'
                        }

                        return a + '\n\n' + b.slice(0, b.length-2)
                    } else {
                        return ''
                    }
                }
                color: palette.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                opacity: text.length > 0 ? 1.0 : 0.0
                height: text.length > 0 ? implicitHeight : 0

                Behavior on opacity { FadeAnimator {}}
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
            }
        }
    }
}


