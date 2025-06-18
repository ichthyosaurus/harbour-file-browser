/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2019-2025 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import SortFilterProxyModel 0.2
import harbour.file.browser.Settings 1.0
import Opal.Delegates 1.0
import Opal.DragDrop 1.0

import "../components"
import "../js/paths.js" as Paths

Dialog {
    id: root
    property string startAt
    property var _deletedPaths: ([])
    property bool _itemsMoved: false

    readonly property QtObject _labels: QtObject {
        readonly property string nameOk: qsTr("Name", "as in: “name of the bookmark you are currently editing”")
        readonly property string nameEmpty: qsTr("Name must not be empty")

        readonly property string pathOk: qsTr("Path", "as in: “path of the bookmark you are currently editing”")
        readonly property string pathEmpty: qsTr("Path must not be empty")
        readonly property string pathNotExists: qsTr("Path does not exist")
        readonly property string pathNotFolder: qsTr("Path is not a folder")
    }

    function _markError(inputField, index, message) {
        inputField.errorHighlight = true
        inputField.label = message
        issueModel.select(GlobalSettings.bookmarks.index(index, 0),
                          ItemSelectionModel.Select)
    }

    function _markOk(inputField, index, message) {
        inputField.errorHighlight = false
        inputField.label = message
        issueModel.select(GlobalSettings.bookmarks.index(index, 0),
                          ItemSelectionModel.Deselect)
    }

    function _markDeleted(path) {
        _deletedPaths.push(path)
    }

    allowedOrientations: Orientation.All
    canAccept: !issueModel.hasSelection
    onAccepted: {
        for (var i in _deletedPaths) {
            GlobalSettings.bookmarks.remove(_deletedPaths[i])
            console.log("removed bookmark: “%1”".arg(_deletedPaths[i]))
        }

        var item = view.itemAt(0, 0)
        while (item !== null) {
            if (item.nameField.text.trim() !== item.originalName) {
                GlobalSettings.bookmarks.rename(item.originalPath, item.nameField.text.trim(), false)
                console.log("renamed bookmark: “%1” -> “%2”".
                            arg(item.originalName).arg(item.nameField.text.trim()))
            }

            if (item.pathField.text !== item.originalPath) {
                GlobalSettings.bookmarks.reset(item.originalPath, item.pathField.text, false)
                console.log("reset bookmark: “%1” -> “%2”".
                            arg(item.originalPath).arg(item.pathField.text))
            }

            item = item.getNextItem()
        }

        GlobalSettings.bookmarks.save()
    }

    onRejected: {
        if (_itemsMoved) {
            GlobalSettings.bookmarks.reload(true)
        }
    }

    ItemSelectionModel {
        id: issueModel
        model: GlobalSettings.bookmarks
    }

    SilicaListView {
        id: view
        anchors.fill: parent

        header: DialogHeader {
            acceptText: qsTr("Apply", "as in 'apply these changes'")
            title: qsTr("Edit bookmarks")
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
            onItemDropped: _itemsMoved = true
        }

        delegate: PaddedDelegate {
            id: entry
            property int modelIndex: index
            property alias nameField: nameField
            property alias pathField: pathField
            property string originalName: model.name
            property string originalPath: model.path

            function getNextItem() {
                return view.itemAt(0, entry.y + entry.height + 1)
            }

            minContentHeight: Theme.itemSizeSmall
            enableDefaultGrabHandle: false
            dragHandler: viewDragHandler
            centeredContainer: contentColumn
            interactive: false
            showOddEven: true
            padding.right: Theme.paddingMedium

            visible: model.group === BookmarkGroup.Bookmark
            Binding on contentHeight {
                when: model.group !== BookmarkGroup.Bookmark
                value: 0
            }

            rightItemAlignment: Qt.AlignVCenter
            rightItem: Column {
                width: handle.width
                height: childrenRect.height

                DragHandle {
                    id: handle
                    implicitWidth: Theme.itemSizeSmall

                    anchors {
                        verticalCenter: undefined
                        right: parent.right
                    }

                    moveHandler: DelegateDragHandler {
                        viewHandler: viewDragHandler
                        handledItem: entry
                        modelIndex: entry.modelIndex
                    }
                }

                IconButton {
                    anchors.right: parent.right
                    width: Theme.iconSizeMedium
                    icon.source: "image://theme/icon-m-delete"
                    onClicked: {
                        var path = entry.originalPath
                        var forget = root._markDeleted
                        entry.remorseDelete(function() {
                            entry.animateRemoval()
                            forget(path)
                        })
                    }
                }
            }

            Column {
                id: contentColumn
                width: parent.width

                TextField {
                    id: nameField
                    textMargin: 0
                    width: parent.width
                    label: _labels.nameOk
                    placeholderText: label
                    inputMethodHints: Qt.ImhNoPredictiveText
                    wrapMode: Text.Wrap

                    // when enter is pressed, either
                    // - go to next text field
                    // - accept dialog (if possible)
                    // - else hide the virtual keyboard
                    EnterKey.enabled: nameField.text.length > 0
                    EnterKey.iconSource: {
                        if (index < view.count-1) "image://theme/icon-m-enter-next"
                        else if (root.canAccept) "image://theme/icon-m-enter-accept"
                        else "image://theme/icon-m-enter-close"
                    }
                    EnterKey.onClicked: {
                        var next = entry.getNextItem()
                        if (next && next.nameField) next.nameField.forceActiveFocus()
                        else if (root.canAccept) accept()
                    }

                    onTextChanged: {
                        if (text.trim() === "") {
                            _markError(nameField, index, _labels.nameEmpty)
                        } else {
                            _markOk(nameField, index, _labels.nameOk)
                        }
                    }

                    Component.onCompleted: {
                        text = entry.originalName
                    }
                }

                TextField {
                    id: pathField
                    textMargin: 0
                    width: parent.width
                    label: _labels.pathOk
                    placeholderText: label
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    focusOnClick: false

                    onClicked: {
                        var dialog = pageStack.push(Qt.resolvedUrl("PathEditDialog.qml"),
                            { path: pathField.text, pickFolder: true, acceptText: qsTr("Apply") })
                        dialog.accepted.connect(function() {
                            pathField.text = dialog.path
                        });
                    }

                    onTextChanged: {
                        if (text.trim() === "") {
                            _markError(pathField, index, _labels.pathEmpty)
                        } else {
                            if (!engine.exists(pathField.text)) {
                                _markError(pathField, index, _labels.pathNotExists)
                            } else if (!engine.pathIsDirectory(pathField.text)) {
                                _markError(pathField, index, _labels.pathNotFolder)
                            } else {
                                _markOk(pathField, index, _labels.pathOk)
                            }
                        }
                    }

                    Component.onCompleted: {
                        text = entry.originalPath
                    }
                }
            }

            Component.onCompleted: {
                if (originalPath == startAt) {
                    nameField.forceActiveFocus()
                }
            }
        }
    }
}
