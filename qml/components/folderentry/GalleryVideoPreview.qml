import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaItem {
    id: root

    opacity: highlighted ? Theme.opacityLow : 1.0

    HighlightImage {
        anchors.centerIn: parent
        height: Theme.iconSizeLarge
        width: height
        source: "image://theme/icon-l-play"
        fillMode: Image.PreserveAspectFit
    }
}
