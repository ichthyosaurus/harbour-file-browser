import QtQuick 2.0
import Sailfish.Silica 1.0

import "pages"
import "js/navigation.js" as Navigation

ApplicationWindow {
    id: main
    signal bookmarkAdded(var path)
    signal bookmarkRemoved(var path)
    signal bookmarkMoved(var path)

    // note: version number has to be updated only in harbour-file-browser.yaml!
    readonly property string versionString: qsTr("Version %1").arg(appVersion)
    readonly property bool runningAsRoot: engine.runningAsRoot()

    property string coverText: "File Browser"
    cover: Qt.resolvedUrl("cover/FileBrowserCover.qml")
    initialPage: Component {
        DirectoryPage {
            dir: "";

            property bool initial: true
            onStatusChanged: {
                if (status === PageStatus.Activating && initial) {
                    initial = false;
                    pageStack.completeAnimation();
                    Navigation.goToFolder(initialDirectory);
                }
            }
        }
    }
}
