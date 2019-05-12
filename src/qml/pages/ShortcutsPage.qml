import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaListView {
        id: shortcutsView

        width: parent.width
        height: parent.height - 2*Theme.horizontalPageMargin

        VerticalScrollDecorator { }

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                          { dir: StandardPaths.home });
            }
        }

        model: listModel

        header: PageHeader {
            title: qsTr("Places")
        }

        delegate: Component {
            id: listItem

            BackgroundItem {
                id: iconButton
                width: shortcutsView.width
                height: Theme.itemSizeSmall

                onClicked: {
                    Functions.goToFolder(model.location)
                }

                Image {
                    id: image
                    width: height
                    source: "image://theme/" + model.thumbnail + "?" + (
                                iconButton.pressed ? Theme.highlightColor : Theme.primaryColor)
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: Theme.paddingMedium
                    }
                }

                Label {
                    id: shortcutLabel
                    width: page.width - x -
                           (deleteBookmarkBtn.visible ? deleteBookmarkBtn.width : Theme.horizontalPageMargin)
                    font.pixelSize: Theme.fontSizeMedium
                    color: iconButton.pressed ? Theme.highlightColor : Theme.primaryColor
                    text: model.name
                    truncationMode: TruncationMode.Fade
                    anchors {
                        left: image.right
                        leftMargin: Theme.paddingMedium
                        top: parent.top
                        topMargin: model.location === model.name ? (parent.height / 2) - (height / 2) : 5
                    }
                }

                Row {
                    spacing: 0
                    anchors {
                        left: image.right
                        leftMargin: Theme.paddingMedium
                        top: shortcutLabel.bottom
                        topMargin: 2
                        right: shortcutLabel.right
                    }

                    Text {
                        id: sizeInfo
                        visible: model.showsize
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: iconButton.pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        text: (visible ? "... \u2022 ... \u2022 " : "")

                        function updateText() {
                            if (visible) {
                                var space = engine.diskSpace(model.location);
                                text = (space.length > 0 ? space[0] + " \u2022 " + space[1] + " \u2022 " : "");
                            } else {
                                text = "";
                            }
                        }

                        Component.onCompleted: {
                            updateText();
                        }
                        onVisibleChanged: {
                            updateText();
                        }
                    }

                    Text {
                        id: shortcutPath
                        width: parent.width - (sizeInfo.visible ? sizeInfo.width : 0)
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: iconButton.pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        text: Functions.unicodeArrow() + " " + model.location
                        visible: model.location === model.name ? false : true
                        elide: Text.ElideMiddle
                    }
                }

                IconButton {
                    id: deleteBookmarkBtn
                    width: Theme.itemSizeSmall
                    height: Theme.itemSizeSmall
                    visible: model.bookmark ? true : false
                    icon.source: "image://theme/icon-m-clear"

                    anchors {
                        top: parent.top
                        right: parent.right
                        rightMargin: Theme.paddingSmall
                        leftMargin: Theme.paddingSmall
                    }

                    onClicked: {
                        if (!model.bookmark) return;
                        Functions.removeBookmark(model.location);
                    }
                }
            }
        }

        section {
            property: 'section'
            delegate: SectionHeader {
                text: section
                height: Theme.itemSizeExtraSmall
            }
        }

        ListModel {
            id: listModel
        }

        Component.onCompleted: {
            updateModel()
        }

        function updateModel() {
            listModel.clear()
            listModel.append({ "section": qsTr("Locations"),
                               "name": qsTr("Home"),
                               "thumbnail": "icon-m-home",
                               "location": StandardPaths.home,
                               "showsize": true })
            listModel.append({ "section": qsTr("Locations"),
                               "name": qsTr("Documents"),
                               "thumbnail": "icon-m-file-document-light",
                               "location": StandardPaths.documents })
            listModel.append({ "section": qsTr("Locations"),
                               "name": qsTr("Downloads"),
                               "thumbnail": "icon-m-cloud-download",
                               "location": StandardPaths.download })
            listModel.append({ "section": qsTr("Locations"),
                               "name": qsTr("Music"),
                               "thumbnail": "icon-m-file-audio",
                               "location": StandardPaths.music })
            listModel.append({ "section": qsTr("Locations"),
                               "name": qsTr("Pictures"),
                               "thumbnail": "icon-m-file-image",
                               "location": StandardPaths.pictures })
            listModel.append({ "section": qsTr("Locations"),
                               "name": qsTr("Videos"),
                               "thumbnail": "icon-m-file-video",
                               "location": StandardPaths.videos })
            listModel.append({ "section": qsTr("Locations"),
                               "name": qsTr("Root"),
                               "thumbnail": "icon-m-file-rpm",
                               "location": "/",
                               "showsize": true })
            listModel.append({ "section": qsTr("Android locations"),
                               "name": qsTr("Android storage"),
                               "thumbnail": "icon-m-file-apk",
                               "location": StandardPaths.home + "/android_storage" })
            if (engine.sdcardPath() !== "") {
                listModel.append({ "section": qsTr("Storage devices"),
                                   "name": qsTr("SD card"),
                                   "thumbnail": "icon-m-sd-card",
                                   "location": engine.sdcardPath(),
                                   "showsize": true })
            }

            // TODO support external drives via USB OTG

            // Add bookmarks if there are any
            var bookmarks = Functions.getBookmarks();

            for (var key in bookmarks) {
                listModel.append({ "section": qsTr("Bookmarks"),
                                   "name": engine.readSetting("bookmarks"+bookmarks[key]),
                                   "thumbnail": "icon-m-favorite",
                                   "location": bookmarks[key],
                                   "bookmark": true })
            }
        }
    }

    Connections {
        target: main
        onBookmarkAdded: {
            shortcutsView.updateModel();
        }
        onBookmarkRemoved: {
            for (var i = 0; i < listModel.count; i++) {
                if (listModel.get(i).bookmark === true && listModel.get(i).location === path) {
                    //listModel.get(i).animateRemoval(shortcutsView);
                    listModel.remove(i);
                }
            }
        }
    }
}
