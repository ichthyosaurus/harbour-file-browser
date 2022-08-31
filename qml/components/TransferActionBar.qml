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
import harbour.file.browser.Settings 1.0

Item {
    id: action
    property string selection: ""

    Row {
        anchors.fill: parent

        BackgroundItem {
            id: first
            width: parent.width / 3
            contentHeight: parent.height
            _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)

            Label { text: qsTr("Copy");  anchors.centerIn: parent; color: first.highlighted ? Theme.highlightColor : Theme.primaryColor }

            onClicked: action.selection = "copy"
            highlighted: action.selection === "copy"
        }
        BackgroundItem {
            id: second
            width: parent.width / 3
            contentHeight: parent.height
            _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)

            Label { text: qsTr("Move");  anchors.centerIn: parent; color: second.highlighted ? Theme.highlightColor : Theme.primaryColor }

            onClicked: action.selection = "move"
            highlighted: action.selection === "move"
        }
        BackgroundItem {
            id: third
            width: parent.width / 3
            contentHeight: parent.height
            _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)

            Label { text: qsTr("Link");  anchors.centerIn: parent; color: third.highlighted ? Theme.highlightColor : Theme.primaryColor }

            onClicked: action.selection = "link"
            highlighted: action.selection === "link"
        }
    }

    DirectorySettings { id: prefs; path: "" }

    Component.onCompleted: {
        var defTransfer = prefs.transferDefaultAction
        action.selection = (defTransfer === "none" ? "" : defTransfer)
    }
}
