/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * File Browser is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * File Browser is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property alias title: titleOverlay.title
    property alias path: image.source // deprecated
    property alias source: image.source

    readonly property Flickable flickable: flick
    readonly property bool editMode: false // not implemented

    onStatusChanged: {
        if (page.status === PageStatus.Inactive && image.status === Image.Ready) {
            image.fitToScreen()
        }
    }

    MediaTitleOverlay { id: titleOverlay }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: imageView.width
        contentHeight: imageView.height
        onHeightChanged: if (image.status === Image.Ready) image.fitToScreen();

        Item {
            id: imageView
            width: Math.max(image.width*image.scale, flick.width)
            height: Math.max(image.height*image.scale, flick.height)

            AnimatedImage {
                id: image
                property real prevScale
                property alias imageRotation: imageRotation

                function fitToScreen() {
                    scale = Math.min(flick.width / width, flick.height / height)
                    pinchArea.minScale = scale
                    pinchArea.maxScale = 4*Math.max(flick.width / width, flick.height / height)
                    prevScale = scale
                }

                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                cache: false
                asynchronous: true
                smooth: !flick.moving
                opacity: status === Image.Ready ? 1.0 : 0.0

                Behavior on opacity { FadeAnimator { duration: 250 } }

                onStatusChanged: {
                    if (status === Image.Ready) {
                        fitToScreen()
                        statusLoader.sourceComponent = undefined
                    } else if (status === Image.Loading) {
                        statusLoader.sourceComponent = loadingIndicator
                    } else if (status === Image.Error) {
                        statusLoader.sourceComponent = failedLoading
                    }
                }

                onScaleChanged: {
                    if ((width * scale) > flick.width) {
                        var xoff = (flick.width / 2 + flick.contentX) * scale / prevScale;
                        flick.contentX = xoff - flick.width / 2
                    }
                    if ((height * scale) > flick.height) {
                        var yoff = (flick.height / 2 + flick.contentY) * scale / prevScale;
                        flick.contentY = yoff - flick.height / 2
                    }
                    prevScale = scale
                    flick.returnToBounds();
                }

                transform: [
                    Rotation {
                        id: imageRotation
                        origin { x: image.width/2; y: image.height/2 }

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
                property bool pinchRequested: false

                anchors.fill: parent
                Timer { id: timer; interval: 200; onTriggered: parent.singleClick() }
                onClicked: timer.start()

                onDoubleClicked: {
                    pinchRequested = true
                    if (image.status !== Image.Ready) return;

                    var newScale = pinchArea.minScale;
                    if (Math.round(image.scale) === Math.round(pinchArea.minScale)) {
                        // image.fitToScreen() is called when the image is loaded. This makes
                        // sure that either height or width is fit to the flickable's corresponding
                        // side. We check which side fits and scale to the other.
                        if (Math.round(image.width*image.scale) === flick.width &&
                                Math.round(image.height*image.scale) === flick.height) {
                            newScale = pinchArea.maxScale // just zoom in if both sides fit exactly
                        } else if (Math.round(image.width*image.scale) === flick.width) {
                            newScale = (flick.height-5)/image.height
                        } else if (Math.round(image.height*image.scale) === flick.height) {
                            newScale = (flick.width-5)/image.width
                        }
                    } else {
                        newScale = pinchArea.minScale;
                    }

                    pinchArea.zoomToScale(newScale, true);
                }

                function singleClick() {
                    if (pinchRequested) {
                        pinchRequested = false;
                        return;
                    } else if (titleOverlay.visible) {
                        titleOverlay.hide();
                    } else {
                        titleOverlay.show();
                    }
                }
            }

            anchors.fill: parent
            enabled: image.status === Image.Ready
            pinch.target: image
            pinch.minimumScale: 0.5*minScale
            pinch.maximumScale: 1.5*maxScale

            onPinchFinished: {
                flick.returnToBounds()
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

    Loader {
        id: statusLoader
        anchors.centerIn: parent
        sourceComponent: undefined
    }

    Component {
        id: loadingIndicator

        Item {
            height: childrenRect.height
            width: page.width

            BusyIndicator {
                id: imageLoadingIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
            }

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: imageLoadingIndicator.bottom; topMargin: Theme.paddingLarge
                }
                font.pixelSize: Theme.fontSizeSmall;
                color: Theme.highlightColor;
                text: qsTr("Loading image... %1").arg(Math.round(image.progress*100) + "%")
            }
        }
    }

    Component {
        id: failedLoading
        Text {
            width: page.width - 2*Theme.horizontalPageMargin
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            font.pixelSize: Theme.fontSizeMedium
            text: qsTr("Error loading image")
            color: Theme.highlightColor
        }
    }
}
