import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "../pages/functions.js" as Functions

SilicaListView {
    id: view

    property bool selectable: false
    property bool multiSelect: false
    property bool allowDeleteBookmarks: true
    property var initialSelection
    property var sections: ["locations", "android", "external", "bookmarks"]
    property var _selectedIndex: []

    signal itemClicked(var clickedIndex, var path)
    signal itemSelected(var clickedIndex, var path)
    signal itemDeselected(var clickedIndex, var path) // only for multiSelect

    model: listModel

    delegate: ListItem {
        id: listItem
        property bool selected: false
        ListView.onRemove: animateRemoval(listItem) // enable animated list item removals

        BackgroundItem {
            id: iconButton
            width: view.width
            height: Theme.itemSizeSmall

            onClicked: {
                view.itemClicked(index, model.location);
            }

            Binding on highlighted {
                when: selected || down
                value: true
            }

            Connections {
                target: view
                onItemClicked: {
                    if (!selectable) return;
                    if (index === clickedIndex) { // toggle
                        if (view._selectedIndex.indexOf(index) == -1) { // select
                            if (multiSelect) view._selectedIndex.push(index);
                            else view._selectedIndex = [index];
                            selected = true;
                            itemSelected(index, model.location);
                        } else if (multiSelect) { // deselect
                            view._selectedIndex = view._selectedIndex.filter(function(item) {
                                return item !== index
                            })
                            selected = false;
                            itemDeselected(index, model.location);
                        }
                    } else if (!multiSelect) {
                        selected = false;
                    }
                }
            }

            Image {
                id: image
                width: height
                source: "image://theme/" + model.thumbnail + "?" + (
                            iconButton.highlighted ? Theme.highlightColor : Theme.primaryColor)
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: Theme.paddingMedium
                }
            }

            Label {
                id: shortcutLabel
                width: view.width - x -
                       (deleteBookmarkBtn.visible ? deleteBookmarkBtn.width : Theme.horizontalPageMargin)
                font.pixelSize: Theme.fontSizeMedium
                color: iconButton.highlighted ? Theme.highlightColor : Theme.primaryColor
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
                    color: iconButton.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
                    color: iconButton.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    text: Functions.unicodeArrow() + " " + model.location
                    visible: model.location === model.name ? false : true
                    elide: Text.ElideMiddle
                }
            }

            IconButton {
                id: deleteBookmarkBtn
                width: Theme.itemSizeSmall
                height: Theme.itemSizeSmall
                visible: (model.bookmark ? true : false) && allowDeleteBookmarks
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

    ViewPlaceholder {
         enabled: view.count === 0
         text: qsTr("Nothing to show here...")
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

        for (var i = 0; i < sections.length; i++) {
            var s = sections[i];
            if (s === "locations") {
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
            } else if (s === "android") {
                listModel.append({ "section": qsTr("Android locations"),
                                   "name": qsTr("Android storage"),
                                   "thumbnail": "icon-m-file-apk",
                                   "location": StandardPaths.home + "/android_storage" })
            } else if (s === "external") {
                if (engine.sdcardPath() !== "") {
                    listModel.append({ "section": qsTr("Storage devices"),
                                       "name": qsTr("SD card"),
                                       "thumbnail": "icon-m-sd-card",
                                       "location": engine.sdcardPath(),
                                       "showsize": true })
                }

                // TODO support external drives via USB OTG
            } else if (s === "bookmarks") {
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
    }

    Connections {
        target: main
        onBookmarkAdded: {
            view.updateModel();
        }
        onBookmarkRemoved: {
            for (var i = 0; i < listModel.count; i++) {
                if (listModel.get(i).bookmark === true && listModel.get(i).location === path) {
                    listModel.remove(i);
                }
            }
        }
    }

    function getSelectedLocations() {
        var ret = []
        for (var i = 0; i < listModel.count; i++) {
            if (view._selectedIndex.indexOf(i) != -1) {
                ret.push(listModel.get(i).location);
            }
        }
        return ret;
    }
}
