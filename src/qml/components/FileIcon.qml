import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0

// a file icon or thumbnail for directory listings
// NOTE index, fileModel, fileIcon, and isDir have to be provided by the parent / context
Item {
    id: base
    property string file: ""
    property bool showThumbnail: false
    property bool highlighted: false

    Component.onCompleted: refresh();
    onShowThumbnailChanged: refresh();

    property bool ready: false
    property int _thumbnailSize: base.width

    Component {
        id: thumbnailComponent
        ThumbnailImage {
            id: img
            source: base.file
            size: _thumbnailSize
            mimeType: fileModel ? fileModel.mimeTypeAt(index) : ""
            property alias highlighted: img.down
        }
    }

    function refresh() {
        ready = false;
        var canThumb = true;

        if (showThumbnail) {
            if (isDir) {
                canThumb = false
            } else if (fileModel) {
                var mimeType = fileModel.mimeTypeAt(index)

                if (   mimeType.indexOf("image/") === -1
                    && mimeType.indexOf("application/pdf") === -1) {
                    canThumb = false
                }
            }
            showThumbnail = canThumb;
        }

        if (showThumbnail) {
            listIcon.source = ""
            thumbnail.sourceComponent = thumbnailComponent
        } else {
            if (!fileIcon) return;
            thumbnail.source = ""
            var qmlIcon = Theme.lightPrimaryColor ? "../components/HighlightImageSF3.qml"
                                              : "../components/HighlightImageSF2.qml";
            listIcon.setSource(qmlIcon, {
                imgsrc: "../images/"+(canThumb ? "large" : "small")+"-"+fileIcon+".png",
                imgw: _thumbnailSize,
                imgh: _thumbnailSize,
            })
        }
    }

    Rectangle {
        id: rect
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Theme.secondaryColor
        visible: !ready
    }

    Loader {
        id: listIcon
        anchors.fill: parent
        asynchronous: true
        property alias highlighted: base.highlighted
        onHighlightedChanged: if (status === Loader.Ready) item.highlighted = base.highlighted
        onLoaded: if (!showThumbnail) ready = true;
    }

    Loader {
        id: thumbnail
        anchors.fill: parent
        property alias highlighted: base.highlighted
        onHighlightedChanged: if (status === Loader.Ready) item.highlighted = base.highlighted
        onLoaded: if (showThumbnail) ready = true;
    }
}
