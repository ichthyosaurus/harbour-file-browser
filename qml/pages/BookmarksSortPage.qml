/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2023 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Movable/sortable list logic adapted from Patchmanager:
 * SPDX-FileCopyrightText: 2018 Coderus
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.file.browser.Settings 1.0
import SortFilterProxyModel 0.2

import "../js/paths.js" as Paths
import "../components"

Page {
    id: root
    allowedOrientations: Orientation.All

    Component.onCompleted: {
        // NOTE this is only needed if the view has bad performance when hiding items
        // GlobalSettings.bookmarks.sortFilter([BookmarkGroup.Bookmark])
    }

    SilicaListView {
        id: view
        anchors.fill: parent

        readonly property int topmostY: -view.headerItem.height
        readonly property int bottommostY: view.contentHeight - view.height - view.headerItem.height

        header: PageHeader {
            title: qsTr("Sort Bookmarks")
        }

        footer: Spacer { height: Theme.horizontalPageMargin }

        model: GlobalSettings.bookmarks

        add: Transition {
            SequentialAnimation {
                NumberAnimation { properties: "z"; to: -1; duration: 1 }
                NumberAnimation { properties: "opacity"; to: 0.0; duration: 1 }
                NumberAnimation { properties: "x,y"; duration: 1 }
                NumberAnimation { properties: "z"; to: 0; duration: 200 }
                NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: 100 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { properties: "z"; to: -1; duration: 1 }
                NumberAnimation { properties: "x"; to: 0; duration: 100 }
                NumberAnimation { properties: "opacity"; to: 0.0; duration: 100 }
            }
        }
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 200 }
        }

        delegate: ListItem {
            id: background
            visible: model.group === BookmarkGroup.Bookmark

            property int dragThreshold: width / 8
            property var pressPosition
            property int dragIndex: index

            onDragIndexChanged: {
                if (drag.target) {
                    GlobalSettings.bookmarks.move(index, dragIndex, false)
                }
            }

            onPressed: {
                pressPosition = Qt.point(mouse.x, mouse.y)
            }

            onMenuOpenChanged: {
                content.x = 0
            }

            readonly property bool isBelowBottom: drag.target ? (content.y + content.height -
                                                                 view.contentY) > view.height : false
            readonly property bool isAboveTop: drag.target ? content.y < view.contentY : false

            onPositionChanged: {
                if (menuOpen) {
                    return
                }

                var deltaX = pressPosition.x - mouse.x
                if (drag.target) {
                    if (isAboveTop) {
                        sctollTopTimer.start()
                        sctollBottomTimer.stop()
                    } else if (isBelowBottom) {
                        sctollBottomTimer.start()
                        sctollTopTimer.stop()
                    } else {
                        sctollBottomTimer.stop()
                        sctollTopTimer.stop()
                    }
                } else {
                    if (deltaX > dragThreshold) {
                        var newPos = mapToItem(view.contentItem, mouse.x, mouse.y)
                        content.parent = view.contentItem
                        content.x = newPos.x - pressPosition.x
                        content.y = newPos.y - pressPosition.y
                        drag.target = content
                    } else if (deltaX > 0) {
                        content.x = -deltaX
                    } else {
                        content.x = 0
                    }
                }
            }

            Timer {
                id: sctollTopTimer
                repeat: true
                interval: 1
                onTriggered: {
                    if (view.contentY > view.topmostY) {
                        view.contentY -= 5
                        content.y -= 5
                    } else {
                        view.contentY = view.topmostY
                        // content.y = 0
                    }
                }
            }

            Timer {
                id: sctollBottomTimer
                repeat: true
                interval: 1
                onTriggered: {
                    // c.y: 1195.81005859375 c.h: 100 cY: 220 cH: 1638 vH: 1280 hH: 138
                    if (view.contentY < view.bottommostY) {
                        view.contentY += 5
                        content.y += 5
                    } else {
                        view.contentY = view.bottommostY
                        // content.y = view.contentHeight - view.height
                    }
                }
            }

            function reset() {
                if (!drag.target) {
                    content.x = 0
                    return
                } else {
                    GlobalSettings.bookmarks.save()
                    //                view.model.saveLayout()
                }
                sctollTopTimer.stop()
                sctollBottomTimer.stop()
                drag.target = null
                var ctod = content.mapToItem(background, content.x, content.y)
                ctod.x = ctod.x - content.x
                ctod.y = ctod.y - content.y
                content.parent = background
                content.x = ctod.x
                content.y = ctod.y
                backAnimation.start()
            }

            onReleased: reset()
            onCanceled: reset()

            Image {
                anchors.fill: parent
                fillMode: Image.Tile
                source: "image://theme/icon-status-invalid"
                opacity: background.drag.target ? 0.33 : Math.abs(content.x) / dragThreshold / 3
                smooth: false
            }

            // ^^ support for drag-and-drop sorting ^^

            width: root.width
            contentHeight: visible ? Theme.itemSizeSmall : 0

            Rectangle {
                id: content
                width: root.width
                height: Theme.itemSizeSmall
                color: background.drag.target ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity / 2)
                                              : "transparent"
                border.width: background.drag.target ? 2 : 0
                border.color: background.drag.target ? Theme.rgba(Theme.highlightdColor, Theme.highlightBackgroundOpacity)
                                                     : "transparent"

                onYChanged: {
                    if (!background.drag.target) {
                        return
                    }

                    var targetIndex = view.indexAt(content.x + content.width / 2, content.y + content.height / 2)
                    if (targetIndex >= 0) {
                        background.dragIndex = targetIndex
                    }
                }

                NumberAnimation {
                    id: backAnimation
                    target: content
                    properties: "x,y"
                    to: 0
                    duration: 200
                }

                HighlightImage {
                    id: icon
                    width: height
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: Theme.paddingMedium
                    }

                    source: "image://theme/" + model.thumbnail
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    id: shortcutLabel
                    font.pixelSize: Theme.fontSizeMedium
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: model.name
                    truncationMode: TruncationMode.Fade
                    anchors {
                        left: icon.right
                        leftMargin: Theme.paddingMedium
                        top: parent.top
                        topMargin: model.path === model.name ? (parent.height / 2) - (height / 2) : 5
                    }
                    width: root.width - x - Theme.horizontalPageMargin
                }

                Row {
                    id: infoRow
                    spacing: 0
                    anchors {
                        left: icon.right
                        leftMargin: Theme.paddingMedium
                        top: shortcutLabel.bottom
                        topMargin: 2
                        right: shortcutLabel.right
                    }

                    property bool shown: true
                    opacity: shown ? 1.0 : 0.0; visible: opacity != 0.0
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    Text {
                        id: shortcutPathLabel
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        text: Paths.unicodeArrow() + " " + model.path
                        visible: model.path !== model.name
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }
}
