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
    property string fallbackFile: ""
    property bool _commandFailed: false

    // execute command when page activates
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            _commandFailed = false;
            consoleModel.executeCommand(page.command, page.arguments);
        } else if (_commandFailed && status === PageStatus.Active && !canNavigateForward) {
            pageStack.pushAttached(Qt.resolvedUrl("ViewPage.qml"), { path: fallbackFile })
        }
    }

    on_CommandFailedChanged: {
        if (_commandFailed && status === PageStatus.Active && !canNavigateForward) {
            pageStack.pushAttached(Qt.resolvedUrl("ViewPage.qml"), { path: fallbackFile })
        }
    }

    ConsoleModel {
        id: consoleModel
        onProcessExited: {
            if (exitCode === 0) {
                _commandFailed = false;
                return;
            } else if (exitCode === -88888) {
                console.log("console: command '%1' probably not found (code %2)".arg(command).arg(exitCode))
            } else if (exitCode === -99999) {
                console.log("console: command '%1' crashed (code %2)".arg(command).arg(exitCode))
            } else {
                console.log("console: command '%1' exited with code %2".arg(command).arg(exitCode))
            }
            _commandFailed = true;
        }
    }

    PageHeader {
        id: header
        title: page.title
    }

    Label {
        visible: _commandFailed
        anchors {
            bottom: parent.bottom; bottomMargin: 2*Theme.horizontalPageMargin
            left: parent.left; leftMargin: Theme.horizontalPageMargin
            right: parent.right; rightMargin: Theme.horizontalPageMargin
        }
        height: Theme.itemSizeLarge
        verticalAlignment: Text.AlignBottom
        truncationMode: TruncationMode.None
        wrapMode: Text.WordWrap
        text: qsTr("Swipe right to view raw contents.")
        color: Theme.secondaryHighlightColor
    }

    // display console text as a list, it is much faster compared to a Text item
    SilicaFlickable {
        id: horizontalFlick
        flickableDirection: "HorizontalFlick"
        contentWidth: itemList.contentWidth
        HorizontalScrollDecorator { flickable: horizontalFlick }

        anchors {
            left: parent.left; right: parent.right
            top: parent.top; topMargin: header.height+Theme.paddingMedium
            bottom: parent.bottom
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
                    elide: Text.ElideNone
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
