/*
 * This file was taken and adapted from harbour-fotokopierer
 * by Frank Fischer, released under the GNU GPL v3+.
 * Original source can be found under
 * <https://chiselapp.com/user/fifr/repository/fotokopierer>.
 *
 * Copyright (c) 2018  Frank Fischer <frank-fischer@shadow-soft.de>
 *               2019  Mirian Margiani <mirian@margiani.ch>
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see  <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    Drag.active: mouseArea.drag.active
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    property real radius: 10
    property color color: Theme.highlightBackgroundColor

    property point center: Qt.point(x + 3*radius, y + 3*radius)
    property int initialCenterX
    property int initialCenterY
    property real minX
    property real maxX
    property real minY
    property real maxY

    property bool dragActive: false
    property bool beHCenter: false
    property bool beVCenter: false

    x: initialCenterX - 3*radius
    y: initialCenterY - 3*radius
    width: radius * 6
    height: radius * 6

    function reset() {
        x = Qt.binding(function() {return initialCenterX - 3*radius; })
        y = Qt.binding(function() {return initialCenterY - 3*radius; })
    }

    Rectangle {
        id: rectangle
        anchors.centerIn: parent
        width: (beHCenter ? parent.radius/2 : parent.radius*2)
        height: (beVCenter ? parent.radius/2 : parent.radius*2)
        antialiasing: false
        color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
        border.color: Theme.highlightColor
        border.width: 2
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        drag.target: parent
        drag.minimumX: root.minX-2*radius
        drag.maximumX: root.maxX-2*radius
        drag.minimumY: root.minY-2*radius
        drag.maximumY: root.maxY-2*radius

        onPressed: dragActive = true
        onReleased: dragActive = false
    }
}
