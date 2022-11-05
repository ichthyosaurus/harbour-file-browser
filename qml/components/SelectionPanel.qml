/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014, 2018-2019 Kari Pihkala
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

// bottom dock panel to display file action icons
DockedPanel {
    id: dockPanel
    width: parent.width
    open: false
    height: fileActions.height
    dock: Dock.Bottom
    visible: shouldBeVisible & !Qt.inputMethod.visible

    property alias selectedFiles: fileActions.selectedFiles
    property alias displayClose: fileActions.displayClose
    property alias actions: fileActions
    property alias selectedCount: fileActions.selectedCount // number of selected items
    property bool enabled: true // enable or disable the buttons
    property string overrideText: "" // override text is shown if set, it gets cleared whenever selected file count changes

    // property to indicate that the panel is really visible (open or showing closing animation)
    property bool shouldBeVisible: false
    onOpenChanged: { if (open) shouldBeVisible = true; }
    onMovingChanged: { if (!open && !moving) shouldBeVisible = false; }

    onSelectedCountChanged: {
        // it should automatically close after another action cleared the selection
        if (selectedCount === 0) open = false;
    }

    FileActions {
        id: fileActions
        labelText: dockPanel.overrideText === "" ? qsTr("%n file(s) selected", "", dockPanel.selectedCount)
                                                 : dockPanel.overrideText
        errorCallback: function(errorMsg) { notificationPanel.showTextWithTimer(errorMsg, ""); }
        showEdit: selectedCount == 1 && fileData.checkSafeToEdit(selectedFiles()[0])
        enabled: enabled
    }
}
