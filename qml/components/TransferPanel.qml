/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
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
import harbour.file.browser.FileClipboard 1.0

Rectangle {
    id: panel
    anchors.fill: parent
    opacity: visible ? 1 : 0
    visible: false
    Behavior on opacity { NumberAnimation { duration: 500 } }

    // there should not be anything underneath
    color: "transparent"

    property var files: []
    property var targets: []
    property string action: ""
    property bool goToTarget: false
    property Page page
    property Item progressPanel
    property Item notificationPanel

    property int _toGo: 0
    property int _current: 0
    property string _currentDir: ""
    property bool _finished: false
    property bool _successful: false

    signal transfersFinished(var success)
    signal overlayShown
    signal overlayHidden(var accepted)

    on_FinishedChanged: {
        if (_finished) {
            page.backNavigation = true;
            page.forwardNavigation = true;
        }
    }

    on_SuccessfulChanged: {
        if (!_finished) return;

        function notifyFinish(message) {
            notificationPanel.showTextWithTimer(message, qsTr("%n file(s)", "", files.length)+" / "+qsTr("%n destination(s)", "", targets.length));
        }

        if (_successful) {
            if (action === "copy") {
                notifyFinish(qsTr("Successfully copied", "", files.length));
            } else if (action === "move") {
                notifyFinish(qsTr("Successfully moved", "", files.length));
            } else if (action === "link") {
                notifyFinish(qsTr("Successfully linked", "", files.length));
            }
        } else {
            if (action === "copy") {
                notifyFinish(qsTr("Failed to copy", "", files.length));
            } else if (action === "move") {
                notifyFinish(qsTr("Failed to move", "", files.length));
            } else if (action === "link") {
                notifyFinish(qsTr("Failed to link", "", files.length));
            }
        }

        transfersFinished(_successful);
    }

    onTransfersFinished: {
        if (!success || targets[0] === "") return;
        if (goToTarget) afterTransferConnection.target = notificationPanel;
    }

    MouseArea { // to catch all "stray" clicks
        anchors.fill: parent
        visible: parent.visible
        enabled: visible
    }

    Item {
        id: actionsRelay
        signal accepted
        signal rejected
        function accept() { accepted(); }
        function reject() { rejected(); }
    }

    SilicaListView {
        id: overwriteFileList
        anchors.fill: parent
        anchors.bottomMargin: 0
        clip: true

        model: files

        VerticalScrollDecorator { flickable: overwriteFileList }

        header: Item {
            width: parent.width
            height: header.height + actions.height + label.height + 4*Theme.paddingLarge

            Column {
                anchors.fill: parent

                PageHeader {
                    id: header
                    title: qsTr("Replace?")
                }

                Row {
                    id: actions
                    width: parent.width
                    height: Theme.itemSizeMedium + 2*Theme.paddingLarge
                    spacing: 10

                    BackgroundItem {
                        onClicked: actionsRelay.reject()
                        width: parent.width / 2 - 5
                        contentHeight: Theme.itemSizeMedium
                        _backgroundColor: Theme.rgba(pressed ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor,
                                                     Theme.highlightBackgroundOpacity)
                        Label {
                            text: qsTr("Cancel")
                            anchors.centerIn: parent
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                    }
                    BackgroundItem {
                        onClicked: actionsRelay.accept();
                        width: parent.width / 2 - 5
                        contentHeight: Theme.itemSizeMedium
                        _backgroundColor: Theme.rgba(pressed ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor,
                                                     Theme.highlightBackgroundOpacity)
                        Label {
                            text: qsTr("Overwrite")
                            anchors.centerIn: parent
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                    }
                }

                Label {
                    id: label
                    text: qsTr("These files or folders already exist in “%1”:").arg(_currentDir)
                    wrapMode: Text.Wrap
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    color: Theme.highlightColor
                }
            }
        }

        delegate: Item {
            id: fileItem
            width: ListView.view.width
            height: listLabel.height

            Label {
                id: listLabel
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                text: modelData
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.primaryColor
            }
        }
    }

    Connections {
        target: engine
        onProgressChanged: progressPanel.text = engine.progressFilename
        onWorkerDone: progressPanel.hide()
        onWorkerErrorOccurred: {
            // the error signal goes to all pages in pagestack, show it only in the active one
            _successful = false;
            if (progressPanel.open) {
                progressPanel.hide();
                if (message === "Unknown error")
                    filename = qsTr("Trying to move between phone and SD Card? It does not work, try copying.");
                else if (message === "Failure to write block")
                    filename = qsTr("Perhaps the storage is full?");
                notificationPanel.showText(message, filename);
            }
        }
    }

    Connections {
        id: engineConnection
        target: null
        onWorkerDone: {
            if (!_finished) panel._doRecursiveTransfer();
            else _successful = true;
        }
    }

    Connections {
        id: mainConnections
        target: null
        onAccepted: {
            mainConnections.target = null
            overlayHidden(true);
            panel.visible = false;
            panel._doPaste();
        }
        onRejected: {
            mainConnections.target = null;
            overlayHidden(false);
            panel.visible = false;
            if (panel._toGo > 0) panel._doRecursiveTransfer();
            else _finished = true;
        }
    }

    Connections {
        id: afterTransferConnection
        target: null
        onOpenChanged: {
            if (target.open) return;
            target = null;
            navigate_goToFolder(targets[0]);
        }
    }

    function startTransfer(toTransfer, targetDirs, selectedAction, goToTarget) {
        page.backNavigation = false;
        page.forwardNavigation = false;
        panel.goToTarget = (goToTarget ? true : false);

        files = toTransfer;
        targets = targetDirs;
        action = selectedAction;

        _toGo = targets.length;
        _current = 0;
        _finished = false;
        _successful = false;

        _doRecursiveTransfer();
    }

    function _doRecursiveTransfer() {
        engineConnection.target = null;

        if (action === "copy") {
            FileClipboard.setPaths(files, FileClipMode.Copy)
        } else if (action === "move") {
            if (_toGo > 1) {
                // Copy! We don't want to remove the source files yet!
                FileClipboard.setPaths(files, FileClipMode.Copy)
            } else {
                FileClipboard.setPaths(files, FileClipMode.Cut)
            }
        } else if (action === "link") {
            FileClipboard.setPaths(files, FileClipMode.Link)
        }

        _currentDir = targets[_current]
        _toGo -= 1
        _current += 1

        var existingFiles = FileClipboard.listExistingFiles(_currentDir, true, true);

        if (existingFiles.length > 0) { // ask for permission to overwrite
            if (action === "link") {
                notificationPanel.showText(qsTr("Unable to overwrite existing file with symlink"), "");
                _successful = false;
                return;
            } else {
                mainConnections.target = actionsRelay;
                overlayShown()
                panel.visible = true;
            }
        } else { // everything's fine
            _doPaste();
        }
    }

    function _doPaste() {
        var panelText = ""

        if (action === "copy") {
            panelText = qsTr("Copying");
        } else if (action === "move") {
            panelText = qsTr("Moving");
        } else if (action === "link") {
            panelText = qsTr("Linking");
        }

        progressPanel.showText(panelText);

        engineConnection.target = engine;

        if (_toGo > 0) {
            _finished = false
        } else {
            _finished = true
        }

        engine.pasteFiles(
            FileClipboard.paths, _currentDir, FileClipboard.mode)
    }
}
