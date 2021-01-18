/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014 Kari Pihkala
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

// This component is a toggle switch, which displays a letter or a dash '-'
BackgroundItem {
    id: bgItem

    // checked status of the switch
    property bool checked: false

    // letter to be displayed
    property string letter: ""

    height: parent.height

    Label {
        id: label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: checked ? letter : "-"
        color: bgItem.highlighted ? Theme.highlightColor : Theme.primaryColor
    }

    onClicked: checked = !checked
}
