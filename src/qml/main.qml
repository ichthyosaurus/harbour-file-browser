import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    id: main
    property string coverText: "File Browser"

    cover: Qt.resolvedUrl("cover/FileBrowserCover.qml")
    initialPage: Component {
        ShortcutsPage { }
    }
}
