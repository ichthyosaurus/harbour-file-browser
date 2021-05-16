/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020-2021 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later OR AGPL-3.0-or-later
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: overlay
    z: 100
    anchors.fill: parent
    property alias title: _titleLabel.text
    property alias subtitle: _subtitleLabel.text
    property alias titleItem: _titleLabel
    property alias subtitleItem: _subtitleLabel

    property bool shown: false
    opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
    Behavior on opacity { NumberAnimation { duration: 80 } }

    function show() { shown = true; }
    function hide() { shown = false; }

    Rectangle {
        anchors.top: parent.top
        height: Math.max(Theme.itemSizeLarge,
                         _titleLabel.height+_subtitleLabel.height +
                         2*Theme.horizontalPageMargin +
                         Theme.paddingMedium)
        width: parent.width

        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.5) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        Label {
            id: _titleLabel
            anchors {
                top: parent.top
                margins: Theme.horizontalPageMargin
                left: parent.left
                right: parent.right
            }
            color: Theme.highlightColor
            font.pixelSize: subtitle === '' ? Theme.fontSizeLarge :
                                              Theme.fontSizeMedium
            elide: Text.ElideNone
            truncationMode: TruncationMode.Fade
            horizontalAlignment: Text.AlignRight
        }

        Label {
            id: _subtitleLabel
            anchors {
                top: _titleLabel.baseline
                topMargin: Theme.paddingMedium
                left: _titleLabel.left
                right: _titleLabel.right
            }
            color: _titleLabel.color
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideNone
            truncationMode: TruncationMode.Fade
            horizontalAlignment: Text.AlignRight
        }
    }
}
