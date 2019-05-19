import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    property alias title: titleLabel.text
    property alias open: viewGroup.open
    property alias titleHeight: viewGroup.height
    property Component contents
    property alias contentItem: loader.item

    width: parent.width
    height: viewGroup.height + contentItem.height
    Behavior on height { NumberAnimation { duration: 100 } }
    clip: true

    BackgroundItem {
        id: viewGroup
        width: parent.width
        height: Theme.itemSizeSmall
        property bool open: false
        onClicked: open = !open

        Label {
            id: titleLabel
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: moreImage.left
                rightMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }
            text: "View"
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
        }

        Image {
            id: moreImage
            anchors {
                right: parent.right
                rightMargin: Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }
            source: "image://theme/icon-m-right?" + Theme.highlightColor
            transformOrigin: Item.Center
            rotation: viewGroup.open ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: 100 } }
        }

        Rectangle {
            anchors.fill: parent
            z: -1 // behind everything
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    Item {
        id: contentItem
        width: parent.width
        height: visible ? loader.height : 0
        visible: viewGroup.open
        anchors.top: viewGroup.bottom

        Loader {
            id: loader
            width: parent.width
            sourceComponent: contents
        }
    }
}
