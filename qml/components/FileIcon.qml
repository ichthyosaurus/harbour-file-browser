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
import Nemo.Thumbnailer 1.0

// a file icon or thumbnail for directory listings
Item {
    property string file: ""
    property bool showThumbnail: false
    property bool highlighted: false
    property bool isDirectory: false
    property var mimeTypeCallback
    property var fileIconCallback

    property int _thumbnailSize: width
    property bool _doShowThumbnail: showThumbnail && !isDirectory

    Thumbnail {
        id: thumbnailImage
        source: _doShowThumbnail ? file : ""
        mimeType: source !== "" ? mimeTypeCallback() : ""
        width: _thumbnailSize
        height: width
        sourceSize.width: width
        sourceSize.height: height
        priority: Thumbnail.NormalPriority

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Theme.rgba(Theme.secondaryColor, Theme.highlightBackgroundOpacity)
            visible: parent.status === Thumbnail.Loading
        }
    }

    HighlightImage { // not available in Sailfish 2
        color: Theme.primaryColor
        source: (!_doShowThumbnail || thumbnailImage.status === Thumbnail.Error) ?
                    "../images/large-"+fileIconCallback()+".png" : ""
        width: _thumbnailSize
        height: width
        highlighted: parent.highlighted
        asynchronous: true
    }
}
