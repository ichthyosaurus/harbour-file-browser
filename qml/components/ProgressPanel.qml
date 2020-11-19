/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014, 2019 Kari Pihkala
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

// This component displays a progress panel at top of page and blocks all interactions under it
Item {
    id: progressPanel
    anchors.fill: parent

    // reference to page to prevent back navigation (required)
    property Item page
    property bool blockNavigation: true

    // large text displayed on panel
    property string headerText: ""

    // small text displayed on panel
    property string text: ""

    // open status of the panel
    property alias open: dockedPanel.open

    // shows the panel
    function showText(txt) {
        headerText = txt;
        text = "";
        dockedPanel.show();
    }

    // hides the panel
    function hide() {
        dockedPanel.hide();
    }

    // cancelled signal is emitted when user presses the cancel button
    signal cancelled


    //// internal

    InteractionBlocker {
        anchors.fill: parent
        visible: dockedPanel.open
    }

    DockedPanel {
        id: dockedPanel

        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge

        dock: Dock.Top
        open: false
        onOpenChanged: {
            if (blockNavigation) {
                // disable all page navigation
                page.backNavigation = !open;
                page.forwardNavigation = !open;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.overlayBackgroundColor ? Theme.overlayBackgroundColor : "black"
            opacity: 0.7
        }
        BusyIndicator {
            id: progressBusy
            anchors.right: progressHeader.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter
            running: true
            size: BusyIndicatorSize.Small
        }
        Rectangle {
            id: cancelButton
            anchors.right: parent.right
            width: Theme.itemSizeMedium
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: cancelMouseArea.pressed ? Theme.secondaryHighlightColor : "transparent"

            IconButton {
                id: cancelMouseArea
                anchors.fill: parent
                enabled: true; icon.width: Theme.iconSizeMedium; icon.height: Theme.iconSizeMedium
                icon.source: "image://theme/icon-m-clear"
                onClicked: cancelled();
            }
        }
        Label {
            id: progressHeader
            visible: dockedPanel.open

            y: 2*Theme.paddingLarge
            anchors.left: parent.left
            anchors.right: cancelButton.left
            anchors.leftMargin: progressBusy.width + Theme.paddingLarge*4
            anchors.rightMargin: Theme.paddingLarge
            text: progressPanel.headerText
            color: Theme.primaryColor
        }
        Label {
            id: progressText
            visible: dockedPanel.open
            anchors.left: progressHeader.left
            anchors.right: cancelButton.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.top: progressHeader.bottom
            text: progressPanel.text
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
        }
    }
}
