/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2019-2023 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import Opal.SortFilterProxyModel 1.0
import harbour.file.browser.Settings 1.0

import "../components"
import "../js/paths.js" as Paths

Dialog {
    id: root
    allowedOrientations: Orientation.All
    canAccept: !issueModel.hasSelection

    property string startAt
    property int _startAtIndex

    onAccepted: {
        for (var i = 0; i < repeater.count; i++) {
            var item = repeater.itemAt(i)

            if (!!item && item.nameField.text !== item.originalName) {
                GlobalSettings.bookmarks.rename(item.path, item.nameField.text)
            }
        }
    }

    ItemSelectionModel {
        id: issueModel
        model: GlobalSettings.bookmarks
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { flickable: flick }

        Column {
            id: column
            spacing: Theme.paddingLarge
            anchors {
                left: parent.left
                right: parent.right
            }

            DialogHeader {
                acceptText: qsTr("Apply", "as in 'apply these changes'")
                title: qsTr("Rename bookmarks")
            }

            Repeater {
                id: repeater
                model: GlobalSettings.bookmarks
                Component.onCompleted: itemAt(_startAtIndex).nameField.forceActiveFocus()

                delegate: Column {
                    id: entry
                    property string path: model.path
                    property alias nameField: newNameLabel
                    property string originalName: model.name

                    height: model.group === BookmarkGroup.Bookmark ? newNameLabel.height : 0
                    width: root.width

                    Component.onCompleted: {
                        if (path == startAt) {
                            _startAtIndex = index
                        }
                    }

                    TextMetrics {
                        id: elider
                        text: Paths.unicodeArrow() + " " + entry.path
                        elide: Text.ElideMiddle
                        elideWidth: entry.width
                        font: newNameLabel.font
                    }

                    TextField {
                        id: newNameLabel
                        property string okLabel: elider.elidedText
                        property string errorLabel: qsTr("Name must not be empty")

                        width: parent.width
                        label: okLabel
                        placeholderText: label
                        inputMethodHints: Qt.ImhNoPredictiveText

                        // when enter is pressed, either
                        // - go to next text field
                        // - accept dialog (if possible)
                        // - else hide the virtual keyboard
                        EnterKey.enabled: newNameLabel.text.length > 0
                        EnterKey.iconSource: {
                            if (index < repeater.count-1) "image://theme/icon-m-enter-next"
                            else if (root.canAccept) "image://theme/icon-m-enter-accept"
                            else "image://theme/icon-m-enter-close"
                        }
                        EnterKey.onClicked: {
                            var next = repeater.itemAt(index+1)
                            if (next && next.nameField) next.nameField.forceActiveFocus()
                            else if (root.canAccept) accept()
                        }

                        onTextChanged: {
                            if (text.trim() === "") {
                                errorHighlight = true
                                label = errorLabel
                                issueModel.select(GlobalSettings.bookmarks.index(index, 0),
                                                  ItemSelectionModel.Select)
                            } else {
                                errorHighlight = false
                                label = okLabel
                                issueModel.select(GlobalSettings.bookmarks.index(index, 0),
                                                  ItemSelectionModel.Deselect)
                            }
                        }

                        Component.onCompleted: {
                            text = parent.originalName
                        }
                    }
                }
            }
        }
    }
}
