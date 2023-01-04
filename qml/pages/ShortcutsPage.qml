/*
 * This file is part of File Browser.
 *
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
import Nemo.Notifications 1.0
import harbour.file.browser.FileOperations 1.0
import harbour.file.browser.Settings 1.0
// import harbour.file.browser.FileClipboard 1.0

import "../js/paths.js" as Paths
import "../components"

Page {
    id: page
    objectName: "ShortcutsPage"
    allowedOrientations: Orientation.All

    property string currentPath: ""

    function _showSailfishPicker(pickerType, title) {
        // note: we cannot use "animatorPush" because we need a proper
        // object to create connections below
        var picker = pageStack.push("Sailfish.Pickers.%1PickerPage".arg(pickerType), {
            'title': title
        })
        picker.selectedContentPropertiesChanged.connect(function() {
            pageStack.animatorPush(Qt.resolvedUrl("FilePage.qml"), {
                'file': picker.selectedContentProperties.filePath,
                'allowMoveDelete': false,
                'enableOpenFolder': true,
            })
        })
    }

    NotificationPanel {
        id: notificationPanel
        page: page
    }

    ListModel {
        id: pickersModel

        ListElement {
            name: qsTr("Clipboard")
            icon: "image://theme/icon-m-clipboard"
            type: "clipboard"
        }
        ListElement {
            name: qsTr("Transfers")
            icon: "image://theme/icon-m-transfer"
            type: "fileops"
        }
        ListElement {
            name: qsTr("Documents")
            icon: "image://theme/icon-m-file-document"
            type: "documents"
        }
        ListElement {
            name: qsTr("Pictures")
            icon: "image://theme/icon-m-file-image"
            type: "pictures"
        }
        ListElement {
            name: qsTr("Videos")
            icon: "image://theme/icon-m-media"
            type: "videos"
        }
        ListElement {
            name: qsTr("Music")
            icon: "image://theme/icon-m-file-audio"
            type: "music"
        }
    }

    ShortcutsList {
        id: shortcutsView
        anchors.fill: parent
        onItemClicked: navigate_goToFolder(path)

        header: Item {
            width: parent.width
            height: head.height + row.height

            PageHeader {
                id: head
                title: qsTr("Places")
            }

            SilicaFlickable {
                id: flick
                flickableDirection: Flickable.HorizontalFlick
                width: parent.width
                height: row.height + Theme.paddingSmall
                contentHeight: row.height
                contentWidth: row.width + Theme.horizontalPageMargin
                anchors.top: head.bottom
                clip: true  // don't leak into page to the right

                HorizontalScrollDecorator { flickable: flick }

                Row {
                    Item {
                        width: Theme.horizontalPageMargin
                        height: 1
                    }

                    Row {
                        id: row
                        readonly property real itemWidth: Theme.iconSizeMedium + 2*Theme.paddingLarge
                        readonly property int itemsPerScreen: 5  // how many items we try to fit in without scrolling

                        width: childrenRect.width
                        height: childrenRect.height
                        spacing: (itemWidth * itemsPerScreen + 2*Theme.horizontalPageMargin) < page.width ?
                                     (((page.width - 2*Theme.horizontalPageMargin) / itemsPerScreen) - itemWidth) : Theme.paddingMedium

                        Repeater {
                            model: pickersModel
                            delegate: IconButton {
                                visible: enabled
                                enabled: {
                                    // Hide fileops when there is nothing to show. We still show
                                    // the clipboard even if it is empty to improve discoverability.
                                    // Maybe it would be less confusing to always show all entries?
                                    if (model.type === "fileops" && FileOperations.count === 0) false
                                    // else if (model.type === "clipboard" && FileClipboard.count === 0) false
                                    else true
                                }

                                width: row.itemWidth
                                height: childrenRect.height

                                onClicked: {
                                    if (model.type === "clipboard") {
                                        pageStack.animatorPush(Qt.resolvedUrl("ClipboardPage.qml"))
                                    } else if (model.type === "fileops") {
                                        pageStack.animatorPush(Qt.resolvedUrl("FileOperationsPage.qml"))
                                    } else if (model.type === "documents") {
                                        _showSailfishPicker('Document', model.name)
                                    } else if (model.type === "pictures") {
                                        _showSailfishPicker('Image', model.name)
                                    } else if (model.type === "videos") {
                                        _showSailfishPicker('Video', model.name)
                                    } else if (model.type === "music") {
                                        _showSailfishPicker('Music', model.name)
                                    } else {
                                        model.icon = Qt.resolvedUrl("../images/places-warning.png")
                                        console.warn("bug: unknown shortcut type '", model.type, "' cannot be handled")
                                    }
                                }

                                Icon {
                                    id: image
                                    anchors.centerIn: circle
                                    highlighted: parent._showPress
                                    opacity: parent.enabled ? 1.0 : Theme.opacityLow
                                    source: model.icon
                                    width: Theme.iconSizeMedium
                                    height: width
                                }

                                Rectangle {
                                    id: circle
                                    radius: width
                                    width: parent.width - Theme.paddingLarge
                                    height: width
                                    anchors {
                                        top: parent.top
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    color: "transparent"
                                    border.color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                                    opacity: parent.enabled ? 1.0 : Theme.opacityLow
                                }

                                TextMetrics {
                                    id: metrics
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeTiny
                                    text: model.name
                                }

                                Label {
                                    width: parent.width
                                    text: model.name
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: metrics.width > width ? Text.AlignLeft : Text.AlignHCenter
                                    truncationMode: metrics.width > width ? TruncationMode.Fade : TruncationMode.None
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    fontSizeMode: Text.Fit
                                    minimumPixelSize: /*metrics.width > width ? Theme.fontSizeExtraSmall :*/ Theme.fontSizeTiny
                                    opacity: parent.enabled ? 1.0 : Theme.opacityLow

                                    anchors {
                                        top: circle.bottom
                                        topMargin: Theme.paddingSmall
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        footer: Spacer { id: footerSpacer }

        VerticalScrollDecorator { flickable: shortcutsView; }

        PullDownMenu {
            MenuItem {
                visible: currentPath !== ""
                text: bookmark.marked ?
                          qsTr("Remove bookmark for “%1”").arg(Paths.lastPartOfPath(currentPath)) :
                          qsTr("Add “%1” to bookmarks").arg(currentPath === "/" ? "/" : Paths.lastPartOfPath(currentPath))
                onDelayedClick: bookmark.toggle()

                Bookmark {
                    id: bookmark
                    path: currentPath
                }
            }
            MenuItem {
                Notification{
                    id: windowNotification
                    previewSummary: qsTr("New window opened. Sometimes the application stays in the background.")
                    isTransient: true
                    appIcon: "icon-lock-information"
                    icon: "icon-lock-information"
                }

                text: qsTr("Open new window")
                onClicked: {
                    engine.openNewWindow(currentPath)
                    windowNotification.publish()
                }
            }
            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                          { dir: currentPath === "" ? StandardPaths.home : currentPath });
            }
        }

        PushUpMenu {
            id: pulley
            MenuItem {
                text: qsTr("Create a new bookmark")
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("../pages/PathEditDialog.qml"), {
                        path: currentPath === "" ? StandardPaths.home : currentPath,
                        acceptCallback: function(path) {
                            if (!GlobalSettings.bookmarks.hasBookmark(path)) GlobalSettings.bookmarks.add(path)
                        },
                        customFilter: function(path) {
                            // exclude dirs that already have a bookmark
                            return !GlobalSettings.bookmarks.hasBookmark(path);
                         },
                         hideExcluded: false,
                         acceptText: qsTr("Save")
                    })
                }
            }
            MenuItem {
                visible: !GlobalSettings.runningAsRoot && GlobalSettings.systemSettingsEnabled
                text: qsTr("Open storage settings");
                onClicked: {
                    pageStack.push(Qt.resolvedUrl(GlobalSettings.storageSettingsPath));
                }
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            main.coverText = qsTr("Places") // update cover
            if (!forwardNavigation) pageStack.pushAttached(main.settingsPage);
        }
        if (status === PageStatus.Activating || status === PageStatus.Deactivating) {
            shortcutsView._isEditing = false;
        }
    }
}
