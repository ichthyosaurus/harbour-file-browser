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

Row {
    property int selectedMode: -1  // used by FileClipModePickerElement

    signal modeSelected(var mode)

    readonly property var labelForMode: {
        var map = {}
        map[FileClipMode.Copy] = qsTr("Copy")
        map[FileClipMode.Cut] = qsTr("Move")
        map[FileClipMode.Link] = qsTr("Link")
        // map[FileClipMode.Compress] = qsTr("Compress")
        map[-1] = ""
        return map
    }

    height: childrenRect.height
    width: parent.width

    // important: you must update the "numberOfElements"
    // property in FileClipModePickerElement when adding more
    // elements here!

    FileClipModePickerElement {
        elementMode: FileClipMode.Copy
        text: labelForMode[elementMode]
        icon: "../images/clipboard-copy.png"
    }
    FileClipModePickerElement {
        elementMode: FileClipMode.Cut
        text: labelForMode[elementMode]
        icon: "../images/clipboard-move.png"
    }
    FileClipModePickerElement {
        elementMode: FileClipMode.Link
        text: labelForMode[elementMode]
        icon: "../images/clipboard-link.png"
    }

//     FileClipModePickerElement {
//         elementMode: FileClipMode.Compress
//         text: labelForMode[elementMode]
//         icon: "../images/clipboard-compress.png"
//     }
}
