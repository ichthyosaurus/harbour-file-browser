/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014-2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
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

import QtQuick 2.6
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

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("These are global preferences. If enabled " +
                           "in “<a href='#'>View → Use per-directory view settings</a>”, " +
                           "view preferences will be saved individually for all " +
                           "folders. Here, you can define the default values.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                linkColor: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
                onLinkActivated: viewGroup.open = true
            }

            Spacer { height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("Swipe right to view File Browser's source code, " +
                           "license information, and a list of contributors.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
            }

            Spacer { height: Theme.paddingLarge }

            GroupedDrawer {
                id: viewGroup
                title: qsTr("View")
                open: false
                contents: Column {
                    SettingsSwitch {
                        text: qsTr("Use per-directory view settings")
                        key: "viewUseLocalSettings"
                    }
                    SettingsSwitch {
                        text: qsTr("Show hidden files")
                        key: "viewHiddenFilesShown"
                    }
                    SettingsSwitch {
                        text: qsTr("Show preview images")
                        key: "viewPreviewsShown"
                    }
                    ComboBox {
                        label: qsTr("Thumbnail size")
                        property var indices: ({'small': 0, 'medium': 1, 'large': 2, 'huge': 3})
                        currentIndex: indices[globalSettings.viewPreviewsSize]
                        onValueChanged: globalSettings.viewPreviewsSize = currentItem.action

                        menu: ContextMenu {
                            MenuItem { text: qsTr("small");  property string action: "small"; }
                            MenuItem { text: qsTr("medium"); property string action: "medium"; }
                            MenuItem { text: qsTr("large");  property string action: "large"; }
                            MenuItem { text: qsTr("huge");   property string action: "huge"; }
                        }
                    }
                    TextSwitch {
                        text: qsTr("Enable gallery mode")
                        description: qsTr("In gallery mode, images will be shown comfortably large, " +
                                          "and all entries except for images, videos, and directories will be hidden.")
                        automaticCheck: false
                        checked: globalSettings.viewViewMode === "gallery"
                        onClicked: {
                            // writing the new value will update "checked"
                            if (checked) globalSettings.viewViewMode = 'list'
                            else globalSettings.viewViewMode = 'gallery'
                        }
                    }
                }
            }

            GroupedDrawer {
                title: qsTr("Sorting")
                contents: Column {
                    SettingsSwitch {
                        text: qsTr("Show folders first")
                        key: "viewShowDirectoriesFirst"
                    }
                    SettingsSwitch {
                        text: qsTr("Sort case-sensitively")
                        key: "viewSortCaseSensitively"
                    }
                    ComboBox {
                        label: qsTr("Sort by")
                        property var indices: ({'name': 0, 'size': 1, 'modificationtime': 2, 'type': 3})
                        currentIndex: indices[globalSettings.viewSortRole]
                        onValueChanged: globalSettings.viewSortRole = currentItem.value

                        menu: ContextMenu {
                            MenuItem { text: qsTr("name");              property string value: "name" }
                            MenuItem { text: qsTr("size");              property string value: "size" }
                            MenuItem { text: qsTr("modification time"); property string value: "modificationtime" }
                            MenuItem { text: qsTr("file type");         property string value: "type" }
                        }
                    }
                    ComboBox {
                        label: qsTr("Sort order")
                        property var indices: ({'default': 0, 'reversed': 1})
                        currentIndex: indices[globalSettings.viewSortOrder]
                        onValueChanged: globalSettings.viewSortOrder = currentItem.value

                        menu: ContextMenu {
                            MenuItem { text: qsTr("default");  property string value: "default" }
                            MenuItem { text: qsTr("reversed"); property string value: "reversed" }
                        }
                    }
                }
            }

            GroupedDrawer {
                id: behaviourGroup
                title: qsTr("Behavior and View")
                contents: Column {
                    ComboBox {
                        label: qsTr("Default transfer action")
                        property var indices: ({'copy': 0, 'move': 1, 'link': 2, 'none': 3})
                        currentIndex: indices[globalSettings.transferDefaultAction]
                        onValueChanged: globalSettings.transferDefaultAction = currentItem.action

                        menu: ContextMenu {
                            MenuItem { text: qsTr("copy"); property string action: "copy"; }
                            MenuItem { text: qsTr("move"); property string action: "move"; }
                            MenuItem { text: qsTr("link"); property string action: "link"; }
                            MenuItem { text: qsTr("none"); property string action: "none"; }
                        }
                    }
                    ComboBox {
                        label: qsTr("Default filter line action")
                        property var indices: ({'filter': 0, 'search': 1})
                        currentIndex: indices[globalSettings.generalDefaultFilterAction]
                        onValueChanged: globalSettings.generalDefaultFilterAction = currentItem.action

                        menu: ContextMenu {
                            MenuItem { text: qsTr("return to directory view"); property string action: "filter"; }
                            MenuItem { text: qsTr("start recursive search");   property string action: "search"; }
                        }
                    }
                    ComboBox {
                        label: qsTr("File name abbreviation")
                        property var indices: ({'fade': 0, 'end': 1, 'middle': 2})
                        currentIndex: indices[globalSettings.generalFilenameElideMode]
                        onValueChanged: globalSettings.generalFilenameElideMode = currentItem.action

                        menu: ContextMenu {
                            MenuItem { text: qsTr("fade out");     property string action: "fade"; }
                            MenuItem { text: qsTr("elide end");    property string action: "end"; }
                            MenuItem { text: qsTr("elide middle"); property string action: "middle"; }
                        }
                    }
                    SettingsSwitch {
                        text: qsTr("Show full directory paths")
                        key: "generalShowFullDirectoryPaths"
                    }
                    SettingsSwitch {
                        text: qsTr("Show navigation menu icon")
                        key: "generalShowNavigationMenuIcon"
                    }
                    SettingsSwitch {
                        text: qsTr("Enable solid window background")
                        key: "generalSolidWindowBackground"
                    }
                }
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && !forwardNavigation) {
            pageStack.pushAttached(main.aboutPage);
        }

        if (status === PageStatus.Activating) {
            main.coverText = qsTr("Settings")
        }
    }
}
