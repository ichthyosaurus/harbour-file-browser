/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
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

import "../components"
import "../js/paths.js" as Paths

Page {
    id: page
    allowedOrientations: Orientation.All
    property string path: ""

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            PageHeader { title: Paths.lastPartOfPath(page.path) }

            TextArea {
                id: portraitText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.secondaryColor
                visible: page.orientation === Orientation.Portrait ||
                         page.orientation === Orientation.PortraitInverted
                inputMethodHints: Qt.ImhNoPredictiveText
                softwareInputPanelEnabled: false
                background: null
            }
            TextArea {
                id: landscapeText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.secondaryColor
                visible: page.orientation === Orientation.Landscape ||
                         page.orientation === Orientation.LandscapeInverted
                softwareInputPanelEnabled: false
                inputMethodHints: Qt.ImhNoPredictiveText
                background: null
            }
            Spacer {
                height: 2*Theme.paddingLarge
                visible: message.text !== ""
            }
            Label {
                id: message
                width: parent.width
                wrapMode: Text.Wrap
                // show medium size if there is no portrait (or landscape text)
                // in that case, this message becomes main message
                font.pixelSize: portraitText.text === "" ? Theme.fontSizeMedium : Theme.fontSizeTiny
                color: portraitText.text === "" ? Theme.highlightColor : Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter
                visible: message.text !== ""
            }
            Spacer {
                height: 2*Theme.paddingLarge
                visible: message.text !== ""
            }
        }
    }

    // update cover
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            coverText = Paths.lastPartOfPath(page.path);
            // reading file returns three texts, message, portrait and landscape texts
            var txts = engine.readFile(page.path);
            message.text = txts[0] === "" ? "" : "⸻ %1 ⸻".arg(txts[0]);
            portraitText.text = txts[1];
            landscapeText.text = txts[2];
        }
    }
}


