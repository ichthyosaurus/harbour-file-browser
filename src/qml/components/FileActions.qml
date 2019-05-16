import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    width: isUpright ? Screen.width : Screen.height
    height: isUpright ? label.height+groupA.height : label.height

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
    signal propertyTriggered
    property bool displayClose: false

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
            icon.source: displayClose ? "image://theme/icon-m-close"
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
            onClicked: { propertyTriggered(); }
        }
    }
}
