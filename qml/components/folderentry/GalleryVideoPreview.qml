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
    property alias file: thumbnail.source

    readonly property bool _haveThumbnail: thumbnail.status !== Thumbnail.Error

    height: _haveThumbnail ? thumbnail.height : Theme.itemSizeExtraLarge
    palette.colorScheme: _haveThumbnail ? Theme.LightOnDark : Theme.colorScheme

    Thumbnail {
        id: thumbnail
        opacity: highlighted ? Theme.opacityLow : 1.0
        width: Math.min(Screen.width, Screen.height)
        height: width
        sourceSize.width: width
        sourceSize.height: height
        priority: Thumbnail.NormalPriority
    }

    Rectangle {
        anchors {
            fill: playButton
            margins: -Theme.paddingLarge
        }
        radius: width
        color: {
            if (highlighted) {
                Theme.rgba(palette.highlightDimmerColor, Theme.opacityLow)
            } else if (palette.colorScheme === Theme.LightOnDark) {
                Theme.rgba(Theme.darkPrimaryColor, Theme.opacityFaint)
            } else {
                Theme.rgba(Theme.lightPrimaryColor, Theme.opacityFaint)
            }
        }
        border.color: highlighted ?
            palette.secondaryHighlightColor :
            palette.secondaryColor
        border.width: 2
    }

    HighlightImage {
        id: playButton
        anchors.centerIn: parent
        source: "../../modules/Opal/MediaPlayer/private/images/icon-m-play.png"
        color: palette.primaryColor
    }
}
