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

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property alias title: header.title
    property alias path: image.source

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: imageView.width;
        contentHeight: imageView.height
        clip: true

        onHeightChanged: if (imageView.status === Image.Ready) imageView.fitToScreen();

        PageHeader { id: header }

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
                    print("hmm")
                    if (status === Image.Ready) {
                        fitToScreen()
                        loadedAnimation.start()
                        print("OK")
                    }
                }

                onSourceChanged: {
                    print(source)
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

            anchors.fill: parent
            enabled: image.status === Image.Ready
            pinch.target: image
            pinch.minimumScale: minScale * 0.5 // This is to create "bounce back effect"
            pinch.maximumScale: maxScale * 1.5 // when over zoomed

            onPinchFinished: {
                flickable.returnToBounds()
                if (image.scale < pinchArea.minScale) {
                    bounceBackAnimation.to = pinchArea.minScale
                    bounceBackAnimation.start()
                }
                else if (image.scale > pinchArea.maxScale) {
                    bounceBackAnimation.to = pinchArea.maxScale
                    bounceBackAnimation.start()
                }
            }

            NumberAnimation {
                id: bounceBackAnimation
                target: image
                duration: 250
                property: "scale"
                from: image.scale
            }
        }
    }
}
