/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2019-2020 Kari Pihkala
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

// This component blocks all components under it and displays a dark background
Rectangle {
    id: interactionBlocker

    // clicked signal is emitted when the component is clicked
    signal clicked

    visible: false
    color: Theme.overlayBackgroundColor ? Theme.overlayBackgroundColor : "black"
    opacity: 0.4

    MouseArea {
        anchors.fill: parent
        enabled: true
        onClicked: interactionBlocker.clicked()
    }
    // use a timer to delay the visibility of interaction blocker by adjusting opacity
    // this is done to prevent flashing if the file operation is fast
    onVisibleChanged: {
        if (visible === true) {
            interactionBlocker.opacity = 0;
            blockerTimer.start();
        } else {
            blockerTimer.stop();
        }
    }
    Timer {
        id: blockerTimer
        interval: 300
        onTriggered: {
            interactionBlocker.opacity = 0.3;
            stop();
        }
    }
}
