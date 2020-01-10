import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "../pages/functions.js" as Functions

SilicaListView {
    id: view

    property bool selectable: false
    property bool multiSelect: false
    property bool allowDeleteBookmarks: true
    property bool editable: true
    property var initialSelection
    property var sections: ["locations", "android", "external", "bookmarks"]

    signal itemClicked(var clickedIndex, var path)
    signal itemSelected(var clickedIndex, var path)
    signal itemDeselected(var clickedIndex, var path) // only for multiSelect

    property var _selectedIndex: []
    property bool _isEditing: false
    function _editBookmarks() { if (editable) _isEditing = true; }
    function _finishEditing() { _isEditing = false; }

    model: listModel

    delegate: ListItem {
        id: listItem
        property bool selected: view._selectedIndex.indexOf(index) !== -1
        ListView.onRemove: animateRemoval(listItem) // enable animated list item removals
        menu: model.contextMenu

        width: view.width
        height: Theme.itemSizeSmall + (_menuItem ? _menuItem.height : 0)

        onClicked: {
                if (!_isEditing) itemClicked(index, model.location);
                else _finishEditing();
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
                        listItem.highlighted ? Theme.highlightColor : Theme.primaryColor)
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: Theme.paddingMedium
            }
        }

        Label {
            id: shortcutLabel
            font.pixelSize: Theme.fontSizeMedium
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            text: model.name
            truncationMode: TruncationMode.Fade
            anchors {
                left: image.right
                leftMargin: Theme.paddingMedium
                top: parent.top
                topMargin: model.location === model.name ? (parent.height / 2) - (height / 2) : 5
            }
            width: view.width - x -
                   (deleteBookmarkBtn.visible ? deleteBookmarkBtn.width : Theme.horizontalPageMargin)
        }

        TextField {
            id: editLabel
            visible: !shortcutLabel.visible
            z: infoRow.z-1
            placeholderText: model.name
            text: model.name
            labelVisible: false
            textTopMargin: 0
            textMargin: 0
            anchors {
                left: image.right
                leftMargin: Theme.paddingMedium
                top: parent.top
                topMargin: model.location === model.name ? (parent.height / 2) - (height / 2) : 5
            }
            width: view.width - x -
                   (deleteBookmarkBtn.visible ? deleteBookmarkBtn.width : Theme.horizontalPageMargin)
            Connections { target: editLabel._editor; onAccepted: _finishEditing(); }
        }

        Row {
            id: infoRow
            spacing: 0
            anchors {
                left: image.right
                leftMargin: Theme.paddingMedium
                top: shortcutLabel.bottom
                topMargin: 2
                right: shortcutLabel.right
            }

            visible: true; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 100 } }

            Text {
                id: sizeInfo
                visible: model.showsize
                font.pixelSize: Theme.fontSizeExtraSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                text: Functions.unicodeArrow() + " " + model.location
                visible: model.location === model.name ? false : true
                elide: Text.ElideMiddle
            }
        }

        onPressAndHold: {
            if (model.bookmark ? true : false) {
                _editBookmarks();
            }
        }

        IconButton {
            id: deleteBookmarkBtn
            width: Theme.itemSizeSmall
            height: Theme.itemSizeSmall
            icon.source: "image://theme/icon-m-remove"
            visible: false; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 100 } }

            anchors {
                top: parent.top
                right: parent.right
                rightMargin: Theme.paddingSmall
                leftMargin: Theme.paddingSmall
            }

            onClicked: {
                if (!model.bookmark || !model.location) return;
                Functions.removeBookmark(model.location);
            }
        }

        states: [
            State {
                name: "" // default state
                PropertyChanges { target: infoRow; visible: true; }
                PropertyChanges { target: shortcutLabel; visible: true; }
                PropertyChanges { target: deleteBookmarkBtn; visible: false; }
                PropertyChanges { target: editLabel; readOnly: true; }
            },
            State {
                name: "editing"
                when: _isEditing && model.bookmark === true;
                PropertyChanges { target: infoRow; visible: false; }
                PropertyChanges { target: shortcutLabel; visible: false; }
                PropertyChanges { target: deleteBookmarkBtn; visible: allowDeleteBookmarks; }
                PropertyChanges { target: editLabel; readOnly: false; text: model.name; }
            }
        ]

        onStateChanged: {
            if (state !== "") return;
            var oldText = model.name;
            var newText = editLabel.text;

            if (newText === "" || oldText === newText || model.location === "" || !model.location) {
                return;
            }

            model.name = newText;
            settings.write("Bookmarks/"+model.location, newText);
        }
    }

    Component {
        id: contextMenu
        ContextMenu {
            MenuItem {
                text: qsTr("Open system settings");
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("/usr/share/jolla-settings/pages/storage/storage.qml"));
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
                var drives = engine.externalDrives();

                for (var d in drives) {
                    listModel.append({ "section": qsTr("Storage devices"),
                                       "name": drives[d].title,
                                       "thumbnail": drives[d].title === qsTr("SD card") ? "icon-m-sd-card" : "icon-m-usb",
                                       "location": drives[d].path,
                                       "showsize": true,
                                       "contextMenu": contextMenu })
                }
            } else if (s === "bookmarks") {
                // Add bookmarks if there are any
                var bookmarks = Functions.getBookmarks();

                for (var key in bookmarks) {
                    if (bookmarks[key] === "") continue;
                    var name = settings.read("Bookmarks/"+bookmarks[key]);

                    if (name === "") {
                        console.warn("empty bookmark name for", bookmarks[key], "reset to default value");
                        name = Functions.lastPartOfPath(bookmarks[key]);
                        settings.write("Bookmarks/"+bookmarks[key], Functions.lastPartOfPath(bookmarks[key]));
                    }

                    listModel.append({ "section": qsTr("Bookmarks"),
                                       "name": name,
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
