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
import harbour.file.browser.FileModel 1.0

import "../js/paths.js" as Paths
import "../components"

Page {
    id: page
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
                height: row.height
                contentHeight: row.height
                contentWidth: row.width + Theme.horizontalPageMargin
                anchors.top: head.bottom

                HorizontalScrollDecorator { flickable: flick }

                Row {
                    Item {
                        width: Theme.horizontalPageMargin
                        height: 1
                    }

                    Row {
                        id: row
                        property real itemWidth: Theme.iconSizeMedium + 2*Theme.paddingLarge

                        width: childrenRect.width
                        height: childrenRect.height
                        spacing: (itemWidth * 5 + 2*Theme.horizontalPageMargin) < page.width ?
                                     (((page.width - 2*Theme.horizontalPageMargin) / 5) - itemWidth) : Theme.paddingMedium

                        Repeater {
                            model: ListModel {
                                ListElement {
                                    name: qsTr("Clipboard")
                                    icon: "image://theme/icon-m-clipboard"
                                    type: "clipboard"
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

                            delegate: IconButton {
                                width: row.itemWidth
                                height: childrenRect.height

                                onClicked: {
                                    if (model.type === "clipboard") {
                                        pageStack.animatorPush(Qt.resolvedUrl("ClipboardPage.qml"))
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
                property bool hasPrevious: pageStack.previousPage() ? true : false
                property var hasBookmark: hasPrevious ? pageStack.previousPage().hasBookmark : undefined
                visible: currentPath !== "" && hasPrevious
                text: (hasBookmark !== undefined) ?
                          (hasBookmark ?
                               qsTr("Remove bookmark for “%1”").arg(Paths.lastPartOfPath(currentPath)) :
                               qsTr("Add “%1” to bookmarks").arg(currentPath === "/" ? "/" : Paths.lastPartOfPath(currentPath))) : ""
                onClicked: {
                    if (hasBookmark !== undefined) {
                        pageStack.previousPage().toggleBookmark();
                    }
                }
            }
            MenuItem {
                text: qsTr("Open new window")
                onClicked: {
                    engine.openNewWindow(currentPath);
                    notificationPanel.showTextWithTimer(qsTr("New window opened"),
                        qsTr("Sometimes the application stays in the background"));
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
            property bool _refresh: false
            onActiveChanged: { // delay action until menu is closed
                busy = true
                if (!active && _refresh) shortcutsView.updateModel()
                else _refresh = false
                busy = false
            }
            MenuItem {
                text: qsTr("Create a new bookmark")
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("../pages/PathEditDialog.qml"),
                                   { path: currentPath === "" ? StandardPaths.home : currentPath,
                                       acceptCallback: function(path) {
                                           if (!bookmarks_hasBookmark(path)) bookmarks_addBookmark(path)
                                       },
                                       customFilter: function(path) {
                                           // exclude dirs that already have a bookmark
                                           return !bookmarks_hasBookmark(path);
                                       },
                                       hideExcluded: false,
                                       acceptText: qsTr("Save")
                                   })
                }
            }

            MenuItem {
                text: qsTr("Refresh")
                onClicked: pulley._refresh = true
            }
            MenuItem {
                visible: !runningAsRoot && systemSettingsEnabled
                text: qsTr("Open storage settings");
                onClicked: {
                    pageStack.push(Qt.resolvedUrl(engine.storageSettingsPath()));
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
