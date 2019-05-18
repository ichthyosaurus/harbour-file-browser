import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.file.browser.FileData 1.0

Item {
    width: isUpright ? Screen.width : Screen.height
    height: isUpright ? label.height+groupA.height+groupB.height : label.height

    property var selectedFiles: function() {
        // function returning a list of selected files (has to be provided)
        console.log("error: missing implementation of FileActions::selectedFiles()!")
        return -1;
    }
    property int selectedCount: 0
    property alias labelText: label.text
    property bool isUpright: main.orientation === Orientation.Portrait ||
                             main.orientation === Orientation.PortraitInverted
    property int itemSize: Theme.iconSizeMedium
    property bool enabled: true
    property bool showLabel: true
    property bool displayClose: false

    property bool showSelection: true
    property bool showCut: true
    property bool showCopy: true
    property bool showDelete: true
    property bool showProperties: true

    property bool showRename: true
    property bool showShare: true
    property bool showTransfer: true
    property bool showArchive: true
    property bool showEdit: true

    signal selectAllTriggered
    signal cutTriggered
    signal copyTriggered
    signal deleteTriggered
    signal closeTriggered
    signal propertiesTriggered
    signal renameTriggered(var oldFiles, var newFiles)
    signal shareTriggered
    signal transferTriggered(var toTransfer, var targets, var selectedAction, var goToTarget)
    signal compressTriggered
    signal extractTriggered
    signal editTriggered

    onSelectedCountChanged: {
        labelText = qsTr("%1 selected").arg(selectedCount)
    }

    FileData {
        id: fileData
    }

    Label {
        id: label
        visible: showLabel
        height: isUpright ? itemSize : itemSize+Theme.paddingLarge
        width: isUpright ? parent.width : 2*Theme.itemSizeLarge
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
    }

    FileActionsRow {
        id: groupA
        tiedTo: label

        IconButton {
            visible: showSelection
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: displayClose ? "image://theme/icon-m-clear"
                                      : "../images/toolbar-select-all.png"
            onPressAndHold: {
                if (displayClose) labelText = qsTr("clear selection");
                else labelText = qsTr("select all");
            }
            onClicked: { displayClose ? closeTriggered() : selectAllTriggered(); }
        }
        IconButton {
            visible: showCut
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: "../images/toolbar-cut.png"
            onClicked: {
                var files = selectedFiles();
                engine.cutFiles(files);
                labelText = qsTr("%1 cut").arg(engine.clipboardCount);
                cutTriggered();
            }
            onPressAndHold: labelText = qsTr("cut files")
        }
        IconButton {
            visible: showCopy
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: "../images/toolbar-copy.png"
            onPressAndHold: labelText = qsTr("copy files")
            onClicked: {
                var files = selectedFiles();
                engine.copyFiles(files);
                labelText = qsTr("%1 copied").arg(engine.clipboardCount);
                copyTriggered();
            }
        }
        IconButton {
            visible: showTransfer
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-shuffle"
            onPressAndHold: labelText = qsTr("transfer files")
            onClicked: {
                var files = selectedFiles();
                var dialog = pageStack.push(Qt.resolvedUrl("../pages/TransferDialog.qml"),
                                            { toTransfer: files });
                dialog.accepted.connect(function() {
                    if (dialog.errorMessage === "") {
                        transferTriggered(dialog.toTransfer, dialog.targets, dialog.selectedAction, dialog.goToTarget);
                    } else {
                        notificationPanel.showTextWithTimer(dialog.errorMessage, "");
                    }
                });
            }
        }
        IconButton {
            visible: showDelete
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-delete"
            onPressAndHold: labelText = qsTr("delete files")
            onClicked: { deleteTriggered(); }
        }
    }

    FileActionsRow {
        id: groupB
        tiedTo: groupA

        IconButton {
            visible: showRename
            enabled: selectedCount === 1; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-font-size"
            onPressAndHold: labelText = qsTr("rename files")
            onClicked: {
                var files = selectedFiles();
                var dialog = pageStack.push(Qt.resolvedUrl("../pages/RenameDialog.qml"),
                                            { path: files[0] })
                dialog.accepted.connect(function() {
                    if (dialog.errorMessage !== "") notificationPanel.showTextWithTimer(dialog.errorMessage, "");
                    renameTriggered(files, [dialog.newPath]);
                })
            }
        }
        IconButton {
            visible: showShare
            // sadly, SharePage can only handle one sole single lone and lonely orientation
            enabled: selectedCount === 1 && main.orientation === Orientation.Portrait
            icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-share"
            onPressAndHold: labelText = qsTr("share files")
            onClicked: {
                var files = selectedFiles();
                fileData.file = files[0];
                fileData.refresh();
                pageStack.animatorPush("Sailfish.TransferEngine.SharePage", {
                    source: Qt.resolvedUrl(files[0]),
                    mimeType: fileData.mimeType,
                    serviceFilter: ["sharing", "e-mail"]
                })
                shareTriggered();
            }
        }
        IconButton { // NOT IMPLEMENTED YET
            visible: showArchive && false
            enabled: false; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-file-archive-folder"
            onClicked: { compressTriggered(); }
            onPressAndHold: {
                labelText = qsTr("compress files")
                // labelText = qsTr("extract archive")
            }
        }
        IconButton { // NOT IMPLEMENTED YET
            visible: showEdit && false
            enabled: false; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-edit"
            onPressAndHold: labelText = qsTr("edit files")
            onClicked: { editTriggered(); }
        }
        IconButton {
            visible: showProperties
            enabled: selectedCount === 1; icon.width: itemSize; icon.height: itemSize
            icon.source: "../images/toolbar-properties.png"
            onPressAndHold: labelText = qsTr("show file properties")
            onClicked: {
                var files = selectedFiles();
                pageStack.push(Qt.resolvedUrl("../pages/FilePage.qml"), { file: files[0] });
                propertiesTriggered();
            }
        }
    }
}
