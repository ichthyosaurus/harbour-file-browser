/*
 * This file is part of File Browser.
 *
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

Item {
    id: overlay
    z: 100
    anchors.fill: parent
    property alias title: titleLabel.text

    property bool shown: false
    opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
    Behavior on opacity { NumberAnimation { duration: 80 } }

    function show() { shown = true; }
    function hide() { shown = false; }

    Rectangle {
        anchors.top: parent.top
        height: Theme.itemSizeLarge
        width: parent.width

        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.5) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        Label {
            id: titleLabel
            anchors.fill: parent
            anchors.margins: Theme.horizontalPageMargin
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            truncationMode: TruncationMode.Fade
            horizontalAlignment: Text.AlignRight
        }
    }
}
