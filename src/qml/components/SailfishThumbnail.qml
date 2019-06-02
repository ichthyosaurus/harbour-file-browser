import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0

Item {
    id: base
    property bool highlighted
    property alias source: thumbnail.source
    property int size: Theme.itemSizeHuge
    width: size
    height: size

    Thumbnail {
        id: thumbnail
        width: size
        height: size
        sourceSize.width: width
        sourceSize.height: height
        priority: Thumbnail.NormalPriority

        onStatusChanged: {
            if (status === Thumbnail.Error) {
                errorLabelComponent.createObject(thumbnail)
            }
        }
    }

    Component {
        id: errorLabelComponent
        Label {
            text: qsTr("No thumbnail available")
            anchors.centerIn: parent
            width: base.width - 2 * Theme.paddingMedium
            height: base.height - 2 * Theme.paddingSmall
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            fontSizeMode: Text.Fit
        }
    }
}
