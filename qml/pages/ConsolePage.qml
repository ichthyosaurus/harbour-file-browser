/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
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
import harbour.file.browser.ConsoleModel 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string title: ""
    property string command: ""
    property variant arguments // this must be set to a string list, e.g. [ "arg1", "arg2" ]
    property color consoleColor: Theme.secondaryColor

    // execute command when page activates
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            consoleModel.executeCommand(page.command, page.arguments);
        }
    }

    ConsoleModel {
        id: consoleModel
    }

    PageHeader {
        id: header
        title: page.title
    }

    // display console text as a list, it is much faster compared to a Text item
    SilicaFlickable {
        id: horizontalFlick
        flickableDirection: "HorizontalFlick"
        contentWidth: itemList.contentWidth
        HorizontalScrollDecorator { flickable: horizontalFlick }
        clip: true

        anchors {
            top: header.bottom
            topMargin: Theme.paddingMedium
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        SilicaListView {
            id: itemList
            anchors.fill: parent
            model: consoleModel
            footer: Spacer { height: Theme.horizontalPageMargin }

            VerticalScrollDecorator {
                visible: horizontalFlick.contentWidth > horizontalFlick.width
                anchors.right: undefined // places scrollbar on the left
                flickable: itemList
            }

            VerticalScrollDecorator { flickable: itemList }

            delegate: Item {
                id: listItem
                width: ListView.view.width
                height: listLabel.height-24

                Text {
                    id: listLabel
                    x: Theme.horizontalPageMargin
                    text: modelData
                    textFormat: Text.PlainText
                    color: page.consoleColor
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeTiny
                    font.family: "Monospace"
                    Component.onCompleted: {
                        if ((width+2*x) > horizontalFlick.contentWidth) {
                            horizontalFlick.contentWidth = width+2*x;
                        }
                    }
                }
            }
        }
    }
}
