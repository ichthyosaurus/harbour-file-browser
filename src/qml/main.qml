import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    id: main
    signal bookmarkAdded(var path)
    signal bookmarkRemoved(var path)

    // set to false to disable sharing functionality
    // as sharing is not allowed in Jolla store
    property bool sharingEnabled: true

    property string coverText: "File Browser"
    cover: Qt.resolvedUrl("cover/FileBrowserCover.qml")
    initialPage: Component {
        DirectoryPage { initial: true; }
    }
}
