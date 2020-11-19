/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014, 2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
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

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileData 1.0
import "../components"

Dialog {
    property string path: ""

    // return value
    property string errorMessage: ""

    id: dialog
    allowedOrientations: Orientation.All

    property int _executeWidth: executeLabel.width

    onAccepted: errorMessage = engine.chmod(path,
                        ownerRead.checked, ownerWrite.checked, ownerExecute.checked,
                        groupRead.checked, groupWrite.checked, groupExecute.checked,
                        othersRead.checked, othersWrite.checked, othersExecute.checked);

    FileData {
        id: fileData
        file: path
    }

    // copy values to fields when page shows up
    Component.onCompleted: {
        ownerName.text = fileData.owner
        groupName.text = fileData.group
        var permissions = fileData.permissions
        if (permissions.charAt(0) !== '-') ownerRead.checked = true;
        if (permissions.charAt(1) !== '-') ownerWrite.checked = true;
        if (permissions.charAt(2) !== '-') ownerExecute.checked = true;
        if (permissions.charAt(3) !== '-') groupRead.checked = true;
        if (permissions.charAt(4) !== '-') groupWrite.checked = true;
        if (permissions.charAt(5) !== '-') groupExecute.checked = true;
        if (permissions.charAt(6) !== '-') othersRead.checked = true;
        if (permissions.charAt(7) !== '-') othersWrite.checked = true;
        if (permissions.charAt(8) !== '-') othersExecute.checked = true;
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            DialogHeader {
                id: dialogHeader
                acceptText: qsTr("Change")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("Change permissions for\n%1").arg(path)
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
            }

            Spacer {
                height: 2*Theme.paddingLarge
            }

            // read, write, execute small labels
            Row {
                width: parent.width
                Label {
                    width: parent.width/2
                    text: " "
                }

                Label {
                    id: readLabel
                    width: executeLabel.width
                    text: qsTr("Read")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    id: writeLabel
                    width: executeLabel.width
                    text: qsTr("Write")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    id: executeLabel
                    text: qsTr("Execute")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // owner
            Row {
                width: parent.width
                Column {
                    width: parent.width/2
                    Label {
                        id: ownerName
                        width: parent.width - Theme.paddingLarge
                        text: ""
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignRight
                    }
                    Label {
                        width: parent.width - Theme.paddingLarge
                        text: qsTr("Owner")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        horizontalAlignment: Text.AlignRight
                    }
                }
                LetterSwitch {
                    id: ownerRead
                    width: _executeWidth
                    letter: 'r'
                }
                LetterSwitch {
                    id: ownerWrite
                    width: _executeWidth
                    letter: 'w'
                }
                LetterSwitch {
                    id: ownerExecute
                    width: _executeWidth
                    letter: 'x'
                }
            }

            // group
            Row {
                id: groupRow
                width: parent.width
                Column {
                    width: parent.width/2
                    Label {
                        id: groupName
                        width: parent.width - Theme.paddingLarge
                        text: ""
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignRight
                    }
                    Label {
                        width: parent.width - Theme.paddingLarge
                        text: qsTr("Group")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        horizontalAlignment: Text.AlignRight
                    }
                }
                LetterSwitch {
                    id: groupRead
                    width: _executeWidth
                    letter: 'r'
                }
                LetterSwitch {
                    id: groupWrite
                    width: _executeWidth
                    letter: 'w'
                }
                LetterSwitch {
                    id: groupExecute
                    width: _executeWidth
                    letter: 'x'
                }
            }

            // others
            Row {
                width: parent.width
                height: groupRow.height
                Item {
                    width: parent.width/2
                    height: parent.height
                    Label {
                        width: parent.width - Theme.paddingLarge
                        height: parent.height
                        text: qsTr("Others")
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                LetterSwitch {
                    id: othersRead
                    width: _executeWidth
                    letter: 'r'
                }
                LetterSwitch {
                    id: othersWrite
                    width: _executeWidth
                    letter: 'w'
                }
                LetterSwitch {
                    id: othersExecute
                    width: _executeWidth
                    letter: 'x'
                }
            }
        }
    }
}


