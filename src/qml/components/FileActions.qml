import QtQuick 2.6
import Sailfish.Silica 1.0

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
    signal closeTriggered
    signal deleteTriggered
    signal archiveTriggered
    signal editTriggered
    property bool displayClose: false

    onSelectedCountChanged: {
        labelText = qsTr("%1 selected").arg(selectedCount)
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
            }
        }
        IconButton {
            visible: showCopy
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: "../images/toolbar-copy.png"
            onClicked: {
                var files = selectedFiles();
                engine.copyFiles(files);
                labelText = qsTr("%1 copied").arg(engine.clipboardCount);
            }
        }
        IconButton {
            visible: showDelete
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-delete"
            onClicked: { deleteTriggered(); }
        }
        IconButton {
            visible: showProperties
            enabled: selectedCount === 1; icon.width: itemSize; icon.height: itemSize
            icon.source: "../images/toolbar-properties.png"
            onClicked: {
                var files = selectedFiles();
                pageStack.push(Qt.resolvedUrl("../pages/FilePage.qml"), { file: files[0] });
            }
        }
    }

    FileActionsRow {
        id: groupB
        tiedTo: groupA

        IconButton {
            visible: showRename
            enabled: selectedCount === 1; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-font-size"
            onClicked: {
                var files = selectedFiles();
                var dialog = pageStack.push(Qt.resolvedUrl("../pages/RenameDialog.qml"),
                                            { path: files[0] })
                dialog.accepted.connect(function() {
                    if (dialog.errorMessage !== "") notificationPanel.showTextWithTimer(dialog.errorMessage, "");
                })
            }
        }
        IconButton {
            visible: showShare
            enabled: selectedCount === 1; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-share"
            onClicked: {
                var files = selectedFiles();
                pageStack.animatorPush("Sailfish.TransferEngine.SharePage", {
                    source: Qt.resolvedUrl(files[0]),
                    mimeType: "", // TODO
                    serviceFilter: ["sharing", "e-mail"]
                })
            }
        }
        IconButton {
            visible: showTransfer
            enabled: enabled; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-shuffle"
            onClicked: {
                var files = selectedFiles();
                var dialog = pageStack.push(Qt.resolvedUrl("../pages/TransferDialog.qml"),
                                            { toTransfer: files });
                dialog.accepted.connect(function() {
                    if (dialog.errorMessage === "") fileData.refresh(); // FIXME has to be in FilePage
                    else notificationPanel.showTextWithTimer(dialog.errorMessage, "");
                });
            }
        }
        IconButton {
            visible: showArchive
            enabled: false; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-file-archive-folder"
            onClicked: { archiveTriggered(); }
        }
        IconButton {
            visible: showEdit
            enabled: false; icon.width: itemSize; icon.height: itemSize
            icon.source: "image://theme/icon-m-edit"
            onClicked: { editTriggered(); }
        }
    }
}
