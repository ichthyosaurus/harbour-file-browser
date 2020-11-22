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

// This item has to be used together with a DirectoryPopup and a Flickable.
// It fades the flickable below the popup but keeps it visible above.
Item {
    id: root
    anchors.fill: parent // must fill the whole visible area, e.g. the page
    property Item baseFlickable
    property Item directoryPopup
    property bool enabled: _popup && (directoryPopup.active ||
                                      directoryPopup.currentHeight > 0)

    property bool _flick: baseFlickable ? true : false
    property bool _popup: directoryPopup ? true : false
    visible: enabled

    // This effect copies the original header and shows
    // it ontop of the second effect. This is necessary as the
    // second effect hides the flickable above the popup.
    OpacityRampEffectBase {
        id: fakeHeader
        offset: 1 // don't even start
        clampMax: 1; clampMin: 1 // we want to keep opacity at 1.0
        anchors {
            bottom: parent.bottom; bottomMargin: parent.height-directoryPopup.menuTop
            top: parent.top; left: parent.left; right: parent.right
        }
        visible: enabled
        source: ShaderEffectSource {
            smooth: false
            enabled: root.enabled
            hideSource: enabled
            sourceItem: enabled ? baseFlickable.headerItem : null
            sourceRect: Qt.rect(0, 0, root.width, directoryPopup.menuTop)
        }
    }

    // This effect fades the visible area of the flickable
    // so it becomes completely transparent just below the popup.
    OpacityRampEffectBase {
        direction: OpacityRamp.BottomToTop
        offset: 0 // start at the bottom
        slope: directoryPopup.currentHeight === 0 ?
                   0 : 1+1/(fileList.height/(directoryPopup.currentHeight+directoryPopup.menuTop))
        anchors {
            top: parent.top; topMargin: directoryPopup.menuTop
            bottom: parent.bottom; left: parent.left; right: parent.right
        }
        visible: enabled
        source: ShaderEffectSource {
            smooth: false
            enabled: root.enabled
            hideSource: enabled
            sourceItem: enabled ? baseFlickable.contentItem : null
            sourceRect: Qt.rect(0, 0, root.width, root.height-directoryPopup.menuTop)
        }
    }
}
