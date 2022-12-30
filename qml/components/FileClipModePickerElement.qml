/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
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

import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.file.browser.FileClipboard 1.0

BackgroundItem {
    id: root

    // important: this item is intended to be used *only*
    // in FileClipModePicker. It requires these properties
    // from the parent context:
    //     1. property int selectedMode

    property int elementMode: -1000
    property alias text: label.text

    // icons are optional but must include
    // proper top and bottom margins if used
    property alias icon: icon.source

    readonly property int numberOfElements: 3 // number of elements in the FileClipMode enum
//     readonly property int numberOfElements: 4
    readonly property bool isSelected: parent.selectedMode === elementMode

    width: parent.width / numberOfElements
    height: contentHeight
    contentHeight: Math.max(Theme.itemSizeMedium, contentColumn.height)
    _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor,
                                 ((highlighted && !isSelected) ? 0.8 : 1.0) * Theme.highlightBackgroundOpacity)

    Column {
        id: contentColumn
        width: parent.width - 2*Theme.paddingMedium
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        HighlightImage {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            source: ""
            highlighted: parent.highlighted
            visible: true
        }

        Label {
            id: label
            width: parent.width
            text: "NO LABEL"
            font.pixelSize: Theme.fontSizeSmall
            fontSizeMode: Text.Fit
            minimumPixelSize: Theme.fontSizeExtraSmall
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            truncationMode: TruncationMode.Fade
        }

        Item { // spacer
            width: 1
            height: Theme.paddingMedium
        }
    }

    onClicked: parent.selectedMode = elementMode
    highlighted: down || isSelected
}
