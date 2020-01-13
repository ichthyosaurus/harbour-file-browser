import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    id: main
    signal bookmarkAdded(var path)
    signal bookmarkRemoved(var path)
    signal bookmarkMoved(var path)

    // note: version number has to be updated only in harbour-file-browser.yaml!
    readonly property string versionString: qsTr("Version %1").arg(versionNumber)

    property string coverText: "File Browser"
    cover: Qt.resolvedUrl("cover/FileBrowserCover.qml")
    initialPage: Component {
        DirectoryPage { initial: true; }
    }
}
