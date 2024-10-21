/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2019-2023 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.file.browser.Settings 1.0

import "../js/paths.js" as Paths

Row {
    id: root
    spacing: Theme.paddingMedium

    property string path
    property bool active: visible
    readonly property var diskSpaceInfo: _diskSpaceInfo

    property int _diskSpaceHandle: -1
    property var _diskSpaceInfo: ['']

    onActiveChanged: {
        if (active) {
            _diskSpaceHandle = engine.requestDiskSpaceInfo(path)
        }
    }

    Component.onCompleted: {
        if (active) {
            _diskSpaceHandle = engine.requestDiskSpaceInfo(path)
        }
    }

    Connections {
        target: active ? engine : null
        onDiskSpaceInfoReady: {
            if (_diskSpaceHandle == handle) {
                _diskSpaceHandle = -1

                /* debugDelayer.info = info
                debugDelayer.start() */
                _diskSpaceInfo = info
            }
        }
    }

    /* Timer {
        id: debugDelayer
        property var info
        onTriggered: _diskSpaceInfo = info
        interval: 2000
    } */

    Rectangle {
        width: parent.width - calculating.width
        height: Theme.paddingSmall
        anchors.verticalCenter: calculating.verticalCenter
        color: Theme.rgba(highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor,
                          Theme.opacityFaint)
        radius: 50

        Rectangle {
            anchors.left: parent.left
            width: parent.width / 100 * parseInt(_diskSpaceInfo[1], 10)
            Behavior on width { NumberAnimation { duration: 200 } }
            height: parent.height
            color: Theme.rgba(highlighted ? Theme.highlightColor : Theme.primaryColor,
                              Theme.opacityLow)
            radius: 50
        }
    }

    Row {
        id: calculating

        BusyIndicator {
            size: BusyIndicatorSize.ExtraSmall
            visible: _diskSpaceInfo[0] === ''
            running: visible
        }

        Label {
            visible: _diskSpaceInfo[0] !== ''
            text: qsTr("%1 free").arg(_diskSpaceInfo[3])
            font.pixelSize: Theme.fontSizeExtraSmall
            color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
}
