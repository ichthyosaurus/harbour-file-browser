import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "../components"

Page {
    id: page
    property string dir;

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                id: header
                title: qsTr("Sorting")
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.pop();
                }
            }

            SelectableListView {
                id: sortList
                title: qsTr("Sort by...")

                model: ListModel {
                    ListElement {
                        label: qsTr("Name")
                        value: "name"
                    }
                    ListElement {
                        label: qsTr("Size")
                        value: "size"
                    }
                    ListElement {
                        label: qsTr("Modification time")
                        value: "modificationtime"
                    }
                    ListElement {
                        label: qsTr("File type")
                        value: "type"
                    }
                }

                onSelectionChanged: {
                    if (useLocalSettings()) {
                        engine.writeSetting("Dolphin/SortRole", newValue.toString(), getConfigPath());
                    } else {
                        engine.writeSetting("listing-sort-by", newValue.toString());
                    }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            SelectableListView {
                id: orderList
                title: qsTr("Order...")

                model: ListModel {
                    ListElement {
                        label: qsTr("default")
                        value: "default"
                    }
                    ListElement {
                        label: qsTr("reversed")
                        value: "reversed"
                    }
                }

                onSelectionChanged: {
                    if (useLocalSettings()) {
                        engine.writeSetting("Dolphin/SortOrder", newValue.toString() === "default" ? "0" : "1", getConfigPath());
                    } else {
                        engine.writeSetting("listing-order", newValue.toString());
                    }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            TextSwitch {
                id: showDirsFirst
                text: qsTr("Show folders first")
                onCheckedChanged: saveSetting("show-dirs-first", "Sailfish/ShowDirectoriesFirst", "true", "false", showDirsFirst.checked.toString())
            }

            TextSwitch {
                id: showHiddenFiles
                text: qsTr("Show hidden files")
                onCheckedChanged: saveSetting("show-hidden-files", "Settings/HiddenFilesShown", "true", "false", showHiddenFiles.checked.toString())
            }

            TextSwitch {
                id: sortCaseSensitive
                text: qsTr("Sort case-sensitively")
                onCheckedChanged: saveSetting("sort-case-sensitive", "Sailfish/SortCaseSensitively", "true", "false", sortCaseSensitive.checked.toString())
            }

            TextSwitch {
                id: showThumbnails
                text: qsTr("Show thumbnails where possible")
                onCheckedChanged: saveSetting("show-thumbnails", "Dolphin/PreviewsShown", "true", "false", showThumbnails.checked.toString())
            }
        }
    }

    function getConfigPath() {
        return dir+"/.directory";
    }

    function useLocalSettings() {
        return engine.readSetting("use-local-view-settings", "false") === "true";
    }

    function updateShownSettings() {
        var useLocal = useLocalSettings();

        if (useLocal) {
            header.description = qsTr("Local settings");
        } else {
            header.description = qsTr("Global settings");
        }

        var sort = engine.readSetting("listing-sort-by");
        var order = engine.readSetting("listing-order");
        var conf = getConfigPath();

        if (useLocal) {
            sortList.initial = engine.readSetting("Dolphin/SortRole", sort, conf);
            orderList.initial = engine.readSetting("Dolphin/SortOrder", order === "default" ? "0" : "1", conf) === "0" ? "default" : "reversed";
        } else {
            sortList.initial = sort;
            orderList.initial = order;
        }

        var dirsFirst = engine.readSetting("show-dirs-first");
        var caseSensitive = engine.readSetting("sort-case-sensitive");
        var showHidden = engine.readSetting("show-hidden-files");
        var showThumbs = engine.readSetting("show-thumbnails");

        if (useLocal) {
            showDirsFirst.checked = (engine.readSetting("Sailfish/ShowDirectoriesFirst", dirsFirst, conf) === "true");
            sortCaseSensitive.checked = (engine.readSetting("Sailfish/SortCaseSensitively", caseSensitive, conf) === "true");
            showHiddenFiles.checked = (engine.readSetting("Settings/HiddenFilesShown", showHidden, conf) === "true");
            showThumbnails.checked = (engine.readSetting("Dolphin/PreviewsShown", showThumbs, conf) === "true");
        } else {
            showDirsFirst.checked = (dirsFirst === "true");
            sortCaseSensitive.checked = (caseSensitive === "true");
            showHiddenFiles.checked = (showHidden === "true");
            showThumbnails.checked = (showThumbs === "true");
        }
    }

    function saveSetting(keyGlobal, keyLocal, trueLocal, falseLocal, valueStr) {
        if (useLocalSettings()) {
            engine.writeSetting(keyLocal, (valueStr === "true" ? trueLocal : falseLocal), getConfigPath());
        } else {
            engine.writeSetting(keyGlobal, valueStr);
        }
    }

    Component.onCompleted: {
        updateShownSettings();
    }
}
