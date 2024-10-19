//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

IconButton {
    id: root

    property int size: Theme.iconSizeMedium
    property int grow: Theme.paddingLarge

    property color color: Theme.lightPrimaryColor
    property color highlightColor: Theme.colorScheme === Theme.LightOnDark ?
        Theme.highlightColor : Qt.lighter(Theme.highlightColor, 2)

    readonly property color _activeColor: highlighted ?
        icon.highlightColor : icon.color

    width: size + 2*grow
    height: width

    icon {
        width: size
        height: size
        color: root.color
        highlightColor: root.highlightColor
    }

    Rectangle {
        z: -1
        anchors.fill: parent
        color: Theme.rgba("black", Theme.opacityLow)
        radius: width / 2
        border.color: _activeColor
        border.width: 2
    }
}
