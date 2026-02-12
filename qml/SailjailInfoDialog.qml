/*
 * This file is part of File Browser.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025-2026 Mirian Margiani
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Opal.SupportMe 1.0
import Opal.LinkHandler 1.0

SupportDialog {
    readonly property string openReposUrl: "https://openrepos.net/content/ichthyosaurus/file-browser"

    greeting: qsTr("Notice")
    hook: qsTr("Please install this app from Storeman / OpenRepos to get " +
               "unrestricted access to all files and folders.")

    DetailsDrawer {
        title: qsTr("Limitations in this version")
        closedHeight: 2 * Theme.itemSizeHuge

        DetailsParagraph {
            text: qsTr("This app is currently running in a sandbox " +
                       "environment and does not have access to all " +
                       "files and folders.")
        }

        DetailsParagraph {
            text: qsTr("Inaccessible folders appear " +
                       "empty as there is no way for the app to determine if " +
                       "a folder is actually empty or simply presented as empty " +
                       "by the system.")
        }

        DetailsParagraph {
            text: qsTr("Additionally, some file previews and integrated " +
                       "access to storage settings are disabled.")
        }

        DetailsParagraph {
            text: qsTr("If you need full access to all files, please install " +
                       "File Browser from <a href='%1'>OpenRepos</a>.".arg(
                           openReposUrl))
        }
    }

    Item {
        width: 1
        height: 2*Theme.paddingLarge
    }

    Button {
        width: Theme.buttonWidthLarge
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("Install from OpenRepos",
                   "as in: “open the OpenRepos website to install " +
                   "the File Browser app from there”")
        onClicked: LinkHandler.openOrCopyUrl(openReposUrl)
    }

    goodbye: ""
}
