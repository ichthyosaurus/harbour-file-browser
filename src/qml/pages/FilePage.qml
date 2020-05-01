import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileData 1.0
import harbour.file.browser.ConsoleModel 1.0
import QtMultimedia 5.0

import "../components"
import "../js/navigation.js" as Navigation
import "../js/paths.js" as Paths

Page {
    id: page
    allowedOrientations: Orientation.All
    property string file: "/"
    property alias notificationPanel: notificationPanel

    FileData {
        id: fileData
        file: page.file
        property string category
        Component.onCompleted: category = typeCategory()
    }

    RemorsePopup {
        id: remorsePopup
    }

    ConsoleModel {
        id: consoleModel

        // called when open command exits
        onProcessExited: {
            if (exitCode === 0) {
                if (fileData.category === "apk") {
                    notificationPanel.showTextWithTimer(qsTr("Install launched"),
                                               qsTr("If nothing happens, then the package is probably faulty."));
                    return;
                }
                if (!fileData.category !== "rpm")
                    notificationPanel.showTextWithTimer(qsTr("Open successful"),
                                               qsTr("Sometimes the application stays in the background"));
            } else if (exitCode === 1) {
                notificationPanel.showTextWithTimer(qsTr("Internal error"),
                                               "xdg-open exit code 1");
            } else if (exitCode === 2) {
                notificationPanel.showTextWithTimer(qsTr("File not found"),
                                               page.file);
            } else if (exitCode === 3) {
                notificationPanel.showTextWithTimer(qsTr("No application to open the file"),
                                               qsTr("xdg-open found no preferred application"));
            } else if (exitCode === 4) {
                notificationPanel.showTextWithTimer(qsTr("Action failed"),
                                               "xdg-open exit code 4");
            } else if (exitCode === -88888) {
                notificationPanel.showTextWithTimer(qsTr("xdg-open not found"), "");

            } else if (exitCode === -99999) {
                notificationPanel.showTextWithTimer(qsTr("xdg-open crash?"), "");

            } else {
                notificationPanel.showTextWithTimer(qsTr("xdg-open error"), "exit code: "+exitCode);
            }
        }
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
                text: fileData.category === "rpm" || fileData.category === "apk" ? qsTr("Install") : qsTr("Open")
                visible: !fileData.isDir
                onClicked: {
                    if (!fileData.isSafeToOpen()) {
                        notificationPanel.showTextWithTimer(qsTr("File cannot be opened"),
                                                   qsTr("This type of file cannot be opened."));
                        return;
                    }
                    consoleModel.executeCommand("xdg-open", [ page.file ])
                }
            }

            MenuItem {
                text: qsTr("Go to Target")
                visible: fileData.isSymLink && fileData.isDir
                onClicked: Navigation.goToFolder(fileData.symLinkTarget);
            }
        }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                title: Paths.formatPathForTitle(fileData.absolutePath)
            }

            // file info texts, visible if error is not set
            Column {
                visible: fileData.errorMessage === ""
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

                IconButton {
                    id: playButton
                    visible: fileData.category === "audio"
                    icon.source: audioPlayer.playbackState !== MediaPlayer.PlayingState ?
                                     "image://theme/icon-l-play" :
                                     "image://theme/icon-l-pause"
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: playAudio();
                    MediaPlayer { // prelisten of audio
                        id: audioPlayer
                        source: ""
                    }
                }
                Spacer { height: Theme.paddingMedium; visible: playButton.visible } // fix to playButton height
                // clickable icon and filename
                BackgroundItem {
                    id: openButton
                    width: parent.width
                    height: openArea.height
                    onClicked: quickView()

                    Column {
                        id: openArea
                        width: parent.width

                        Image { // preview of image, max height 400
                            id: imagePreview
                            visible: fileData.category === "image"
                            source: visible ? fileData.file : "" // access source only if image is visible
                            anchors.left: parent.left
                            anchors.right: parent.right
                            sourceSize.width: parent.width
                            sourceSize.height: 4*Theme.itemSizeHuge
                            width: parent.width
                            height: implicitHeight < 400 * Theme.pixelRatio && implicitHeight != 0
                                    ? implicitHeight * Theme.pixelRatio
                                    : 400 * Theme.pixelRatio
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        // HighlightImage replaced with a Loader so that HighlightImage or Image
                        // can be loaded depending on Sailfish version (lightPrimaryColor is defined on SF3)
                        Loader {
                            id: icon
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: !imagePreview.visible && !playButton.visible
                            width: 128 * Theme.pixelRatio
                            height: 128 * Theme.pixelRatio
                            Component.onCompleted: {
                                var qml = Theme.lightPrimaryColor ? "../components/HighlightImageSF3.qml"
                                                                  : "../components/HighlightImageSF2.qml";
                                setSource(qml, {
                                    imgsrc: "../images/large-"+fileData.icon+".png",
                                    imgw: 128 * Theme.pixelRatio,
                                    imgh: 128 * Theme.pixelRatio
                                })
                            }
                        }
                        Spacer { // spacing if image or play button is visible
                            id: spacer
                            height: 24
                            visible: imagePreview.visible || playButton.visible
                        }
                        Label {
                            id: filename
                            width: parent.width
                            text: fileData.name
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            color: openButton.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            visible: fileData.isSymLink
                            width: parent.width
                            text: Paths.unicodeArrow()+" "+fileData.symLinkTarget
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: fileData.isSymLinkBroken ? "red" :
                                    (openButton.highlighted ? Theme.highlightColor
                                                            : Theme.primaryColor)
                        }
                        Spacer { height: Theme.paddingLarge }
                    }
                }

                FileActions {
                    x: -parent.x
                    selectedFiles: function() {
                        return [file];
                    }
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
                            pageStack.pop();
                            if (prevPage.progressPanel) prevPage.progressPanel.showText(qsTr("Deleting"));
                            engine.deleteFiles([page.file]);
                        });
                    }
                    onTransferTriggered: {
                        if (selectedAction === "move") {
                            var prevPage = pageStack.previousPage();
                            if (prevPage.progressPanel) transferPanel.progressPanel = prevPage.progressPanel;
                            if (prevPage.notificationPanel) transferPanel.notificationPanel = prevPage.notificationPanel;
                            pageStack.pop();
                        }

                        transferPanel.startTransfer(toTransfer, targets, selectedAction, goToTarget);
                    }
                }

                // Display metadata with priority < 5
                Repeater {
                    model: fileData.metaData
                    // first char is priority (0-9), labels and values are delimited with ':'
                    DetailItem {
                        visible: modelData.charAt(0) < '5'
                        label: modelData.substring(1, modelData.indexOf(":"))
                        value: String(modelData.substring(modelData.indexOf(":")+1)).trim()
                    }
                }

                DetailItem {
                    label: qsTr("Location")
                    value: fileData.absolutePath
                }
                DetailItem {
                    label: qsTr("Type")
                    value: fileData.isSymLink
                           ? qsTr("Link to %1").arg(fileData.mimeTypeComment) + "\n("+fileData.mimeType+")"
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
                }
                DetailItem {
                    label: qsTr("Group")
                    value: fileData.group
                }
                DetailItem {
                    label: qsTr("Last modified")
                    value: fileData.modifiedLong
                }
                // Display metadata with priority >= 5
                Repeater {
                    model: fileData.metaData
                    // first char is priority (0-9), labels and values are delimited with ':'
                    DetailItem {
                        visible: modelData.charAt(0) >= '5'
                        label: modelData.substring(1, modelData.indexOf(":"))
                        value: String(modelData.substring(modelData.indexOf(":")+1)).trim()
                    }
                }
            }

            // error label, visible if error message is set
            Label {
                visible: fileData.errorMessage !== ""
                anchors.left: parent.left
                anchors.right: parent.right
                horizontalAlignment: Text.AlignHCenter
                text: fileData.errorMessage
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }
        }
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

    function quickView() {
        viewContents();
    }

    function viewContents(asAttached, forceRawView) {
        // dirs are special cases - there's no way to display their contents, so go to them
        if (fileData.isDir) {
            if (asAttached === true) return; // don't try to switch to them in an attached page

            if (fileData.isSymLink) {
                Navigation.goToFolder(fileData.symLinkTarget);
            } else {
                Navigation.goToFolder(fileData.file);
            }
            return;
        }

        var method;

        if (asAttached) {
            method = pageStack.pushAttached;
        } else {
            method = pageStack.push;
        }

        // view depending on file type
        if (forceRawView) {
            method(Qt.resolvedUrl("ViewPage.qml"), { path: page.file });
            return;
        }

        if (fileData.category === "zip") {
            method(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Paths.lastPartOfPath(fileData.file),
                           command: "unzip",
                           arguments: [ "-Z", "-2ht", fileData.file ] });

        } else if (fileData.category === "rpm") {
            method(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Paths.lastPartOfPath(fileData.file),
                           command: "rpm",
                           arguments: [ "-qlp", "--info", fileData.file ] });

        } else if (fileData.category === "tar") {
            method(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Paths.lastPartOfPath(fileData.file),
                           command: "tar",
                           arguments: [ "tf", fileData.file ] });
        } else if (fileData.category === "image") {
            method(Qt.resolvedUrl("ViewImagePage.qml"), { path: page.file, title: fileData.name });
        } else if (fileData.category === "video") {
            method(Qt.resolvedUrl("ViewVideoPage.qml"), { path: page.file, title: fileData.name, autoPlay: !asAttached });
        } else if (pdfViewerEnabled && fileData.category === "pdf") {
            method("Sailfish.Office.PDFDocumentPage", {
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
