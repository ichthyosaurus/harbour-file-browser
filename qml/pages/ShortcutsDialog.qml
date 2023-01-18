/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2023 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../components"

Dialog {
    id: dialog
    allowedOrientations: Orientation.All
    canAccept: selectedPath != ""

    property string selectedPath

    Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Component {
            ShortcutsList {
                id: shortcutsView
                anchors.fill: parent
                onItemClicked: {
                    selectedPath = path
                    dialog.accept()
                }

                header: DialogHeader {
                    acceptText: qsTr("Select")
                }

                VerticalScrollDecorator { flickable: shortcutsView }
                footer: Spacer { id: footerSpacer }
            }
        }
    }
}
