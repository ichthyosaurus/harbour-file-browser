import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: parent.width
    anchors.topMargin: Theme.paddingSmall
    height: sizeLabel.height+dirCountLabel.height+fileCountLabel.height

    property var files: []

    Label {
        id: title
        text: qsTr("Size")
        anchors {
            left: parent.left
            right: parent.horizontalCenter
            rightMargin: Theme.paddingSmall
            leftMargin: Theme.horizontalPageMargin
            top: parent.top
            bottom: fileCountLabel.bottom
        }
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignTop
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeSmall
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }

    SizeDetailItemPart {
        id: sizeLabel
        anchors.top: parent.top
        text: ""
        placeholderText: qsTr("size")
    }

    SizeDetailItemPart {
        id: dirCountLabel
        anchors.top: sizeLabel.bottom
        text: ""
        placeholderText: qsTr("directories")
    }

    SizeDetailItemPart {
        id: fileCountLabel
        anchors.top: dirCountLabel.bottom
        text: ""
        placeholderText: qsTr("files")
    }

    // TODO load size info asynchronously
    Component.onCompleted: {
        var sizes = engine.fileSizeInfo(files);
        sizeLabel.text = (sizes[0] === "-" ? qsTr("?? bytes") : sizes[0]);
        dirCountLabel.text = qsTr("%n directory/ies", "", parseInt(sizes[1], 10));
        fileCountLabel.text = qsTr("%n file(s)", "", parseInt(sizes[2], 10));
        print(sizes)
    }
}
