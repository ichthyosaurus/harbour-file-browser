/*
 * This file was taken and adapted from harbour-fotokopierer
 * by Frank Fischer, released under the GNU GPL v3+.
 * Original source can be found under
 * <https://chiselapp.com/user/fifr/repository/fotokopierer>.
 *
 * Copyright (c) 2018  Frank Fischer <frank-fischer@shadow-soft.de>
 *               2019  Mirian Margiani <mirian@margiani.ch>
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see  <http://www.gnu.org/licenses/>
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property alias title: title.text
    property alias path: image.source

    onStatusChanged: {
        if (page.status === PageStatus.Inactive && image.status === Image.Ready) {
            image.fitToScreen()
        }
    }

    Item {
        id: overlay
        z: 100
        anchors.fill: parent
        visible: false
        property bool isEditing: cropRotateRow.visible || drawRow.visible || writeRow.visible
        NumberAnimation { id: hideShowAnim; target: overlay; duration: 80; property: "opacity"; from: overlay.opacity }
        function show() { opacity = 0; visible = true; hideShowAnim.to = 1; hideShowAnim.start(); }
        function hide() { visible = true; hideShowAnim.to = 0; hideShowAnim.start(); visible = false; }
        onVisibleChanged: if (!visible) actions.visible = true; // reset visibility

        Rectangle {
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
                    right: actions.visible ? actions.left : parent.right
                }

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                truncationMode: TruncationMode.Fade
                horizontalAlignment: Text.AlignRight
                MouseArea {
                    anchors.fill: parent
                    Timer { id: resetTimer; interval: 3500; onTriggered: actions.visible = true; }
                    onClicked: { actions.visible = !actions.visible; resetTimer.start(); }
                }
            }

            Row {
                id: actions
                visible: true; opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 80 } }
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                    margins: Theme.paddingMedium
                }

                spacing: 0
                property int itemSize: 0.9*Theme.iconSizeMedium

                IconButton {
                    icon.width: parent.itemSize; icon.height: parent.itemSize
                    icon.source: "image://theme/icon-m-crop"
                    highlighted: cropRotateRow.visible || pressed
                    onClicked: {
                        cropRotateRow.visible = !cropRotateRow.visible
                        drawRow.visible = false
                        writeRow.visible = false
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
                    highlighted: drawRow.visible || pressed
                    onClicked: {
                        cropRotateRow.visible = false
                        drawRow.visible = !drawRow.visible
                        writeRow.visible = false
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
                    highlighted: writeRow.visible || pressed
                    onClicked: {
                        cropRotateRow.visible = false
                        drawRow.visible = false
                        writeRow.visible = !writeRow.visible
                    }

                    Rectangle {
                        visible: parent.highlighted
                        anchors.fill: parent; anchors.margins: 5
                        antialiasing: true
                        radius: (width / 2)
                        color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                    }
                }
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
                visible: false; opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 80 } }
                anchors.fill: parent

                onVisibleChanged: {
                    if (!visible) {
                        pinchArea.enabled = true;
                        pinchArea.zoomToScale(1);
                        return;
                    }
                    pinchArea.zoomToScale(Math.min((image.paintedHeight-2*cropAreaOverlay.radius)/image.paintedHeight,
                                                   (image.paintedWidth-2*cropAreaOverlay.radius)/image.paintedWidth));
                    pinchArea.enabled = false;
                }

                BackgroundItem {
                    width: cropRotateRow.width/3
                    anchors.left: parent.left; anchors.leftMargin: Theme.paddingMedium
                    anchors.verticalCenter: rotateBtn.verticalCenter
                    onClicked: cropRotateRow.visible = !cropRotateRow.visible
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
                    onClicked: image.rotation += 90
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
                visible: false; opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 80 } }
                anchors.fill: parent

                Label {
                    anchors.centerIn: parent
                    text: qsTr("not implemented yet")
                }
            }

            Item {
                id: writeRow
                visible: false; opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 80 } }
                anchors.fill: parent

                Label {
                    anchors.centerIn: parent
                    text: qsTr("not implemented yet")
                }
            }
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: imageView.width;
        contentHeight: imageView.height
        clip: true

        onHeightChanged: if (imageView.status === Image.Ready) imageView.fitToScreen();

        Item {
            id: imageView

            width: Math.max(image.width*image.scale, flickable.width)
            height: Math.max(image.height*image.scale, flickable.height)

            Image {
                id: image
                property real prevScale

                width: flickable.width
                height: flickable.height

                function fitToScreen() {
                    scale = Math.min(flickable.width / width, flickable.height / height, 1)
                    pinchArea.minScale = scale
                    prevScale = scale
                }

                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: !flickable.moving

                onStatusChanged: {
                    if (status === Image.Ready) {
                        fitToScreen()
                        loadedAnimation.start()
                    }
                }

                NumberAnimation {
                    id: loadedAnimation
                    target: image
                    property: "opacity"
                    duration: 250
                    from: 0; to: 1
                    easing.type: Easing.InOutQuad
                }

                onScaleChanged: {
                    if ((width * scale) > flickable.width) {
                        var xoff = (flickable.width / 2 + flickable.contentX) * scale / prevScale;
                        flickable.contentX = xoff - flickable.width / 2
                    }
                    if ((height * scale) > flickable.height) {
                        var yoff = (flickable.height / 2 + flickable.contentY) * scale / prevScale;
                        flickable.contentY = yoff - flickable.height / 2
                    }
                    prevScale = scale
                }

                BusyIndicator {
                    size: BusyIndicatorSize.Large
                    anchors.centerIn: parent
                    running: image.status !== Image.Ready
                }
            }
        }

        PinchArea {
            id: pinchArea

            property real minScale: 1.0
            property real maxScale: 3.0

            MouseArea {
                anchors.fill: parent
                Timer { id: timer; interval: 200; onTriggered: parent.singleClick() }
                onClicked: timer.start()
                property bool pinchRequested: false
                onDoubleClicked: {
                    pinchRequested = true
                    if (image.status !== Image.Ready || overlay.isEditing) return;
                    pinchArea.zoomToScale(pinchArea.minScale, true)
                }
                function singleClick() {
                    if (pinchRequested) {
                        pinchRequested = false;
                        return;
                    } else if (overlay.visible && overlay.isEditing) {
                        return;
                    } else if (overlay.visible) {
                        overlay.hide();
                    } else {
                        overlay.show();
                    }
                }
            }

            anchors.fill: parent
            enabled: image.status === Image.Ready
            pinch.target: image
            pinch.minimumScale: minScale * 0.5 // This is to create "bounce back effect"
            pinch.maximumScale: maxScale * 1.5 // when over zoomed

            onPinchFinished: {
                flickable.returnToBounds()
                if (image.scale < pinchArea.minScale) {
                    zoomToScale(pinchArea.minScale, false)
                }
                else if (image.scale > pinchArea.maxScale) {
                    zoomToScale(pinchArea.maxScale, false)
                }
            }

            function zoomToScale(newScale, quick) {
                if (quick === true) bounceBackAnimation.quick = true
                else bounceBackAnimation.quick = false
                bounceBackAnimation.to = newScale;
                bounceBackAnimation.start()
            }

            NumberAnimation {
                id: bounceBackAnimation
                target: image
                property bool quick: false
                duration: quick ? 150 : 250
                property: "scale"
                from: image.scale
            }
        }
    }

    Item {
        id: cropAreaOverlay
        anchors.fill: parent
        visible: cropRotateRow.visible
        property real radius: 0.8*(Theme.iconSizeMedium/2)

        Canvas {
            id: frame
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = Qt.rgba(0, 0, 0, 0.2);
                ctx.fillRect(0, 0, width, height)
                ctx.fillStyle = Qt.rgba(0, 0, 0, 0);
                ctx.globalCompositeOperation = "copy"
                ctx.strokeStyle = Theme.highlightColor
                ctx.beginPath()
                ctx.moveTo(topLeft.center.x, topLeft.center.y)
                ctx.lineTo(topRight.center.x, topRight.center.y)
                ctx.lineTo(bottomRight.center.x, bottomRight.center.y)
                ctx.lineTo(bottomLeft.center.x, bottomLeft.center.y)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }
        }

        CornerMarker {
            id: topLeft
            radius: parent.radius
            initialCenterX: (image.width - image.paintedWidth) / 2 + radius
            initialCenterY: (image.height - image.paintedHeight) / 2 + radius
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                bottomLeft.x = x; topRight.y = y;
                frame.requestPaint();
            }
        }

        CornerMarker {
            id: topRight
            radius: parent.radius
            initialCenterX: (image.width  + image.paintedWidth) / 2 - radius
            initialCenterY: (image.height - image.paintedHeight) / 2 + radius
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                bottomRight.x = x; topLeft.y = y;
                frame.requestPaint();
            }

        }

        CornerMarker {
            id: bottomLeft
            radius: parent.radius
            initialCenterX: (image.width  - image.paintedWidth) / 2 + radius
            initialCenterY: (image.height + image.paintedHeight) / 2 - radius
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                topLeft.x = x; bottomRight.y = y;
                frame.requestPaint();
            }

        }

        CornerMarker {
            id: bottomRight
            radius: parent.radius
            initialCenterX: (image.width  + image.paintedWidth) / 2 - radius
            initialCenterY: (image.height + image.paintedHeight) / 2 - radius
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                topRight.x = x; bottomLeft.y = y;
                frame.requestPaint();
            }
        }

        CornerMarker {
            id: topCenter
            radius: parent.radius
            beVCenter: true
            initialCenterX: image.width/2
            initialCenterY: (image.height - image.paintedHeight) / 2 + radius
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                topLeft.y = y; topRight.y = y;
                x = Math.min(topLeft.x, topRight.x)+Math.abs(topLeft.x-topRight.x)/2
                frame.requestPaint();
            }
        }

        CornerMarker {
            id: bottomCenter
            radius: parent.radius
            beVCenter: true
            initialCenterX: image.width/2
            initialCenterY: (image.height + image.paintedHeight) / 2 - radius
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                bottomLeft.y = y; bottomRight.y = y;
                x = Math.min(bottomLeft.x, bottomRight.x)+Math.abs(bottomLeft.x-bottomRight.x)/2
                frame.requestPaint();
            }
        }

        CornerMarker {
            id: leftCenter
            radius: parent.radius
            beHCenter: true
            initialCenterX: (image.width  - image.paintedWidth) / 2 + radius
            initialCenterY: image.height/2
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                bottomLeft.x = x; topLeft.x = x;
                y = Math.min(bottomLeft.y, topLeft.y)+Math.abs(bottomLeft.y-topLeft.y)/2
                frame.requestPaint();
            }
        }

        CornerMarker {
            id: rightCenter
            radius: parent.radius
            beHCenter: true
            initialCenterX: (image.width  + image.paintedWidth) / 2 - radius
            initialCenterY: image.height/2
            minX: (image.width - image.paintedWidth) / 2
            maxX: (image.width + image.paintedWidth) / 2 - 2*radius
            minY: (image.height - image.paintedHeight) / 2
            maxY: (image.height + image.paintedHeight) / 2 - 2*radius
            onCenterChanged: {
                if (!dragActive) return;
                bottomRight.x = x; topRight.x = x;
                y = Math.min(bottomRight.y, topRight.y)+Math.abs(bottomRight.y-topRight.y)/2
                frame.requestPaint();
            }
        }
    }
}
