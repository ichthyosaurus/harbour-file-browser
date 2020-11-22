/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014, 2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2020 Mirian Margiani
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

// This component displays a list of options on top of a page.
Item {
    id: item
    property int menuTop: Theme.itemSizeMedium

    property string _selectedMenu: ""
    property Item _contextMenu

    function show() {
        if (!_contextMenu) _contextMenu = contextMenuComponent.createObject(rect);
        _selectedMenu = "";
        _contextMenu.open(rect);
    }

    on_SelectedMenuChanged: {
        if (_selectedMenu != "" && _contextMenu) _contextMenu.close();
    }

    Column {
        anchors.fill: parent
        Spacer { height: menuTop }
        // background rectangle for context menu so it covers underlying items
        Rectangle {
            id: rect
            color: "transparent"
//            opacity: Theme.highlightBackgroundOpacity
            width: parent.width
            height: _contextMenu ? _contextMenu.height : 0
        }
    }

    Component {
        id: contextMenuComponent
        ContextMenu {
            // delayed action so that menu has already closed when page transition happens
            onClosed: {
                if (_selectedMenu === "back") {
                    console.log("BACK requested")
                } else if (_selectedMenu === "up") {
                    console.log("UP requested")
                } else if (_selectedMenu === "forward") {
                    console.log("FORWARD requested")
                } else if (_selectedMenu === "editPath") {
                    console.log("EDIT PATH requested")
                } else if (_selectedMenu === "showHidden") {
                    console.log("SHOW HIDDEN requested")
                }
                _selectedMenu = "";
            }

            Row {
                anchors { left: parent.left; right: parent.right }
                height: normalMenuItem.height
                BackgroundItem {
                    width: parent.width/3
                    contentHeight: parent.height
                    Label { text: qsTr("<"); anchors.centerIn: parent; highlighted: parent.highlighted }
                    onClicked: _selectedMenu = "back"
                }
                BackgroundItem {
                    width: parent.width/3
                    contentHeight: parent.height
                    Label { text: qsTr("^"); anchors.centerIn: parent; highlighted: parent.highlighted }
                    onClicked: _selectedMenu = "up"
                }
                BackgroundItem {
                    width: parent.width/3
                    contentHeight: parent.height
                    Label { text: qsTr(">"); anchors.centerIn: parent; highlighted: parent.highlighted }
                    onClicked: _selectedMenu = "forward"
                }
            }

            MenuItem {
                text: qsTr("Show hidden files")
                onClicked: _selectedMenu = "showHidden"
            }
            MenuItem {
                id: normalMenuItem
                text: qsTr("Edit path")
                onClicked: _selectedMenu = "editPath"
            }
        }
    }
}
