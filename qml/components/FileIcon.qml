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

// a file icon or thumbnail for directory listings
Item {
    id: base
    property string file: ""
    property bool showThumbnail: false
    property bool highlighted: false
    property bool isDirectory: false
    property var mimeTypeCallback
    property var fileIconCallback

    Component.onCompleted: refresh();
    onShowThumbnailChanged: refresh();

    property bool ready: false
    property int _thumbnailSize: base.width
    property string _cachedMimeType: ""

    function refresh() {
        ready = false;
        var canThumb = true;

        if (showThumbnail) {
            if (isDirectory) {
                canThumb = false
            } else if (mimeTypeCallback !== undefined) {
                var mimeType = mimeTypeCallback();
                _cachedMimeType = mimeType;

                if (   mimeType.indexOf("image/") === -1
                    && mimeType.indexOf("video/") === -1
                    && mimeType.indexOf("application/pdf") === -1
                   ) {
                    canThumb = false
                }
            }
            showThumbnail = canThumb;
        }

        if (showThumbnail) {
            listIcon.source = "";
            listIcon.setSource("../components/SailfishThumbnail.qml", {
                source: base.file,
                size: _thumbnailSize,
                mimeType: _cachedMimeType,
            });
        } else {
            if (fileIconCallback === undefined) return;
            thumbnail.source = ""
            var qmlIcon = Theme.lightPrimaryColor ? "../components/HighlightImageSF3.qml"
                                              : "../components/HighlightImageSF2.qml";
            listIcon.setSource(qmlIcon, {
                imgsrc: "../images/"+(canThumb ? "large" : "small")+"-"+fileIconCallback()+".png",
                imgw: _thumbnailSize,
                imgh: _thumbnailSize,
            });
        }
    }

    Rectangle {
        id: rect
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Theme.rgba(Theme.secondaryColor, Theme.highlightBackgroundOpacity)
        visible: !ready
    }

    Loader {
        id: listIcon
        anchors.fill: parent
        asynchronous: true
        property alias highlighted: base.highlighted
        onHighlightedChanged: if (status === Loader.Ready) item.highlighted = base.highlighted
        onLoaded: if (!showThumbnail) ready = true;
    }

    Loader {
        id: thumbnail
        anchors.fill: parent
        property alias highlighted: base.highlighted
        onHighlightedChanged: if (status === Loader.Ready) item.highlighted = base.highlighted
        onLoaded: if (showThumbnail) ready = true;
    }
}
