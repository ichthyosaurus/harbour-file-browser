/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

MenuLabel {
    property var diskSpaceInfo: ['']

    text: diskSpaceInfo[0] === 'ok' ?
              qsTr("%1 full (%2%)", "as in “15 of 20 GiB [%1] of this " +
                   "device are filled with data, which is 75% [%2] of " +
                   "its capacity”")
              .arg(diskSpaceInfo[2])
              .arg(diskSpaceInfo[1]) :
              " " // empty space to make sure the label has a height

    BusyIndicator {
        size: BusyIndicatorSize.Small
        running: parent.diskSpaceInfo[0] !== 'ok'
        anchors.centerIn: parent
    }
}
