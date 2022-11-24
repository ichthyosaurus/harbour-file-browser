/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileClipboard 1.0
import harbour.file.browser.Settings 1.0

// TODO refactor to use FileClipMode instead of strings

Item {
    id: root
    property string selection: (picker.selectedMode >= 0 ? GlobalSettings.transferDefaultAction : "")

    height: Theme.itemSizeMedium
    width: parent.width

    FileClipModePicker {
        id: picker
        anchors.fill: parent

        selectedMode: {
            var defTransfer = GlobalSettings.transferDefaultAction

            if (defTransfer == "copy") return FileClipMode.Copy
            else if (defTransfer == "move") return FileClipMode.Cut
            else if (defTransfer == "link") return FileClipMode.Link
            else return -1
        }

        onSelectedModeChanged: {
            if (selectedMode == FileClipMode.Copy) {
                selection = "copy"
            } else if (selectedMode == FileClipMode.Cut) {
                selection = "move"
            } else if (selectedMode == FileClipMode.Link) {
                selection = "link"
            }
        }
    }
}
