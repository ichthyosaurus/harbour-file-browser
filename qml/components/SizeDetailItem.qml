/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2019-2025 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Harbour.FileBrowser.Engine 1.0

Item {
    id: root

    property var files: []
    property int _workerHandle: Engine.requestFileSizeInfo(files)

    function refresh() {
        updateConnections.target = Engine
        _workerHandle = Engine.requestFileSizeInfo(files)
    }

    width: parent.width
    anchors.topMargin: Theme.paddingSmall
    height: sizeLabel.height+dirCountLabel.height+fileCountLabel.height

    Label {
        id: title
        text: qsTr("Size")
        anchors {
            left: parent.left
            right: parent.horizontalCenter
            rightMargin: Theme.paddingSmall
            leftMargin: Theme.horizontalPageMargin
            top: parent.top
            bottom: fileCountLabel.bottom
        }
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignTop
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeSmall
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }

    SizeDetailItemPart {
        id: sizeLabel
        anchors.top: parent.top
        text: ""
        placeholderText: qsTr("size")
    }

    SizeDetailItemPart {
        id: dirCountLabel
        anchors.top: sizeLabel.bottom
        text: ""
        placeholderText: qsTr("directories")
    }

    SizeDetailItemPart {
        id: fileCountLabel
        anchors.top: dirCountLabel.bottom
        text: ""
        placeholderText: qsTr("files")
    }

    Connections {
        id: updateConnections

        target: Engine
        onFileSizeInfoReady: {
            if (_workerHandle == handle) {
                _workerHandle = -1
                target = null

                sizeLabel.text = (info[1] === '' ? qsTr("unknown size") : info[1])

                var dirsCnt = parseInt(info[2], 10);
                if (dirsCnt > 0) {
                    dirCountLabel.text = qsTr("%n directories", "", dirsCnt);
                } else {
                    dirCountLabel.visible = false;
                    dirCountLabel.height = 0;
                }

                var filesCnt = parseInt(info[3], 10);
                if (filesCnt > 0) {
                    fileCountLabel.text = qsTr("%n file(s)", "", filesCnt);
                } else {
                    fileCountLabel.visible = false;
                    fileCountLabel.height = 0;
                }
            }
        }
    }
}
