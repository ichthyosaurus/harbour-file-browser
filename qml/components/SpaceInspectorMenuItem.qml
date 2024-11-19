/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import harbour.file.browser.Settings 1.0

MenuItem {
    id: root

    property string path

    visible: GlobalSettings.spaceInspectorEnabled
    text: qsTr("Analyse disk usage")
    onClicked: {
        if (GlobalSettings.launchSpaceInspector(path)) {
            successNotification.publish()
        } else {
            errorNotification.publish()
        }
    }

    Notification {
        id: successNotification
        previewSummary: qsTr("The “Space Inspector” app will open shortly.")
        isTransient: true
        appIcon: "icon-lock-information"
        icon: "icon-lock-information"
    }

    Notification {
        id: errorNotification
        previewSummary: qsTr("The “Space Inspector” app could not be opened.")
        isTransient: true
        appIcon: "icon-lock-warning"
        icon: "icon-lock-warning"
    }
}
