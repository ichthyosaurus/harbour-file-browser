import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property alias text: label.text
    property alias placeholderText: waiterLabel.text
    height: label.visible ? label.height : waiterLabel.height

    y: Theme.paddingSmall
    anchors {
        left: parent.horizontalCenter
        right: parent.right
        leftMargin: Theme.paddingSmall
        rightMargin: Theme.horizontalPageMargin
    }

    Label {
        id: label
        visible: !spinner.visible
        horizontalAlignment: Text.AlignLeft
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }

    BusyIndicator {
        id: spinner
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: parent.text === ""
        size: BusyIndicatorSize.ExtraSmall
        running: true
    }

    Label {
        id: waiterLabel
        visible: spinner.visible
        anchors.left: spinner.right
        anchors.leftMargin: Theme.paddingSmall
        horizontalAlignment: Text.AlignLeft
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }
}
