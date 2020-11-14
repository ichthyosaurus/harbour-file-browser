import QtQuick 2.2
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property alias title: titleOverlay.title
    property alias path: video.source
    property alias autoPlay: video.autoPlay
    property bool _isPlaying: autoPlay

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
                _isPlaying = false;
                titleOverlay.show();
                video.pause();
            } else {
                titleOverlay.hide();
                _isPlaying = true;
                video.play();
            }
        }
    }

    Video {
        id: video
        anchors.fill: parent
        autoPlay: false
        fillMode: VideoOutput.PreserveAspectFit
        muted: false
        onStopped: play() // we have to do it manually because
                          // seamless looping is only available since Qt 5.13
    }

    // TODO implement video error handling
}
