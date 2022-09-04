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

Page {
    id: root
    allowedOrientations: Orientation.All

    property alias file: editor.file
    property bool _changed: false

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
            editorArea.forceActiveFocus()
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
        contentHeight: header.height + editorColumn.height + Theme.paddingMedium

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
                text: qsTr("Save")
                enabled: !editor.isReadOnly && _changed
                onClicked: {
                    console.log("[text editor] saving to", fileData.file)
                    editor.contents = editorArea.text
                    editor.save()
                    _changed = false
                }
            }
        }

        PageHeader {
            id: header
            title: (_changed ? "* " : "") + fileData.name
            description: fileData.absolutePath
        }

        Column {
            id: editorColumn
            anchors.top: header.bottom
            width: parent.width
            clip: true

            TextArea {
                id: editorArea
                anchors {
                    left: parent.left
                    right: parent.right
                }

                focus: true
                text: editor.contents
                font.pixelSize: Theme.fontSizeExtraSmall
                font.family: "monospace"
                wrapMode: Text.Wrap

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
