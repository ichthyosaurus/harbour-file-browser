//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2020-2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later OR AGPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property alias title: _titleLabel.text
    property bool shown: false

    property alias titleItem: _titleLabel

    function show() { shown = true }
    function hide() { shown = false }

    z: 100
    anchors.fill: parent
    opacity: shown ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 80
        }
    }

    Rectangle {
        anchors.top: parent.top
        height: Math.max(Theme.itemSizeLarge,
                         _titleLabel.height
                         + 2*Theme.horizontalPageMargin
                         + Theme.paddingMedium)
        width: parent.width

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.4)
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }

        Label {
            id: _titleLabel
            anchors {
                top: parent.top
                margins: Theme.horizontalPageMargin
                left: parent.left
                right: parent.right
            }
            color: Theme.lightPrimaryColor
            font.pixelSize: Theme.fontSizeLarge
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.fontSizeSmall
            truncationMode: TruncationMode.Fade
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
