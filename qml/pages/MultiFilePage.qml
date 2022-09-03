/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
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

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/paths.js" as Paths

Page {
    id: page
    allowedOrientations: Orientation.All
    property var files
    property alias notificationPanel: notificationPanel
    property bool _hasMoved: false

    on_HasMovedChanged: {
        if (!_hasMoved) return;
        canNavigateForward = false;
    }

    RemorsePopup {
        id: remorsePopup
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + 2*Theme.paddingLarge
        VerticalScrollDecorator { flickable: flickable }

        visible: !transferPanel.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                title: qsTr("Selection Properties")
            }

            Label {
                visible: _hasMoved
                anchors {
                    left: parent.left; right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("The files have been moved.")
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                spacing: Theme.paddingLarge

                enabled: !_hasMoved
                opacity: enabled ? 1.0 : Theme.opacityLow

                Image { // cannot be highlighted
                    id: icon
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 128 * Theme.pixelRatio
                    height: width
                    source: "../images/large-file-stack.png"
                    asynchronous: true
                }

                Label {
                    width: parent.width
                    text: qsTr("%n item(s) selected", "", page.files.length)
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primaryColor
                }

                FileActions {
                    x: -parent.x
                    selectedFiles: function() { return page.files; }
                    errorCallback: function(errorMsg) { notificationPanel.showTextWithTimer(errorMsg, ""); }
                    selectedCount: page.files.length
                    showProperties: false
                    showSelection: false
                    showShare: false
                    showEdit: false
                    showRename: false
                    Component.onCompleted: labelText = "" // forcibly hide 'x files selected'

                    onDeleteTriggered: {
                        remorsePopup.execute(qsTr("Deleting"), function() {
                            var prevPage = pageStack.previousPage();
                            var filesList = page.files;
                            console.log("mark as doomed:", filesList)
                            prevPage.markAsDoomed(filesList);
                            pageStack.pop();
                            if (prevPage.progressPanel) prevPage.progressPanel.showText(qsTr("Deleting"));
                            engine.deleteFiles(filesList);
                        });
                    }
                    onTransferTriggered: {
                        if (selectedAction === "move") {
                            var prevPage = pageStack.previousPage(page);
                            if (prevPage.progressPanel) transferPanel.progressPanel = prevPage.progressPanel;
                            if (prevPage.notificationPanel) transferPanel.notificationPanel = prevPage.notificationPanel;
                            if (prevPage.markAsDoomed) prevPage.markAsDoomed(toTransfer);
                            page._hasMoved = true;
                        }
                        transferPanel.startTransfer(toTransfer, targets, selectedAction, goToTarget);
                    }
                }

                SizeDetailItem {
                    files: page.files
                }

                DetailList {
                    visible: values.length > 0
                    label: qsTr("Directories")
                    values: getDirectories()
                    maxEntries: 5
                    preprocessor: function(file) {
                        return Paths.lastPartOfPath(file);
                    }
                }

                DetailList {
                    visible: values.length > 0
                    label: qsTr("Files")
                    values: getFiles()
                    maxEntries: 5
                    preprocessor: function(file) {
                        return Paths.lastPartOfPath(file);
                    }
                }
            }
        }
    }

    function getFiles() {
        var ret = [];
        for (var i = 0; i < files.length; i++) {
            if (engine.pathIsFile(files[i])) ret.push(files[i]);
        }
        if (ret.length === 0) ret.push(qsTr("none"));
        return ret;
    }

    function getDirectories() {
        var ret = [];
        for (var i = 0; i < files.length; i++) {
            if (engine.pathIsDirectory(files[i])) ret.push(files[i]);
        }
        if (ret.length === 0) ret.push(qsTr("none"));
        return ret;
    }

    NotificationPanel {
        id: notificationPanel
        page: page
    }

    ProgressPanel {
        id: progressPanel
        page: page
        onCancelled: engine.cancel()
    }

    TransferPanel {
        id: transferPanel
        page: page
        progressPanel: progressPanel
        notificationPanel: notificationPanel
    }
}
