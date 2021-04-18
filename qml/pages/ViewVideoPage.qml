/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020-2021 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later OR AGPL-3.0-or-later
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import "../components"

// TODO video controls
// TODO attached info page

Page {
    id: page
    allowedOrientations: Orientation.All
    property alias title: titleOverlay.title
    property alias path: video.source
    property alias autoPlay: video.autoPlay
    property bool enableDarkBackground: true
    property bool _isPlaying: video.playbackState === MediaPlayer.PlayingState
    property string _errorString

    Loader {
        sourceComponent: enableDarkBackground ? backgroundComponent : null
        anchors.fill: parent
        Component {
            id: backgroundComponent
            Rectangle {
                visible: enableDarkBackground
                color: Theme.overlayBackgroundColor
                opacity: Theme.opacityHigh
            }
        }
    }

    MediaTitleOverlay {
        id: titleOverlay
        shown: !autoPlay

        IconButton {
            anchors.centerIn: parent
            icon.source: "image://theme/icon-l-play?" + (pressed
                         ? Theme.highlightColor
                         : Theme.primaryColor)
            onClicked: mouseArea.onClicked("")
        }

        Rectangle {
            // TODO find a more elegant solution to make
            // this stay below the overlay but above the video
            z: parent.z - 1000
            anchors.fill: parent
            color: Theme.rgba("bbbbbb", 0.5)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            if (_isPlaying === true) {
                titleOverlay.show();
                video.pause();
            } else {
                titleOverlay.hide();
                video.play();
            }
        }
    }

    // Whisperfish related issue (works in File Browser):
    // Video playback is partly broken. Showing anything only works if
    // autoPlay is true, but play/pause does not work even though the
    // media player changes its playbackState property correctly.
    // Looping is not possible. (This may be related to WF#158.)
    Video {
        id: video
        anchors.fill: parent
        autoPlay: true // TODO set to false once possible
        fillMode: VideoOutput.PreserveAspectFit
        muted: false
        onStopped: play() // we have to restart manually because
                          // seamless looping is only available since Qt 5.13
        onErrorChanged: {
            if (error === MediaPlayer.NoError) return;
            // we don't want to risk crashes by trying any further
            console.log("playing video failed:", errorString)
            _errorString = errorString
            source = ""
            loader.sourceComponent = failedLoading
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        Component {
            id: failedLoading
            BusyLabel {
                //: Full page placeholder shown when a video failed to load
                //% "Failed to play"
                text: qsTrId("whisperfish-view-video-page-error") +
                      "\n\n" + _errorString
                running: false
            }
        }
    }
}
