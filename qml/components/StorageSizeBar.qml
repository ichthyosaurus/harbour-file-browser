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
    id: sizeInfo
    spacing: Theme.paddingMedium

    property int diskSpaceHandle: -1
    property var diskSpaceInfo: ['']

    onVisibleChanged: {
        if (visible) {
            diskSpaceHandle = engine.requestDiskSpaceInfo(model.path)
        }
    }

    Component.onCompleted: {
        if (model.showSize) {
            diskSpaceHandle = engine.requestDiskSpaceInfo(model.path)
        }
    }

    Connections {
        target: model.showSize ? engine : null
        onDiskSpaceInfoReady: {
            if (sizeInfo.diskSpaceHandle == handle) {
                sizeInfo.diskSpaceHandle = -1

                /* debugDelayer.info = info
                            debugDelayer.start() */
                sizeInfo.diskSpaceInfo = info
            }
        }
    }

    /* Timer {
                    id: debugDelayer
                    property var info
                    onTriggered: sizeInfo.diskSpaceInfo = info
                    interval: 2000
                } */

    Rectangle {
        width: parent.width - calculating.width
        height: Theme.paddingSmall
        anchors.verticalCenter: calculating.verticalCenter
        color: Theme.rgba(highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor,
                          Theme.opacityLow)
        radius: 50

        Rectangle {
            anchors.left: parent.left
            width: parent.width / 100 * parseInt(sizeInfo.diskSpaceInfo[1], 10)
            Behavior on width { NumberAnimation { duration: 200 } }
            height: parent.height
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
            radius: 50
        }
    }

    Row {
        id: calculating

        BusyIndicator {
            size: BusyIndicatorSize.ExtraSmall
            visible: sizeInfo.diskSpaceInfo[0] === ''
            running: visible
        }

        Label {
            visible: sizeInfo.diskSpaceInfo[0] !== ''
            text: qsTr("%1 free").arg(sizeInfo.diskSpaceInfo[3])
            font.pixelSize: Theme.fontSizeExtraSmall
            color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
}
