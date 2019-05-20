import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: overlay
    z: 100
    anchors.fill: parent
    visible: false

    property bool isEditing: cropEnabled || drawEnabled || writeEnabled
    property bool cropEnabled: false
    property bool drawEnabled: false
    property bool writeEnabled: false
    property alias title: title.text
    property var image
    property PinchArea pinch

    NumberAnimation { id: showAnim; target: overlay; duration: 80; property: "opacity"; to: 1.0; from: target.opacity;
        onStarted: target.visible = true; }
    NumberAnimation { id: hideAnim; target: overlay; duration: 80; property: "opacity"; to: 0.0; from: target.opacity;
        onStopped: target.visible = false }
    function show() { showAnim.start(); }
    function hide() { hideAnim.start(); }

    onVisibleChanged: if (!visible) actions.state = "shown"; // reset visibility

    CropAreaOverlay {
        id: cropAreaOverlay
        anchors.fill: parent
        visible: overlay.cropEnabled
        image: parent.image
    }

    Rectangle {
        id: topRow
        MouseArea { anchors.fill: parent }  // catch stray clicks

        anchors.top: parent.top
        height: 1.5*Theme.itemSizeLarge
        width: parent.width

        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.5) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        Label {
            id: title
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                margins: Theme.horizontalPageMargin
                right: actions.left
            }

            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            truncationMode: TruncationMode.Fade
            horizontalAlignment: Text.AlignRight
            MouseArea { anchors.fill: parent; onClicked: { actions.toggleVisible(); } }
        }

        Row {
            id: actions
            visible: true
            state: "shown"

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: Theme.paddingMedium
            }

            function toggleVisible() { if (state === "shown") state = "hidden"; else state = "shown"; }

            spacing: 0
            property int itemSize: 0.9*Theme.iconSizeMedium

            IconButton {
                icon.width: parent.itemSize; icon.height: parent.itemSize
                icon.source: "image://theme/icon-m-crop"
                highlighted: cropEnabled || pressed
                onClicked: {
                    cropEnabled = !cropEnabled
                    drawEnabled = false
                    writeEnabled = false
                }

                Rectangle {
                    visible: parent.highlighted
                    anchors.fill: parent; anchors.margins: 5
                    antialiasing: true
                    radius: (width / 2)
                    color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                }
            }
            IconButton {
                icon.width: parent.itemSize; icon.height: parent.itemSize
                icon.source: "image://theme/icon-m-edit"
                highlighted: drawEnabled || pressed
                onClicked: {
                    cropEnabled = false
                    drawEnabled = !drawEnabled
                    writeEnabled = false
                }

                Rectangle {
                    visible: parent.highlighted
                    anchors.fill: parent; anchors.margins: 5
                    antialiasing: true
                    radius: (width / 2)
                    color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                }
            }
            IconButton {
                icon.width: parent.itemSize; icon.height: parent.itemSize
                icon.source: "image://theme/icon-m-text-input"
                highlighted: writeEnabled || pressed
                onClicked: {
                    cropEnabled = false
                    drawEnabled = false
                    writeEnabled = !writeEnabled
                }

                Rectangle {
                    visible: parent.highlighted
                    anchors.fill: parent; anchors.margins: 5
                    antialiasing: true
                    radius: (width / 2)
                    color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                }
            }

            states: [
                State { name: "shown";  AnchorChanges { target: actions; anchors.right: topRow.right; anchors.left: undefined; } },
                State { name: "hidden"; AnchorChanges { target: actions; anchors.left: topRow.right; anchors.right: undefined; } }
            ]

            transitions: Transition { AnchorAnimation { duration: 200 } }
        }
    }

    Rectangle {
        MouseArea { anchors.fill: parent }  // catch stray clicks
        anchors.bottom: parent.bottom
        height: 1.5*Theme.itemSizeLarge
        width: parent.width

        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.6) }
        }

        Item {
            id: cropRotateRow
            visible: cropEnabled; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 80 } }
            anchors.fill: parent
            property int sourceRotation: 0
            Component.onCompleted: sourceRotation = (image.imageRotation.angle % 360);

            onVisibleChanged: {
                if (!pinch) return;
                if (!visible) {
                    pinch.enabled = true;
                    pinch.zoomToScale(1);
                    return;
                }
                pinch.zoomToScale(Math.min((image.paintedHeight-2*cropAreaOverlay.radius)/image.paintedHeight,
                                               (image.paintedWidth-2*cropAreaOverlay.radius)/image.paintedWidth));
                pinch.enabled = false;
            }

            BackgroundItem {
                width: cropRotateRow.width/3
                anchors.left: parent.left; anchors.leftMargin: Theme.paddingMedium
                anchors.verticalCenter: rotateBtn.verticalCenter
                onClicked: { cropEnabled = !cropEnabled; image.imageRotation.angle = parent.sourceRotation; }
                Label {
                    text: qsTr("Cancel")
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    horizontalAlignment: Text.AlignRight
                    anchors.centerIn: parent
                }
            }
            IconButton {
                id: rotateBtn
                icon.width: Theme.iconSizeMedium; icon.height: Theme.iconSizeMedium
                icon.source: "image://theme/icon-m-sync"
                anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.paddingMedium; anchors.horizontalCenter: parent.horizontalCenter
                onClicked: image.imageRotation.angle = (image.imageRotation.angle+90) % 360
            }
            BackgroundItem {
                width: cropRotateRow.width/3
                anchors.right: parent.right; anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: rotateBtn.verticalCenter
                Label {
                    text: qsTr("Apply")
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    horizontalAlignment: Text.AlignLeft
                    anchors.centerIn: parent
                }
            }
        }

        Item {
            id: drawRow
            visible: drawEnabled; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 80 } }
            anchors.fill: parent

            Label {
                anchors.centerIn: parent
                text: qsTr("not implemented yet")
            }
        }

        Item {
            id: writeRow
            visible: writeEnabled; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 80 } }
            anchors.fill: parent

            Label {
                anchors.centerIn: parent
                text: qsTr("not implemented yet")
            }
        }
    }
}
