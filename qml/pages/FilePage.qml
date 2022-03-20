/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2016, 2018-2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2013 Michael Faro-Tusino
 * SPDX-FileCopyrightText: 2016 Joona Petrell
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

import QtQuick 2.5 // >= 2.5 required for Image::autoTransform
import Sailfish.Silica 1.0
import harbour.file.browser.FileData 1.0
import QtMultimedia 5.0

import "../components"
import "../js/paths.js" as Paths

Page {
    id: page
    allowedOrientations: Orientation.All
    property string file: "/"
    property alias notificationPanel: notificationPanel
    property bool _hasMoved: false

    FileData {
        id: fileData
        file: page.file
        property string category
        Component.onCompleted: category = typeCategory()
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { flickable: flickable }

        visible: !transferPanel.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        PullDownMenu {
            enabled: !_hasMoved
            MenuItem {
                text: qsTr("Change Permissions")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("PermissionsDialog.qml"),
                                                { path: page.file })
                    dialog.accepted.connect(function() {
                        if (dialog.errorMessage === "")
                            fileData.refresh();
                        else
                            notificationPanel.showTextWithTimer(dialog.errorMessage, "");
                    })
                }
            }

            MenuItem {
                text: qsTr("View Raw Contents")
                visible: !fileData.isDir
                onClicked: viewContents(false, true)
            }

            // open/install tries to open the file and fileData.onProcessExited shows error
            // if it fails
            MenuItem {
                text: (fileData.category === "rpm" || fileData.category === "apk") ? qsTr("Install") : qsTr("Open")
                visible: !fileData.isDir
                onClicked: {
                    if (!fileData.isSafeToOpen()) {
                        notificationPanel.showTextWithTimer(qsTr("File cannot be opened"),
                                                            qsTr("This type of file cannot be opened."));
                        return;
                    }

                    // note: we show the banner for all installable files because the install might
                    // otherwise silently fail.
                    if (Qt.openUrlExternally(page.file)) {
                        if (fileData.category === "rpm" || fileData.category === "apk") {
                            notificationPanel.showTextWithTimer(qsTr("Install launched"),
                                                                qsTr("If nothing happens, then the package is probably faulty.")+" "+
                                                                //: "it" = "the package", i.e. an RPM or APK file
                                                                qsTr("Swipe right to inspect its contents."));
                        } else {
                            notificationPanel.showTextWithTimer(qsTr("Open successful"),
                                                                qsTr("Sometimes the application stays in the background"));
                        }
                    } else {
                        // TODO verify that this works properly with any file, especially APK and RPM
                        notificationPanel.showTextWithTimer(qsTr("No application to open the file"), "");
                    }
                }
            }

            MenuItem {
                text: qsTr("Go to Target")
                visible: fileData.isSymLink && fileData.isDir
                onClicked: navigate_goToFolder(fileData.symLinkTarget);
            }
        }

        Column {
            id: column
            anchors { left: parent.left; right: parent.right }
            PageHeader { title: Paths.formatPathForTitle(fileData.absolutePath) }
            spacing: 0

            Label {
                // error label, visible if error message is set
                visible: fileData.errorMessage !== "" || _hasMoved
                anchors {
                    left: parent.left; right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                horizontalAlignment: Text.AlignHCenter
                text: !_hasMoved ? fileData.errorMessage : qsTr("The file has been moved.")
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            // file info texts, visible if error is not set
            Column {
                id: infoColumn
                visible: fileData.errorMessage === ""
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

                enabled: !_hasMoved
                opacity: enabled ? 1.0 : Theme.opacityLow

                // clickable icon and filename
                BackgroundItem {
                    id: openButton
                    x: -parent.x
                    width: parent.width + 2*parent.x
                    height: openArea.height
                    onClicked: playButton.visible ? playAudio() : viewContents(false, false)

                    Column {
                        id: openArea
                        x: infoColumn.x
                        width: parent.width - 2*infoColumn.x
                        spacing: 0

                        Spacer { height: Theme.paddingMedium }
                        IconButton {
                            id: playButton
                            visible: fileData.category === "audio"
                            icon.source: audioPlayer.playbackState !== MediaPlayer.PlayingState ?
                                             "image://theme/icon-l-play" :
                                             "image://theme/icon-l-pause"
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Theme.iconSizeLarge
                            onClicked: openButton.clicked(mouse)
                        }
                        Spacer { height: Theme.paddingMedium; visible: playButton.visible }

                        Image { // preview of image, max height 400
                            id: imagePreview
                            visible: fileData.category === "image"
                            source: visible ? fileData.file : ""
                            anchors { left: parent.left; right: parent.right }
                            sourceSize { width: parent.width; height: 4*Theme.itemSizeHuge }
                            width: parent.width
                            height: implicitHeight < (400*Theme.pixelRatio) && implicitHeight != 0
                                    ? implicitHeight*Theme.pixelRatio
                                    : 400*Theme.pixelRatio
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            autoTransform: true
                        }
                        FileIcon {
                            visible: !imagePreview.visible && !playButton.visible
                            anchors.horizontalCenter: parent.horizontalCenter
                            file: page.file
                            showThumbnail: visible
                            highlighted: openButton.highlighted
                            isDirectory: fileData.isDir
                            mimeTypeCallback: function() { return fileData.mimeType; }
                            fileIconCallback: function() { return fileData.icon; }
                            width: 128 * Theme.pixelRatio
                            height: width
                        }
                        Spacer { height: Theme.paddingMedium }
                        Label {
                            text: fileData.name
                            width: parent.width
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            highlighted: openButton.highlighted
                        }
                        Spacer { height: Theme.paddingSmall }
                        Label {
                            text: (fileData.isSymLinkBroken ?
                                       Paths.unicodeBrokenArrow() : Paths.unicodeArrow()
                                   )+" "+fileData.symLinkTarget
                            visible: fileData.isSymLink
                            width: parent.width
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: fileData.isSymLinkBroken ? Theme.secondaryHighlightColor :
                                    (openButton.highlighted ? Theme.highlightColor
                                                            : Theme.primaryColor)
                        }
                        Spacer { height: Theme.paddingMedium }
                    }
                }

                FileActions {
                    x: -parent.x
                    selectedFiles: function() { return [file] }
                    errorCallback: function(errorMsg) { notificationPanel.showTextWithTimer(errorMsg, ""); }
                    selectedCount: 1
                    labelText: ""
                    showProperties: false
                    showSelection: false
                    showShare: !fileData.isSymLink
                    showEdit: !fileData.isDir

                    onRenameTriggered: {
                        page.file = newFiles[0]
                        fileData.refresh();
                    }
                    onDeleteTriggered: {
                        remorsePopup.execute(qsTr("Deleting"), function() {
                            var prevPage = pageStack.previousPage();
                            console.log("mark as doomed:", page.file)
                            prevPage.markAsDoomed(page.file);
                            pageStack.pop();
                            if (prevPage.progressPanel) {
                                prevPage.progressPanel.showText(qsTr("Deleting"));
                            }
                            engine.deleteFiles([page.file]);
                        });
                    }
                    onTransferTriggered: {
                        if (selectedAction === "move") {
                            pageStack.completeAnimation();
                            var prevPage = pageStack.previousPage(page);
                            if (prevPage.progressPanel) transferPanel.progressPanel = prevPage.progressPanel;
                            if (prevPage.notificationPanel) transferPanel.notificationPanel = prevPage.notificationPanel;
                            if (prevPage.markAsDoomed) prevPage.markAsDoomed(toTransfer);
                            page._hasMoved = true;
                        }
                        transferPanel.startTransfer(toTransfer, targets, selectedAction, goToTarget);
                    }
                }
                Spacer { height: 2*Theme.paddingMedium }

                // Display metadata with priority < 5
                Repeater {
                    model: fileData.metaData
                    // first char is priority (0-9), labels and values are delimited with fileData.STRING_SEP
                    DetailItem {
                        visible: modelData.charAt(0) < '5'
                        label: modelData.substring(1, modelData.indexOf(fileData.STRING_SEP))
                        value: String(modelData.substring(
                                      modelData.indexOf(fileData.STRING_SEP)+1)).trim()
                    }
                }

                DetailItem {
                    label: qsTr("Location")
                    value: fileData.absolutePath
                }
                DetailItem {
                    label: qsTr("Type")
                    value: fileData.isSymLink
                                ? (fileData.isSymLinkBroken ? qsTr("Unknown (link target not found)") : qsTr("Link to %1").arg(fileData.mimeTypeComment) + "\n("+fileData.mimeType+")")
                                : fileData.mimeTypeComment + "\n("+fileData.mimeType+")"
                }
                SizeDetailItem {
                    files: [page.file]
                }
                DetailItem {
                    label: qsTr("Permissions")
                    value: fileData.permissions
                }
                DetailItem {
                    label: qsTr("Owner")
                    value: fileData.owner
                    visible: value !== ""
                }
                DetailItem {
                    label: qsTr("Group")
                    value: fileData.group
                    visible: value !== ""
                }
                DetailItem {
                    label: qsTr("Last modified")
                    value: fileData.modifiedLong
                    visible: value !== ""
                }
                // Display metadata with priority >= 5
                Repeater {
                    model: fileData.metaData
                    // first char is priority (0-9), labels and values are delimited with fileData.STRING_SEP
                    DetailItem {
                        visible: modelData.charAt(0) >= '5'
                        label: modelData.substring(1, modelData.indexOf(fileData.STRING_SEP))
                        value: String(modelData.substring(
                                      modelData.indexOf(fileData.STRING_SEP)+1)).trim()
                    }
                }
            }
        }
    }

    on_HasMovedChanged: {
        if (!_hasMoved) return;
        // File has moved away, so we disable any details
        // page. We can't use pageStack.popAttached because
        // it might be transitioning after a transfer action.
        canNavigateForward = false;
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            // update cover
            coverText = Paths.lastPartOfPath(page.file);
        } else if (status === PageStatus.Active) {
            if (!canNavigateForward) {
                viewContents(true);
            }
        }
    }

    MediaPlayer { id: audioPlayer; source: "" }
    RemorsePopup { id: remorsePopup }
    NotificationPanel { id: notificationPanel; page: page }
    ProgressPanel { id: progressPanel; page: page; onCancelled: engine.cancel() }
    TransferPanel {
        id: transferPanel
        page: page
        progressPanel: progressPanel
        notificationPanel: notificationPanel
    }

    function showConsolePage(method, command, arguments) {
        method(Qt.resolvedUrl("ConsolePage.qml"), {
                   title: Paths.lastPartOfPath(fileData.file),
                   command: command,
                   arguments: arguments,
                   fallbackFile: fileData.file
               });
    }

    function viewContents(asAttached, forceRawView) {
        if (fileData.isDir) {
            // dirs are special cases - there's no way to display their contents, so go to them
            if (asAttached === true) return; // don't try to switch to them in an attached page
            if (fileData.isSymLink) navigate_goToFolder(fileData.symLinkTarget);
            else navigate_goToFolder(fileData.file);
            return;
        }

        var method = pageStack.push;
        if (asAttached) method = pageStack.pushAttached;

        // view depending on file type
        if (forceRawView) {
            method(Qt.resolvedUrl("ViewPage.qml"), { path: page.file });
            return;
        } else if (fileData.category === "zip" || fileData.category === "apk") {
            showConsolePage(method, "unzip", [ "-Z", "-2ht", fileData.file ]);
        } else if (fileData.category === "rpm") {
            showConsolePage(method, "rpm", [ "-qlp", "--info", fileData.file ]);
        } else if (fileData.category === "tar") {
            showConsolePage(method, "tar", [ "tf", fileData.file ]);
        } else if (fileData.category === "sqlite3") {
            showConsolePage(method, "sqlite3", [ fileData.file, ".schema" ]);
        } else if (fileData.category === "image") {
            method(Qt.resolvedUrl("ViewImagePage.qml"), { path: page.file, title: fileData.name });
        } else if (fileData.category === "video") {
            method(Qt.resolvedUrl("ViewVideoPage.qml"), { path: page.file, title: fileData.name, autoPlay: !asAttached });
        } else if (pdfViewerEnabled && fileData.category === "pdf") {
            method(engine.pdfViewerPath(), {
                title: fileData.name, source: fileData.file, mimeType: fileData.mimeType
            })
        } else {
            method(Qt.resolvedUrl("ViewPage.qml"), { path: page.file });
        }
    }

    function playAudio() {
        if (audioPlayer.playbackState !== MediaPlayer.PlayingState) {
            audioPlayer.source = fileData.file;
            audioPlayer.play();
        } else {
            audioPlayer.stop();
        }
    }
}
