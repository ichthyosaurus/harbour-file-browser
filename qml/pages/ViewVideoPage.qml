/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2020-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later OR AGPL-3.0-or-later
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Opal.MediaPlayer 1.0

VideoPlayerPage {
    id: root
    allowedOrientations: Orientation.All

    enableDarkBackground: true
    continueInBackground: false
    mprisAppId: qsTr("File Browser", "translated app name")

    Component.onCompleted: {
        if (status === PageStatus.Deactivating) {
            pause()
        }
    }
}
