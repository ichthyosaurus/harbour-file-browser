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

            SectionHeader {
                text: "Global view preferences"
            }

            TextSwitch {
                id: useLocalSettings
                text: qsTr("Use per-directory view settings")
                onCheckedChanged: engine.writeSetting("use-local-view-settings", useLocalSettings.checked.toString())
            }
            TextSwitch {
                id: showDirsFirst
                text: qsTr("Show folders first")
                onCheckedChanged: engine.writeSetting("show-dirs-first", showDirsFirst.checked.toString())
            }
            TextSwitch {
                id: showHiddenFiles
                text: qsTr("Show hidden files")
                onCheckedChanged: engine.writeSetting("show-hidden-files", showHiddenFiles.checked.toString())
            }
            TextSwitch {
                id: showThumbnails
                text: qsTr("Show preview images")
                onCheckedChanged: engine.writeSetting("show-thumbnails", showThumbnails.checked.toString())
            }
            TextSwitch {
                id: sortCaseSensitive
                text: qsTr("Sort case-sensitively")
                onCheckedChanged: engine.writeSetting("sort-case-sensitive", sortCaseSensitive.checked.toString())
            }

            ComboBox {
                id: thumbnailSize
                width: parent.width
                label: "Thumbnail size"
                currentIndex: -1
                menu: ContextMenu {
                    MenuItem { text: qsTr("small"); property string action: "small"; }
                    MenuItem { text: qsTr("medium"); property string action: "medium"; }
                    MenuItem { text: qsTr("large"); property string action: "large"; }
                    MenuItem { text: qsTr("huge"); property string action: "huge"; }
                }
                onValueChanged: {
                    engine.writeSetting("thumbnails-size", currentItem.action);
                }
            }

            SectionHeader {
                text: "Transfer preferences"
            }

            ComboBox {
                id: defaultTransfer
                width: parent.width
                label: "Default transfer action"
                currentIndex: -1
                menu: ContextMenu {
                    MenuItem { text: qsTr("copy"); property string action: "copy"; }
                    MenuItem { text: qsTr("move"); property string action: "move"; }
                    MenuItem { text: qsTr("link"); property string action: "link"; }
                    MenuItem { text: qsTr("none"); property string action: "none"; }
                }
                onValueChanged: {
                    engine.writeSetting("default-transfer-action", currentItem.action);
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
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                Label {
                    id: version
                    text: qsTr("Version")+" "
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor
                }
                Label {
                    text: "1.8.0 (fork)" // Version number must be changed manually!
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor
                }
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
        // update cover
        if (status === PageStatus.Activating)
            coverText = qsTr("Settings");

        // read settings
        if (status === PageStatus.Activating) {
            showDirsFirst.checked = (engine.readSetting("show-dirs-first") === "true");
            showHiddenFiles.checked = (engine.readSetting("show-hidden-files") === "true");
            showThumbnails.checked = (engine.readSetting("show-thumbnails") === "true");
            sortCaseSensitive.checked = (engine.readSetting("sort-case-sensitive") === "true");
            useLocalSettings.checked = (engine.readSetting("use-local-view-settings") === "true");

            var defTransfer = engine.readSetting("default-transfer-action", "none");
            if (defTransfer === "copy") {
                defaultTransfer.currentIndex = 0;
            } else if (defTransfer === "move") {
                defaultTransfer.currentIndex = 1;
            } else if (defTransfer === "link") {
                defaultTransfer.currentIndex = 2;
            } else {
                defaultTransfer.currentIndex = 3;
            }

            var thumbSize = engine.readSetting("thumbnails-size", "medium");
            if (thumbSize === "small") {
                thumbnailSize.currentIndex = 0;
            } else if (thumbSize === "medium") {
                thumbnailSize.currentIndex = 1;
            } else if (thumbSize === "large") {
                thumbnailSize.currentIndex = 2;
            } else if (thumbSize === "huge") {
                thumbnailSize.currentIndex = 3;
            }
        }
    }
}
