/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019 Kari Pihkala
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
import "../components"

Dialog {
    property variant files: [] // this must be set to a string list, e.g. [ "file1", "file2" ]
    property string dir: ""

    id: dialog
    allowedOrientations: Orientation.All

    SilicaListView {
        id: overwriteFileList
        anchors.fill: parent
        anchors.bottomMargin: 0
        clip: true

        model: files

        VerticalScrollDecorator { flickable: overwriteFileList }

        header: Item {
            width: parent.width
            height: dialogHeader.height + dialogLabel.height + 2*Theme.paddingLarge

            DialogHeader {
                id: dialogHeader
                title: qsTr("Replace?")
                acceptText: qsTr("Replace")
            }
            Label {
                id: dialogLabel
                text: dir !== "" ? qsTr("These files or folders already exist in “%1”:").arg(dir) :
                                   qsTr("These files or folders already exist:")
                wrapMode: Text.Wrap
                anchors.top: dialogHeader.bottom
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                color: Theme.highlightColor
            }
        }

        delegate: Item {
            id: fileItem
            width: ListView.view.width
            height: listLabel.height

            Label {
                id: listLabel
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                text: modelData
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.primaryColor
            }
        }
    }
}
