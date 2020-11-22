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

// This page can be used as a dialog's target page.
// It will wait until all transitions are complete
// and will then navigate to the specified page.
Page {
    property string targetPath: ""

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (targetPath === "") {
                console.warn("relay page: cannot open empty path")
                targetPath = StandardPaths.home
            }
            pageStack.completeAnimation() // abort any running animation
            navigate_goToFolder(targetPath)
        }
    }

    // we want to place the BusyIndicator in the lower part
    // of the upper half of the page
    Item {
        anchors {
            top: parent.top; bottom: parent.verticalCenter
            left: parent.left; right: parent.right
        }
        BusyIndicator {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.verticalCenter
            }
            running: true
            size: BusyIndicatorSize.Large
        }
    }
}
