import QtQuick 2.0
import Sailfish.Silica 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                title: qsTr("Settings")
            }

            GroupedDrawer {
                id: viewGroup
                title: qsTr("View")
                contents: Column {
                    property alias useLocalSettings: v1.checked
                    property alias showHiddenFiles: v2.checked
                    property alias showThumbnails: v3.checked
                    property alias thumbSize: v4.currentIndex
                    TextSwitch {
                        id: v1; text: qsTr("Use per-directory view settings")
                        onCheckedChanged: engine.writeSetting("View/UseLocalSettings", checked.toString())
                    }
                    TextSwitch {
                        id: v2; text: qsTr("Show hidden files")
                        onCheckedChanged: engine.writeSetting("View/HiddenFilesShown", checked.toString())
                    }
                    TextSwitch {
                        id: v3; text: qsTr("Show preview images")
                        onCheckedChanged: engine.writeSetting("View/PreviewsShown", checked.toString())
                    }
                    ComboBox {
                        id: v4; width: parent.width
                        label: qsTr("Thumbnail size")
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("small"); property string action: "small"; }
                            MenuItem { text: qsTr("medium"); property string action: "medium"; }
                            MenuItem { text: qsTr("large"); property string action: "large"; }
                            MenuItem { text: qsTr("huge"); property string action: "huge"; }
                        }
                        onValueChanged: engine.writeSetting("View/PreviewsSize", currentItem.action);
                    }
                }
            }

            GroupedDrawer {
                id: sortingGroup
                title: qsTr("Sorting")
                contents: Column {
                    property alias showDirsFirst: s1.checked
                    property alias sortCaseSensitive: s2.checked
                    property alias sortRole: s3.currentIndex
                    property alias sortOrder: s4.currentIndex
                    TextSwitch {
                        id: s1; text: qsTr("Show folders first")
                        onCheckedChanged: { engine.writeSetting("View/ShowDirectoriesFirst", checked.toString()) }
                    }
                    TextSwitch {
                        id: s2; text: qsTr("Sort case-sensitively")
                        onCheckedChanged: engine.writeSetting("View/SortCaseSensitively", checked.toString())
                    }
                    ComboBox {
                        id: s3; label: qsTr("Sort by")
                        onValueChanged: engine.writeSetting("View/SortRole", currentItem.value);
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("name"); property string value: "name" }
                            MenuItem { text: qsTr("size"); property string value: "size" }
                            MenuItem { text: qsTr("modification time"); property string value: "modificationtime" }
                            MenuItem { text: qsTr("file type"); property string value: "type" }
                        }
                    }
                    ComboBox {
                        id: s4; label: qsTr("Sort order")
                        onValueChanged: engine.writeSetting("View/SortOrder", currentItem.value);
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("default"); property string value: "default" }
                            MenuItem { text: qsTr("reversed"); property string value: "reversed" }
                        }
                    }
                }
            }

            GroupedDrawer {
                id: transferGroup
                title: qsTr("Transfer")
                contents: Column {
                    property alias defaultTransfer: t1
                    ComboBox {
                        id: t1; width: parent.width
                        label: qsTr("Default transfer action")
                        currentIndex: -1
                        menu: ContextMenu {
                            MenuItem { text: qsTr("copy"); property string action: "copy"; }
                            MenuItem { text: qsTr("move"); property string action: "move"; }
                            MenuItem { text: qsTr("link"); property string action: "link"; }
                            MenuItem { text: qsTr("none"); property string action: "none"; }
                        }
                        onValueChanged: engine.writeSetting("Transfer/DefaultAction", currentItem.action);
                    }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            Label {
                text: qsTr("About File Browser")
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                horizontalAlignment: Text.AlignRight
                color: Theme.highlightColor
            }
            Spacer { height: Theme.paddingLarge }
            Label {
                id: version
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: main.versionString
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
            }
            Spacer { height: Theme.paddingLarge }
            BackgroundItem {
                anchors.left: parent.left
                anchors.right: parent.right
                height: aboutColumn.height
                onClicked: pageStack.push(Qt.resolvedUrl("LicensePage.qml"))

                Column {
                    id: aboutColumn
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    Label {
                        width: parent.width
                        color: Theme.highlightColor
                        text: qsTr("File Browser is free and unencumbered software released "+
                              "into the public domain.")
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        anchors.right: parent.right
                        color: Theme.primaryColor
                        text: "\u2022 \u2022 \u2022" // three dots
                    }
                }
            }

            Spacer { height: Theme.paddingLarge }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("The source code is available at") + "\nhttps://github.com/karip/harbour-file-browser"
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active)
            pageStack.pushAttached(Qt.resolvedUrl("ContributorsPage.qml"));

        // update cover
        if (status === PageStatus.Activating)
            coverText = qsTr("Settings");

        // read settings
        if (status === PageStatus.Activating) {
            sortingGroup.contentItem.showDirsFirst = (engine.readSetting("View/ShowDirectoriesFirst", "true") === "true");
            sortingGroup.contentItem.sortCaseSensitive = (engine.readSetting("View/SortCaseSensitively", "false") === "true");
            viewGroup.contentItem.showHiddenFiles = (engine.readSetting("View/HiddenFilesShown", "false") === "true");
            viewGroup.contentItem.showThumbnails = (engine.readSetting("View/PreviewsShown", "false") === "true");
            viewGroup.contentItem.useLocalSettings = (engine.readSetting("View/UseLocalSettings", "true") === "true");

            var defTransfer = engine.readSetting("Transfer/DefaultAction", "none");
            if (defTransfer === "copy") {
                transferGroup.contentItem.defaultTransfer.currentIndex = 0;
            } else if (defTransfer === "move") {
                transferGroup.contentItem.defaultTransfer.currentIndex = 1;
            } else if (defTransfer === "link") {
                transferGroup.contentItem.defaultTransfer.currentIndex = 2;
            } else {
                transferGroup.contentItem.defaultTransfer.currentIndex = 3;
            }

            var thumbSize = engine.readSetting("View/PreviewsSize", "medium");
            if (thumbSize === "small") viewGroup.contentItem.thumbSize = 0;
            else if (thumbSize === "medium") viewGroup.contentItem.thumbSize = 1;
            else if (thumbSize === "large") viewGroup.contentItem.thumbSize = 2;
            else if (thumbSize === "huge") viewGroup.contentItem.thumbSize = 3;

            var sortBy = engine.readSetting("View/SortRole", "name");
            if (sortBy === "name") sortingGroup.contentItem.sortRole = 0;
            else if (sortBy === "size") sortingGroup.contentItem.sortRole = 1;
            else if (sortBy === "modificationtime") sortingGroup.contentItem.sortRole = 2;
            else if (sortBy === "type") sortingGroup.contentItem.sortRole = 3;

            var order = engine.readSetting("View/SortOrder", "default");
            if (order === "default") sortingGroup.contentItem.sortOrder = 0;
            else if (order === "reversed") sortingGroup.contentItem.sortOrder = 1;
        }
    }
}
