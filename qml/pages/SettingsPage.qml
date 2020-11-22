/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014-2016, 2018-2019 Kari Pihkala
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

import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                title: qsTr("Settings")
            }

            GroupedDrawer {
                id: viewGroup
                title: qsTr("View")
                contents: Column {
                    property alias useLocalSettings: v1.checked
                    property alias showHiddenFiles: v2.checked
                    property alias showThumbnails: v3.checked
                    property alias thumbSize: v4.currentIndex
                    property alias enableGallery: v5.checked
                    TextSwitch {
                        id: v1; text: qsTr("Use per-directory view settings")
                        onCheckedChanged: settings.write("View/UseLocalSettings", checked.toString())
                    }
                    TextSwitch {
                        id: v2; text: qsTr("Show hidden files")
                        onCheckedChanged: settings.write("View/HiddenFilesShown", checked.toString())
                    }
                    TextSwitch {
                        id: v3; text: qsTr("Show preview images")
                        onCheckedChanged: settings.write("View/PreviewsShown", checked.toString())
                    }
                    ComboBox {
                        id: v4; width: parent.width
                        label: qsTr("Thumbnail size")
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("small"); property string action: "small"; }
                            MenuItem { text: qsTr("medium"); property string action: "medium"; }
                            MenuItem { text: qsTr("large"); property string action: "large"; }
                            MenuItem { text: qsTr("huge"); property string action: "huge"; }
                        }
                        onValueChanged: settings.write("View/PreviewsSize", currentItem.action);
                    }
                    TextSwitch {
                        id: v5; text: qsTr("Enable gallery mode")
                        description: qsTr("In gallery mode, images will be shown comfortably large, "
                            + "and all entries except for images, videos, and directories will be hidden.")
                        onCheckedChanged: settings.write("View/EnableGalleryMode", checked.toString())
                    }
                }
            }

            GroupedDrawer {
                id: sortingGroup
                title: qsTr("Sorting")
                contents: Column {
                    property alias showDirsFirst: s1.checked
                    property alias sortCaseSensitive: s2.checked
                    property alias sortRole: s3.currentIndex
                    property alias sortOrder: s4.currentIndex
                    TextSwitch {
                        id: s1; text: qsTr("Show folders first")
                        onCheckedChanged: { settings.write("View/ShowDirectoriesFirst", checked.toString()) }
                    }
                    TextSwitch {
                        id: s2; text: qsTr("Sort case-sensitively")
                        onCheckedChanged: settings.write("View/SortCaseSensitively", checked.toString())
                    }
                    ComboBox {
                        id: s3; label: qsTr("Sort by")
                        onValueChanged: settings.write("View/SortRole", currentItem.value);
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("name"); property string value: "name" }
                            MenuItem { text: qsTr("size"); property string value: "size" }
                            MenuItem { text: qsTr("modification time"); property string value: "modificationtime" }
                            MenuItem { text: qsTr("file type"); property string value: "type" }
                        }
                    }
                    ComboBox {
                        id: s4; label: qsTr("Sort order")
                        onValueChanged: settings.write("View/SortOrder", currentItem.value);
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("default"); property string value: "default" }
                            MenuItem { text: qsTr("reversed"); property string value: "reversed" }
                        }
                    }
                }
            }

            GroupedDrawer {
                id: behaviourGroup
                title: qsTr("Behavior and View")
                contents: Column {
                    property alias defaultTransfer: b1.currentIndex
                    property alias defaultFilter: b2.currentIndex
                    property alias showFullPaths: b3.checked

                    ComboBox {
                        id: b1; width: parent.width
                        label: qsTr("Default transfer action")
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("copy"); property string action: "copy"; }
                            MenuItem { text: qsTr("move"); property string action: "move"; }
                            MenuItem { text: qsTr("link"); property string action: "link"; }
                            MenuItem { text: qsTr("none"); property string action: "none"; }
                        }
                        onValueChanged: settings.write("Transfer/DefaultAction", currentItem.action);
                    }
                    ComboBox {
                        id: b2; width: parent.width
                        label: qsTr("Default filter line action")
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("return to directory view"); property string action: "filter"; }
                            MenuItem { text: qsTr("start recursive search"); property string action: "search"; }
                        }
                        onValueChanged: settings.write("General/DefaultFilterAction", currentItem.action);
                    }
                    TextSwitch {
                        id: b3; text: qsTr("Show full directory paths")
                        onCheckedChanged: settings.write("General/ShowFullDirectoryPaths", checked.toString())
                    }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            Label {
                text: qsTr("About File Browser")
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                horizontalAlignment: Text.AlignRight
                color: Theme.highlightColor
            }
            Spacer { height: Theme.paddingLarge }
            Label {
                id: version
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: main.versionString
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
            }
            Spacer { height: Theme.paddingLarge }
            BackgroundItem {
                anchors.left: parent.left
                anchors.right: parent.right
                height: aboutColumn.height
                onClicked: pageStack.push(Qt.resolvedUrl("LicensePage.qml"))

                Column {
                    id: aboutColumn
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    Label {
                        width: parent.width
                        color: Theme.highlightColor
                        text: qsTr("File Browser is released under the terms of the GNU GPL version 3 or later. "+
                                   "This is free software: you are free to change and redistribute it. "+
                                   "There is no warranty, to the extent permitted by law.")
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        anchors.right: parent.right
                        color: Theme.primaryColor // interactive
                        text: "\u2022 \u2022 \u2022" // three dots
                    }
                }
            }

            Spacer { height: Theme.paddingLarge }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: '<style type="text/css">A { color: "%1"; }</style><p>'.arg(Theme.primaryColor) +
                      qsTr("The source code is available at") + "<br>" +
                      '<a href="%1">%1</a></p>'.arg(sourceCodeLink)
                wrapMode: Text.Wrap
                onLinkActivated: Qt.openUrlExternally(link)
                textFormat: Text.RichText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!forwardNavigation) pageStack.pushAttached(Qt.resolvedUrl("ContributorsPage.qml"));
        }

        // update cover
        if (status === PageStatus.Activating)
            coverText = qsTr("Settings");

        // read settings
        if (status === PageStatus.Activating) {
            sortingGroup.contentItem.showDirsFirst = (settings.read("View/ShowDirectoriesFirst", "true") === "true");
            sortingGroup.contentItem.sortCaseSensitive = (settings.read("View/SortCaseSensitively", "false") === "true");
            viewGroup.contentItem.showHiddenFiles = (settings.read("View/HiddenFilesShown", "false") === "true");
            viewGroup.contentItem.showThumbnails = (settings.read("View/PreviewsShown", "false") === "true");
            viewGroup.contentItem.useLocalSettings = (settings.read("View/UseLocalSettings", "true") === "true");
            viewGroup.contentItem.enableGallery = (settings.read("View/EnableGalleryMode", "false") === "true");
            behaviourGroup.contentItem.showFullPaths = (settings.read("General/ShowFullDirectoryPaths", "false") === "true");

            var defTransfer = settings.read("Transfer/DefaultAction", "none");
            if (defTransfer === "copy") {
                behaviourGroup.contentItem.defaultTransfer = 0;
            } else if (defTransfer === "move") {
                behaviourGroup.contentItem.defaultTransfer = 1;
            } else if (defTransfer === "link") {
                behaviourGroup.contentItem.defaultTransfer = 2;
            } else {
                behaviourGroup.contentItem.defaultTransfer = 3;
            }

            var defFilter = settings.read("General/DefaultFilterAction", "filter");
            if (defFilter === "filter") behaviourGroup.contentItem.defaultFilter = 0;
            else if (defFilter === "search") behaviourGroup.contentItem.defaultFilter = 1;
            else behaviourGroup.contentItem.defaultFilter = 0;

            var thumbSize = settings.read("View/PreviewsSize", "medium");
            if (thumbSize === "small") viewGroup.contentItem.thumbSize = 0;
            else if (thumbSize === "medium") viewGroup.contentItem.thumbSize = 1;
            else if (thumbSize === "large") viewGroup.contentItem.thumbSize = 2;
            else if (thumbSize === "huge") viewGroup.contentItem.thumbSize = 3;

            var sortBy = settings.read("View/SortRole", "name");
            if (sortBy === "name") sortingGroup.contentItem.sortRole = 0;
            else if (sortBy === "size") sortingGroup.contentItem.sortRole = 1;
            else if (sortBy === "modificationtime") sortingGroup.contentItem.sortRole = 2;
            else if (sortBy === "type") sortingGroup.contentItem.sortRole = 3;

            var order = settings.read("View/SortOrder", "default");
            if (order === "default") sortingGroup.contentItem.sortOrder = 0;
            else if (order === "reversed") sortingGroup.contentItem.sortOrder = 1;
        }
    }
}
