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

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0

Item {
    id: base
    property bool highlighted
    property alias source: thumbnail.source
    property int size: Theme.itemSizeHuge
    width: size
    height: size

    Thumbnail {
        id: thumbnail
        width: size
        height: size
        sourceSize.width: width
        sourceSize.height: height
        priority: Thumbnail.NormalPriority

        onStatusChanged: {
            if (status === Thumbnail.Error) {
                errorLabelComponent.createObject(thumbnail)
            }
        }
    }

    Component {
        id: errorLabelComponent
        Label {
            text: qsTr("No thumbnail available")
            anchors.centerIn: parent
            width: base.width - 2 * Theme.paddingMedium
            height: base.height - 2 * Theme.paddingSmall
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            fontSizeMode: Text.Fit
        }
    }
}
