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
    property alias title: overlay.title
    property alias path: image.source

    onStatusChanged: {
        if (page.status === PageStatus.Inactive && image.status === Image.Ready) {
            image.fitToScreen()
        }
    }

    ImageEditOverlay {
        id: overlay
        anchors.fill: parent
        visible: false
        image: image
        pinch: pinchArea
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: imageView.width
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
                property alias imageRotation: imageRotation

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

                transform: [
                    Rotation {
                        id: imageRotation
                        origin { x: width/2; y: height/2 }

                        NumberAnimation on angle {
                            id: angleAnim; from: imageRotation.angle
                            onStopped: imageRotation.angle = to % 360
                        }

                        function rotateRight() {
                            angleAnim.to = angle+90;
                            angleAnim.duration = 150;
                            angleAnim.start();
                        }
                        function reset(to) {
                            if (Math.abs(angle-to) > 180) angleAnim.to = to+360;
                            else angleAnim.to = to;
                            angleAnim.duration = 150*(Math.abs((angle-angleAnim.to)/90));
                            angleAnim.start();
                        }
                    }
                ]
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
}
