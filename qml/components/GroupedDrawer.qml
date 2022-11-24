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

Item {
    property alias title: titleLabel.text
    property alias open: viewGroup.open
    property alias titleHeight: viewGroup.height
    property Component contents
    property alias contentItem: loader.item

    width: parent.width
    height: viewGroup.height + contentItem.height
    Behavior on height { NumberAnimation { duration: 100 } }
    clip: true

    opacity: enabled ? 1.0 : Theme.opacityLow

    BackgroundItem {
        id: viewGroup
        width: parent.width
        height: Theme.itemSizeSmall
        property bool open: false
        onClicked: open = !open

        Label {
            id: titleLabel
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: moreImage.left
                rightMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }
            text: "View"
            font.pixelSize: Theme.fontSizeLarge
            truncationMode: TruncationMode.Fade
        }

        HighlightImage {
            id: moreImage
            anchors {
                right: parent.right
                rightMargin: Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }
            source: "image://theme/icon-m-right"
            color: Theme.primaryColor
            transformOrigin: Item.Center
            rotation: viewGroup.open ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: 100 } }
        }

        Rectangle {
            anchors.fill: parent
            z: -1 // behind everything
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    Item {
        id: contentItem
        width: parent.width
        height: visible ? loader.height : 0
        visible: viewGroup.open
        anchors.top: viewGroup.bottom

        Loader {
            id: loader
            width: parent.width
            sourceComponent: contents
        }
    }
}
