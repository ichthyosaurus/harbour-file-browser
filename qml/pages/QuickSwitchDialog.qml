/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020 Mirian Margiani
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

PathEditDialog {
    id: dialog
    // 'path' has to be set when called

    acceptText: qsTr("Switch") //: as in "Switch to this folder, please"
    acceptDestinationAction: PageStackAction.Push
    acceptDestinationProperties: ({ 'targetPath': '' })
    acceptDestination: Qt.resolvedUrl("QuickSwitchRelayPage.qml")
    onAcceptPendingChanged: {
        if (!acceptPending) return;
        if (!acceptDestinationInstance) {
            console.warn("fatal: relay page is not instantiated")
            return
        }
        acceptDestinationInstance.targetPath = path;
    }
}
