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

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: parent.width
    anchors.topMargin: Theme.paddingSmall
    height: sizeLabel.height+dirCountLabel.height+fileCountLabel.height

    property var files: []

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

    // TODO load size info asynchronously
    Component.onCompleted: {
        var sizes = engine.fileSizeInfo(files);
        sizeLabel.text = (sizes[0] === "-" ? qsTr("unknown size") : sizes[0]);

        var dirsCnt = parseInt(sizes[1], 10);
        if (dirsCnt > 0) {
            dirCountLabel.text = qsTr("%n directories", "", dirsCnt);
        } else {
            dirCountLabel.visible = false;
            dirCountLabel.height = 0;
        }

        var filesCnt = parseInt(sizes[2], 10);
        if (filesCnt > 0) {
            fileCountLabel.text = qsTr("%n file(s)", "", filesCnt);
        } else {
            fileCountLabel.visible = false;
            fileCountLabel.height = 0;
        }
    }
}
