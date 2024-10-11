/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2023-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.file.browser.Settings 1.0
import Opal.Delegates 1.0
import Opal.DragDrop 1.0

import "../js/paths.js" as Paths
import "../components"

Page {
    id: root
    allowedOrientations: Orientation.All

    SilicaListView {
        id: view
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Sort bookmarks")
        }

        footer: Spacer { height: Theme.horizontalPageMargin }
        model: GlobalSettings.bookmarks

        VerticalScrollDecorator {
            flickable: view
        }

        ViewDragHandler {
            id: viewDragHandler
            listView: view
            handleMove: false
            onItemMoved: GlobalSettings.bookmarks.move(fromIndex, toIndex, false)
            onItemDropped: GlobalSettings.bookmarks.save()
        }

        delegate: TwoLineDelegate {
            minContentHeight: Theme.itemSizeSmall
            dragHandler: viewDragHandler
            visible: model.group === BookmarkGroup.Bookmark
            padding.leftRight: Theme.horizontalPageMargin - Theme.paddingMedium

            Binding on contentHeight {
                when: model.group !== BookmarkGroup.Bookmark
                value: 0
            }

            text: model.name
            description: model.path !== model.name ?
                Paths.unicodeArrow() + " " + model.path : ""

            textLabel {
                font.pixelSize: Theme.fontSizeMedium
                wrapped: false
            }

            descriptionLabel {
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapped: false
                elide: Text.ElideMiddle
            }

            leftItemAlignment: textLabel.wrapped ? Qt.AlignTop : Qt.AlignVCenter
            leftItem: DelegateIconItem {
                source: "image://theme/" + model.thumbnail
            }

            onClicked: {
                toggleWrappedText(textLabel)
                toggleWrappedText(descriptionLabel)
            }
        }
    }
}
