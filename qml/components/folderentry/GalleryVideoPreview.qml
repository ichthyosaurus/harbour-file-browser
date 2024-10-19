import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0

SilicaItem {
    id: root
    property alias file: thumbnail.source

    height: thumbnail.status !== Thumbnail.Error ?
        thumbnail.height : Theme.itemSizeExtraLarge
    palette.colorScheme: Theme.LightOnDark

    Thumbnail {
        id: thumbnail
        opacity: highlighted ? Theme.opacityLow : 1.0
        width: Math.min(Screen.width, Screen.height)
        height: width
        sourceSize.width: width
        sourceSize.height: height
        priority: Thumbnail.NormalPriority
    }

    Rectangle {
        anchors {
            fill: playButton
            margins: -Theme.paddingLarge
        }
        radius: width
        color: Theme.rgba(
            highlighted ? Theme.highlightDimmerColor : "black",
            Theme.opacityLow)
        border.color: highlighted ?
            Theme.secondaryHighlightColor :
            Theme.secondaryColor
        border.width: 2
    }

    HighlightImage {
        id: playButton
        anchors.centerIn: parent
        source: "../../modules/Opal/MediaPlayer/private/images/icon-m-play.png"
    }
}
