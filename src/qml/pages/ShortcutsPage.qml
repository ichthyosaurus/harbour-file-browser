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
            MenuItem {
                text: qsTr("Open new window")
                onClicked: engine.openNewWindow(dir);
            }
            MenuItem {
                property bool hasPrevious: pageStack.previousPage() ? true : false
                property var hasBookmark: hasPrevious ? pageStack.previousPage().hasBookmark : undefined
                visible: currentPath !== "" && hasPrevious
                text: (hasBookmark !== undefined) ?
                          (hasBookmark ?
                               qsTr("Remove bookmark for “%1”").arg(Functions.lastPartOfPath(currentPath)) :
                               qsTr("Add “%1” to bookmarks").arg(Functions.lastPartOfPath(currentPath))) : ""
                onClicked: {
                    if (hasBookmark !== undefined) {
                        pageStack.previousPage().toggleBookmark();
                    }
                }
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
