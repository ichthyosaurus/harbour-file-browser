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

    // requires in parent context:
    // - property int selectedMode

    property int elementMode: -1000
    property alias text: label.text

    readonly property int numberOfElements: 3 // number of elements in the FileClipMode enum

    width: parent.width / numberOfElements
    contentHeight: parent.height
    _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor :
                                               Theme.highlightDimmerColor,
                                 Theme.highlightBackgroundOpacity)

    Label {
        id: label
        text: "NO LABEL"
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        truncationMode: TruncationMode.Fade
    }

    onClicked: parent.selectedMode = elementMode
    highlighted: parent.selectedMode === elementMode
}
