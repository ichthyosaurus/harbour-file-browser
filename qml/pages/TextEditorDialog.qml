/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
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
import harbour.file.browser.FileData 1.0
import harbour.file.browser.TextEditor 1.0

import "../components"

Dialog {
    id: root
    allowedOrientations: Orientation.All

    property alias file: editor.file
    property bool _changed: false
    property bool _predictiveHintsEnabled: true

    function save() {
        console.log("[text editor] saving to", fileData.file)
        editor.contents = editorArea.text
        editor.save()
        _changed = false
    }

    canAccept: !editor.isReadOnly && _changed
    onAccepted: {
        save()
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            editor.reload()
        }
    }

    Notification {
        id: errorNotification
        isTransient: false
        previewSummary: summary
        previewBody: body
        appName: qsTr("File Browser", "translated app name")
        appIcon: "icon-lock-warning"
        icon: "icon-lock-warning"
    }

    FileData {
        id: fileData
        file: editor.file
    }

    TextEditor {
        id: editor
        onContentsChanged: {
            editorArea.text = contents
        }
        onErrorMessageChanged: {
            if (errorCategory === "read") {
                errorNotification.summary = qsTr("Failed to open “%1”").arg(fileData.name)
            } else if (errorCategory === "write") {
                errorNotification.summary = qsTr("Failed to save “%1”").arg(fileData.name)
            } else {
                errorNotification.summary = qsTr("Failed to edit “%1”").arg(fileData.name)
            }

            errorNotification.body = errorMessage
            errorNotification.publish()
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: header.height + titleColumn.height + editorColumn.height + Theme.paddingMedium

        VerticalScrollDecorator { flickable: flick }

        PullDownMenu {
            MenuItem {
                text: qsTr("Open externally")
                onClicked: {
                    if (!Qt.openUrlExternally(fileData.file)) {
                        errorNotification.summary = qsTr("Failed to open “%1”").arg(fileData.name)
                        errorNotification.body = qsTr("No application to open the file")
                        errorNotification.publish()
                    }
                }
            }
            MenuItem {
                text: _predictiveHintsEnabled ?
                          qsTr("Disable predictive text input") :
                          qsTr("Enable predictive text input")
                onDelayedClick: {
                    _predictiveHintsEnabled = !_predictiveHintsEnabled
                }
            }
            MenuItem {
                text: qsTr("Save")
                visible: canAccept
                onClicked: save()
            }
        }

        DialogHeader {
            id: header
            acceptText: qsTr("Save")
        }

        Column {
            id: titleColumn
            anchors.top: header.bottom
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            Label {
                text: (_changed ? "* " : "") + fileData.name
                width: parent.width
                font.pixelSize: Theme.fontSizeLarge
                color: palette.highlightColor
                truncationMode: TruncationMode.Fade
            }

            Label {
                text: fileData.absolutePath
                width: parent.width
                wrapMode: Text.Wrap
                elide: Text.ElideMiddle
                maximumLineCount: 2
                color: palette.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Spacer { height: Theme.paddingLarge }
        }

        Column {
            id: editorColumn
            anchors.top: titleColumn.bottom
            width: parent.width
            clip: true

            TextArea {
                id: editorArea
                anchors {
                    left: parent.left
                    right: parent.right
                }

                text: editor.contents
                font.pixelSize: Theme.fontSizeExtraSmall
                font.family: "monospace"
                wrapMode: Text.Wrap
                inputMethodHints: _predictiveHintsEnabled ? Qt.ImhNone : Qt.ImhNoPredictiveText

                onTextChanged: {
                    if (editor.isReadOnly) return

                    if (text != editor.contents) {
                        _changed = true
                    } else {
                        _changed = false
                    }
                }
            }
        }
    }
}
