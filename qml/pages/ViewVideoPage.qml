/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2020-2026 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later OR AGPL-3.0-or-later
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Opal.MediaPlayer 1.0
import harbour.file.browser.Settings 1.0

VideoPlayerPage {
    id: root
    allowedOrientations: Orientation.All

    autoplay: false
    repeat: true
    continueInBackground: false
    enableDarkBackground: true
    enableBlackBackground: GlobalSettings.generalBlackBackground
    mprisAppId: qsTr("File Browser", "translated app name")
}
