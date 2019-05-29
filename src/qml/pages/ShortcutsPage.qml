import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string currentPath: ""

    SilicaFlickable {
        anchors.fill: parent
        VerticalScrollDecorator { }

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                          { dir: currentPath === "" ? StandardPaths.home : currentPath });
            }
        }

        ShortcutsList {
            id: shortcutsView
            onItemClicked: Functions.goToFolder(path)

            width: parent.width
            height: parent.height - 2*Theme.horizontalPageMargin

            header: PageHeader {
                title: qsTr("Places")
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            main.coverText = Functions.lastPartOfPath(currentPath)+"/"; // update cover
        }
    }
}
