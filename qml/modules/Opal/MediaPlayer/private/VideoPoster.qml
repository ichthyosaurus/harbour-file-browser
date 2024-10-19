//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-FileCopyrightText: 2013-2020 Leszek Lesner
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Nemo.Thumbnailer 1.0
//import QtGraphicalEffects 1.0

MouseArea {
    id: videoItem

    property MediaPlayer player
    property bool active
    property url source
    property string mimeType
    property int duration
    onDurationChanged: positionSlider.maximumValue = duration
    property alias controls: controls
    property alias position: positionSlider.value
    signal playClicked
    signal nextClicked
    signal prevClicked

    property bool autoplay

    property bool transpose

    property bool playing: active && videoItem.player && videoItem.player.playbackState == MediaPlayer.PlayingState
    readonly property bool _loaded: active
                                    && videoItem.player
                                    && videoItem.player.status >= MediaPlayer.Loaded
                                    && videoItem.player.status < MediaPlayer.EndOfMedia

    implicitWidth: poster.implicitWidth
    implicitHeight: poster.implicitHeight

    function ffwd(seconds) {
        ffwdRewRectAnim.secs = seconds
        ffwdRewRectAnim.isRew = false
        ffwdRewAnim.start()
        videoItem.player.seek((positionSlider.value*1000) + (seconds * 1000))
    }

    function rew(seconds) {
        ffwdRewRectAnim.secs = seconds
        ffwdRewRectAnim.isRew = true
        ffwdRewAnim.start()
        videoItem.player.seek((positionSlider.value*1000) - (seconds * 1000))
    }

    SequentialAnimation {
        id: ffwdRewAnim
        PropertyAction { target: ffwdRewRectAnim; property: "visible"; value: true }
        NumberAnimation { target: ffwdRewRectAnim; property: "opacity"; to: 1; duration: 200 }
        NumberAnimation { target: ffwdRewRectAnim; property: "opacity"; to: 0; duration: 200 }
        PropertyAction { target: ffwdRewRectAnim; property: "visible"; value: false }
    }

    Rectangle {
        id: ffwdRewRectAnim

        property int secs: 10
        property bool isRew: false

        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -1.5*Theme.iconSizeLarge
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: 1.5*Theme.iconSizeLarge * (isRew ? -1 : 1)
        }

        width: parent.width / 2
        color: Theme.backgroundGlowColor
        visible: false
        opacity: 0

        Label {
            anchors.centerIn: parent
            text: (parent.isRew ? "-" : "+") + Number(parent.secs).toFixed(0) + "s"
            font.pixelSize: Theme.fontSizeExtraLarge
        }
    }

    Connections {
        target: videoItem._loaded ? videoItem.player : null

        onPositionChanged: positionSlider.value = videoItem.player.position / 1000
        onDurationChanged: positionSlider.maximumValue = videoItem.player.duration / 1000
    }

    onActiveChanged: {
        if (!active) {
            positionSlider.value = 0
        }
    }

    // Poster
    Thumbnail {
        id: poster
        anchors.centerIn: parent

        width: Math.min(videoItem.width, videoItem.height)
        height: width
        sourceSize.width: width
        sourceSize.height: width

//        width: !videoItem.transpose ? videoItem.width : videoItem.height
//        height: !videoItem.transpose ? videoItem.height : videoItem.width

//        sourceSize.width: Screen.height
//        sourceSize.height: Screen.height

        source: videoItem.source
        mimeType: videoItem.mimeType

        priority: Thumbnail.HighPriority

        // this breaks it:
//        fillMode: Thumbnail.PreserveAspectFit

        opacity: (!videoItem._loaded && !autoplay) ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 80 } }

        visible: opacity > 0.0

        rotation: videoItem.transpose ? (implicitHeight > implicitWidth ? 270 : 90)  : 0
    }

    Item {
        id: controls
        width: videoItem.width
        height: videoItem.height

        z: 1000
        opacity: 0.0  // start hidden
        Behavior on opacity { FadeAnimation { duration: 80; id: controlFade } }
        visible: opacity > 0.0

        function forward(seconds) {
            ffwd(seconds)
        }

        function rewind(seconds) {
            rew(seconds)
        }

        property int _clickCount: 0

        Timer {
            id: multiClickTimer
            running: false
            interval: 1500
            onTriggered: stop()
            triggeredOnStart: false
        }

        CircleButton {
            anchors {
                verticalCenter: playPauseButton.verticalCenter
                right: playPauseButton.left
                rightMargin: Theme.paddingLarge
            }
            icon.source: "images/icon-m-rewind.png"
            grow: 0.8 * Theme.paddingLarge

            onClicked: {
                if (!ffwdRewRectAnim.isRew) {
                    controls._clickCount = 0
                    multiClickTimer.stop()
                }

                if (multiClickTimer.running) {
                    controls._clickCount += 1
                    controls.rewind(5 * controls._clickCount)
                } else {
                    controls._clickCount = 1
                    multiClickTimer.start()
                    controls.rewind(5)
                }
            }
        }

        CircleButton {
            id: playPauseButton
            anchors.centerIn: parent
            icon.source: _isPlaying ?
                "images/icon-m-pause.png" :
                "images/icon-m-play.png"
            grow: 1.5 * Theme.paddingLarge

            onClicked: {
                togglePlay()
            }
        }

        CircleButton {
            anchors {
                verticalCenter: playPauseButton.verticalCenter
                left: playPauseButton.right
                leftMargin: Theme.paddingLarge
            }
            icon.source: "images/icon-m-forward.png"
            grow: 0.8 * Theme.paddingLarge

            onClicked: {
                if (ffwdRewRectAnim.isRew) {
                    controls._clickCount = 0
                    multiClickTimer.stop()
                }

                if (multiClickTimer.running) {
                    controls._clickCount += 1
                    controls.forward(10 * controls._clickCount)
                } else {
                    controls._clickCount = 1
                    multiClickTimer.start()
                    controls.forward(10)
                }
            }
        }


        SilicaControl {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            visible: controls.opacity > 0
            enabled: visible
            opacity: controls.opacity
            height: Theme.itemSizeMedium + 2 * Theme.paddingLarge
            palette.colorScheme: Theme.LightOnDark

            Rectangle {
                z: -100
                anchors.fill: parent

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "black" } // black seems to look and work best
                }
            }

            IconButton {
                id: aspectBtn
                icon.source: "image://theme/icon-m-scale"
                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingMedium
                }
                width: visible ? Theme.iconSizeMedium : 0
                height: width
                visible: allowScaling
                onClicked: {
                    toggleAspectRatio();
                }
            }

            Label {
                id: maxTime
                visible: videoItem._loaded || !!text

                anchors {
                    right: aspectBtn.left
                    rightMargin: aspectBtn.visible ? Theme.paddingMedium : (2 * Theme.paddingLarge)
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingLarge
                }

                text: {
                    if (positionSlider.maximumValue > 3599) {
                        return Format.formatDuration(
                            positionSlider.maximumValue, Formatter.DurationLong)
                    } else {
                        return Format.formatDuration(
                            positionSlider.maximumValue, Formatter.DurationShort)
                    }
                }
            }

            IconButton {
                id: repeatBtn
                icon.source: isRepeat ?
                    "image://theme/icon-m-repeat" :
                    "image://theme/icon-m-forward"
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingMedium
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingMedium
                }
                width: Theme.iconSizeMedium
                height: width
                onClicked: {
                    isRepeat = !isRepeat
                }
            }

            IconButton {
                id: castBtn
                icon.source: "images/icon-m-cast.png"
                anchors {
                    left: repeatBtn.right
                    leftMargin: Theme.paddingMedium
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingMedium
                }
                width: visible ? Theme.iconSizeMedium : 0
                height: width
                visible: jupii.found
                onClicked: {
                    jupii.addUrlOnceAndPlay(
                        streamUrl.toString(), streamTitle,
                        "", (onlyMusic.visible ? 1 : 2), "OpalMediaPlayer",
                        Qt.resolvedUrl("images/icon-m-cast.png")
                            .toString().replace('file://', ''))
                }
            }

            Slider {
                id: positionSlider

                anchors {
                    left: castBtn.right
                    right: maxTime.left
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingLarge + Theme.paddingMedium
                }

                enabled: controls.opacity > 0.0
                height: Theme.itemSizeMedium
                handleVisible: down ? true : false
                minimumValue: 0

                valueText: {
                    if (value > 3599) {
                        return Format.formatDuration(
                            value, Formatter.DurationLong)
                    } else {
                        return Format.formatDuration(
                            value, Formatter.DurationShort)
                    }
                }

                onReleased: {
                    if (videoItem.active) {
                        videoItem.player.source = videoItem.source
                        videoItem.player.seek(value * 1000)
                        //videoItem.player.pause()
                    }
                }

//                onDownChanged: {
//                    if (down) {
//                        coverTime.visible = true
//                    }
//                    else
//                        coverTime.fadeOut.start()
//                }
            }
        }
    }
}
