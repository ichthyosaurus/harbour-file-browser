/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014-2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2019-2023 Mirian Margiani
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
import harbour.file.browser.Settings 1.0
import Opal.ComboData 1.0
import Opal.InfoCombo 1.0

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
                title: qsTr("App Settings")
            }

            GroupedDrawer {
                id: viewGroup
                title: qsTr("Directory View")
                isOpen: true

                onIsOpenChanged: {
                    if (isOpen) {
                        if (!!sortingGroup) sortingGroup.close()
                        if (!!behaviourGroup) behaviourGroup.close()
                    }
                }

                    SettingsSwitch {
                        text: qsTr("Use per-directory view settings")
                        key: "viewUseLocalSettings"
                        description: qsTr("Save view preferences individually for all folders " +
                                          "in your home directory. The options below are used by default.")
                    }
                    InfoCombo {
                        label: qsTr("View mode")
                        property ComboData cdata; ComboData { dataRole: "value" }
                        onValueChanged: GlobalSettings.viewViewMode = cdata.currentData
                        Component.onCompleted: cdata.reset(GlobalSettings.viewViewMode)

                        menu: ContextMenu {
                            InfoMenuItem {
                                text: qsTr("list")
                                property string value: "list"
                                info: qsTr("Show files in a list. " +
                                           "Optionally enable preview thumbnails " +
                                           "using the separate setting below.")
                            }
                            /*InfoMenuItem {
                                text: qsTr("Grid")
                                property string value: "grid"
                                info: qsTr("TODO")
                            }*/
                            InfoMenuItem {
                                text: qsTr("gallery")
                                property string value: "gallery"
                                info: qsTr("In gallery mode, images will be shown " +
                                           "comfortably large, and all entries except " +
                                           "for images, videos, and directories will be hidden.")
                            }
                        }

                        InfoComboSection {
                            placeAtTop: false
                            title: qsTr("Note")
                            text: qsTr("It is recommended to use “list” as default mode.") +
                                  qsTr("Note that non-media files are hidden in “gallery” mode. " +
                                       "If per-directory settings are enabled, you can change " +
                                       "the view mode for individual folders.")
                        }
                    }
                    SettingsSwitch {
                        text: qsTr("Show hidden files")
                        key: "viewHiddenFilesShown"
                        description: qsTr('Show files with names starting with a full stop (“.”).')
                    }
                    SettingsSwitch {
                        text: qsTr("Show preview images")
                        key: "viewPreviewsShown"
                        description: qsTr("Preview contents of supported file types.")
                    }
                    ComboBox {
                        label: qsTr("Thumbnail size")
                        property ComboData cdata; ComboData { dataRole: "value" }
                        onValueChanged: GlobalSettings.viewPreviewsSize = cdata.currentData
                        Component.onCompleted: cdata.reset(GlobalSettings.viewPreviewsSize)

                        menu: ContextMenu {
                            MenuItem { text: qsTr("small");  property string value: "small"; }
                            MenuItem { text: qsTr("medium"); property string value: "medium"; }
                            MenuItem { text: qsTr("large");  property string value: "large"; }
                            MenuItem { text: qsTr("huge");   property string value: "huge"; }
                        }
                    }
            }

            GroupedDrawer {
                id: sortingGroup
                title: qsTr("Sorting")

                onIsOpenChanged: {
                    if (isOpen) {
                        viewGroup.close()
                        behaviourGroup.close()
                    }
                }

                    SettingsSwitch {
                        text: qsTr("Show folders first")
                        key: "viewShowDirectoriesFirst"
                        description: qsTr("Always show folders at the top of the file list.")
                    }
                    SettingsSwitch {
                        text: qsTr("Show hidden files last")
                        key: "viewShowHiddenLast"
                        description: qsTr("Always show files starting with a full stop (“.”) at the end of the file list.")
                    }
                    ComboBox {
                        label: qsTr("Sort by")
                        property ComboData cdata; ComboData { dataRole: "value" }
                        onValueChanged: GlobalSettings.viewSortRole = cdata.currentData
                        Component.onCompleted: cdata.reset(GlobalSettings.viewSortRole)

                        menu: ContextMenu {
                            MenuItem { text: qsTr("name");      property string value: "name" }
                            MenuItem { text: qsTr("size");      property string value: "size" }
                            MenuItem { text: qsTr("file age");  property string value: "modificationtime" }
                            MenuItem { text: qsTr("file type"); property string value: "type" }
                        }
                    }
                    SettingsSwitch {
                        text: qsTr("Sort case-sensitively")
                        key: "viewSortCaseSensitively"
                        description: qsTr("Show files with names starting with a capital letter first.")
                        enabled: settingsContainer.viewSortRole == "name"
                    }
                    InfoCombo {
                        label: qsTr("Sort order")
                        property ComboData cdata; ComboData { dataRole: "value" }
                        onValueChanged: GlobalSettings.viewSortOrder = cdata.currentData
                        Component.onCompleted: cdata.reset(GlobalSettings.viewSortOrder)

                        menu: ContextMenu {
                            InfoMenuItem {
                                property string value: "default"
                                text: qsTr("ascending")
                                info: "<ul>" +
                                      "<li>%1</li>".arg(qsTr("Sort names starting with the beginning of the alphabet first.")) +
                                      "<li>%1</li>".arg(qsTr("Show smaller files first.")) +
                                      "<li>%1</li>".arg(qsTr("Show more recently changed files first.")) +
                                      "</ul>"
                            }
                            InfoMenuItem {
                                property string value: "reversed"
                                text: qsTr("descending")
                                info: "<ul>" +
                                      "<li>%1</li>".arg(qsTr("Sort names starting with the end of the alphabet first.")) +
                                      "<li>%1</li>".arg(qsTr("Show larger files first.")) +
                                      "<li>%1</li>".arg(qsTr("Show older files first.")) +
                                      "</ul>"
                            }
                        }
                }
            }

            GroupedDrawer {
                id: behaviourGroup
                title: qsTr("Behavior and View")

                onIsOpenChanged: {
                    if (isOpen) {
                        viewGroup.close()
                        sortingGroup.close()
                    }
                }

                    ComboBox {
                        id: initialDirMode
                        label: qsTr("Initial directory")
                        property var indices: { var x = {}; x[InitialDirectoryMode.Home] = 0;
                            x[InitialDirectoryMode.Last] = 1; x[InitialDirectoryMode.Custom] = 2; return x }
                        currentIndex: indices[GlobalSettings.generalInitialDirectoryMode]
                        onValueChanged: GlobalSettings.generalInitialDirectoryMode = currentItem.value
                        description: qsTr("The directory that is shown when the app starts.")

                        menu: ContextMenu {
                            MenuItem { text: qsTr("user's home"); property int value: InitialDirectoryMode.Home; }
                            MenuItem { text: qsTr("last visited"); property int value: InitialDirectoryMode.Last; }
                            MenuItem { text: qsTr("custom path"); property int value: InitialDirectoryMode.Custom; }
                        }
                    }
                    TextField {
                        property bool isCustom: GlobalSettings.generalInitialDirectoryMode == InitialDirectoryMode.Custom
                        width: parent.width
                        label: qsTr("Initial directory")
                        text: {
                            if (isCustom) GlobalSettings.generalCustomInitialDirectoryPath
                            else if (GlobalSettings.generalInitialDirectoryMode == InitialDirectoryMode.Last) GlobalSettings.generalLastDirectoryPath
                            else if (GlobalSettings.generalInitialDirectoryMode == InitialDirectoryMode.Home) StandardPaths.home
                        }
                        placeholderText: GlobalSettings.default_generalCustomInitialDirectoryPath
                        enabled: isCustom

                        onClicked: {
                            if (!isCustom) return
                            pageStack.animatorPush(Qt.resolvedUrl("PathEditDialog.qml"), {
                                                       path: GlobalSettings.generalCustomInitialDirectoryPath,
                                                       acceptCallback: function(path) {
                                                           GlobalSettings.generalCustomInitialDirectoryPath = path
                                                       },
                                                       acceptText: qsTr("Choose")
                                                   })
                            focus = false // don't show the keyboard after the dialog has been closed
                        }
                    }
                    /* SettingsSwitch {
                        // TODO planned for v2.6.0
                        text: qsTr("Share clipboard among windows")
                        key: "generalShareClipboard"
                        description: qsTr("Share the list of files currently in the clipboard " +
                                          "among all open File Browser windows. When this is " +
                                          "enabled, you can cut files in one window and paste " +
                                          "them in another.")
                    } */
                    ComboBox {
                        label: qsTr("Default transfer action")
                        property var indices: ({'copy': 0, 'move': 1, 'link': 2, 'none': 3})
                        currentIndex: indices[GlobalSettings.transferDefaultAction]
                        onValueChanged: GlobalSettings.transferDefaultAction = currentItem.action
                        description: qsTr("The action that is selected by default when " +
                                          "using the bulk file management feature (available " +
                                          'through the “shuffle” icon after selecting files).')

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
                        currentIndex: indices[GlobalSettings.generalDefaultFilterAction]
                        onValueChanged: GlobalSettings.generalDefaultFilterAction = currentItem.action
                        description: qsTr("Which action to take when the Enter key is pressed in the " +
                                          "filter line in a directory's pull-down menu.")

                        menu: ContextMenu {
                            MenuItem { text: qsTr("return to directory view"); property string action: "filter"; }
                            MenuItem { text: qsTr("start recursive search");   property string action: "search"; }
                        }
                    }
                    ComboBox {
                        label: qsTr("File name abbreviation")
                        property var indices: ({'fade': 0, 'end': 1, 'middle': 2})
                        currentIndex: indices[GlobalSettings.generalFilenameElideMode]
                        onValueChanged: GlobalSettings.generalFilenameElideMode = currentItem.action
                        description: qsTr("How very long filenames are abbreviated in the directory view.")

                        menu: ContextMenu {
                            MenuItem { text: qsTr("fade out");     property string action: "fade"; }
                            MenuItem { text: qsTr("elide end");    property string action: "end"; }
                            MenuItem { text: qsTr("elide middle"); property string action: "middle"; }
                        }
                    }
                    SettingsSwitch {
                        text: qsTr("Show full directory paths")
                        key: "generalShowFullDirectoryPaths"
                        description: qsTr("Show the full path in the page header of the directory view.")
                    }
                    SettingsSwitch {
                        text: qsTr("Show navigation menu icon")
                        key: "generalShowNavigationMenuIcon"
                        description: qsTr("Show a visual hint that the navigation menu is available by " +
                                          "tapping the page header of the directory view.")
                    }
                    /* SettingsSwitch {
                        // TODO planned for v2.7.0
                        text: qsTr("Enable trash can")
                        key: "generalUseTrashCan"
                        description: qsTr("Move files to a separate “trash can” when deleting, " +
                                          "from which you can restore accidentally deleted files. " +
                                          "If this is disabled, files will always be deleted permanently.")
                    } */
                    SettingsSwitch {
                        text: qsTr("Enable solid window background")
                        key: "generalSolidWindowBackground"
                        description: qsTr("Use a solid color instead of your wallpaper as the " +
                                          "background of this app.")
                    }
            }

            Spacer { height: 2*Theme.paddingLarge }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("Swipe from the right to view File Browser's source code, " +
                           "license information, and a list of contributors.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
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
