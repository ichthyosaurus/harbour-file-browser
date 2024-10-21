/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0

SilicaItem {
    id: root
    property string file
    property var mimeTypeCallback: null

    readonly property bool _haveThumbnail:
        thumbnailLoader.status !== Loader.Error &&
        thumbnailLoader.item.status !== Thumbnail.Error

    height: _haveThumbnail ?
        Math.max(thumbnailLoader.height,
                 Theme.itemSizeExtraLarge) :
        Theme.itemSizeExtraLarge

    Loader {
        id: thumbnailLoader

        sourceComponent: Component {
            Thumbnail {
                source: file
                opacity: highlighted ? Theme.opacityLow : 1.0
                width: Math.min(Screen.width, Screen.height)
                height: width
                fillMode: Thumbnail.PreserveAspectFit
                mimeType: !!file && mimeTypeCallback instanceof Function ?
                              mimeTypeCallback() : ""
                sourceSize.width: width
                sourceSize.height: height
                priority: Thumbnail.NormalPriority
            }
        }
    }

    Rectangle {
        anchors {
            fill: playButton
            margins: -Theme.paddingLarge
        }

        radius: width
        color: {
            if (highlighted) {
                Theme.rgba(Theme.highlightDimmerColor, Theme.opacityLow)
            } else if (_haveThumbnail) {
                Theme.rgba(Theme.darkPrimaryColor, Theme.opacityLow)
            } else {
                Theme.rgba(Theme.primaryColor, Theme.opacityFaint)
            }
        }

        border.width: 2
        border.color: {
            if (highlighted) {
                Theme.secondaryHighlightColor
            } else if (_haveThumbnail) {
                Theme.lightSecondaryColor
            } else {
                Theme.secondaryColor
            }
        }
    }

    HighlightImage {
        id: playButton
        anchors.centerIn: parent
        source: "../../modules/Opal/MediaPlayer/private/images/icon-m-play.png"
        color: _haveThumbnail ?
            Theme.lightPrimaryColor :
            Theme.primaryColor
    }
}
