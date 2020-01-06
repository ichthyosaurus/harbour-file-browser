import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "../components"

Page {
    id: page
    property string dir;
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
                id: header
                title: qsTr("Sorting and View")
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.pop();
                }
            }

            SelectableListView {
                id: sortList
                title: qsTr("Sort by...")

                model: ListModel {
                    ListElement { label: qsTr("Name"); value: "name" }
                    ListElement { label: qsTr("Size"); value: "size" }
                    ListElement { label: qsTr("Modification time"); value: "modificationtime" }
                    ListElement { label: qsTr("File type"); value: "type" }
                }

                onSelectionChanged: {
                    if (useLocalSettings()) {
                        engine.writeSetting("Dolphin/SortRole", newValue.toString(), getConfigPath());
                    } else {
                        engine.writeSetting("View/SortRole", newValue.toString());
                    }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            SelectableListView {
                id: orderList
                title: qsTr("Order...")

                model: ListModel {
                    ListElement { label: qsTr("default"); value: "default" }
                    ListElement { label: qsTr("reversed"); value: "reversed" }
                }

                onSelectionChanged: {
                    if (useLocalSettings()) {
                        engine.writeSetting("Dolphin/SortOrder", newValue.toString() === "default" ? "0" : "1", getConfigPath());
                    } else {
                        engine.writeSetting("View/SortOrder", newValue.toString());
                    }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            SelectableListView {
                id: thumbList
                title: qsTr("Preview images")

                model: ListModel {
                    ListElement { label: qsTr("none"); value: "none" }
                    ListElement { label: qsTr("small"); value: "small" }
                    ListElement { label: qsTr("medium"); value: "medium" }
                    ListElement { label: qsTr("large"); value: "large" }
                    ListElement { label: qsTr("huge"); value: "huge" }
                }

                onSelectionChanged: {
                    if (newValue.toString() === "none") saveSetting("View/PreviewsShown", "Dolphin/PreviewsShown", "true", "false", "false")
                    else {
                        saveSetting("View/PreviewsShown", "Dolphin/PreviewsShown", "true", "false", "true")
                        engine.writeSetting("View/PreviewsSize", newValue.toString());
                    }
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            TextSwitch {
                id: showHiddenFiles
                text: qsTr("Show hidden files")
                onCheckedChanged: saveSetting("View/HiddenFilesShown", "Settings/HiddenFilesShown", "true", "false", showHiddenFiles.checked.toString())
            }
            TextSwitch {
                id: showDirsFirst
                text: qsTr("Show folders first")
                onCheckedChanged: saveSetting("View/ShowDirectoriesFirst", "Sailfish/ShowDirectoriesFirst", "true", "false", showDirsFirst.checked.toString())
            }
            TextSwitch {
                id: sortCaseSensitive
                text: qsTr("Sort case-sensitively")
                onCheckedChanged: saveSetting("View/SortCaseSensitively", "Sailfish/SortCaseSensitively", "true", "false", sortCaseSensitive.checked.toString())
            }
        }
    }

    function getConfigPath() {
        return dir+"/.directory";
    }

    function useLocalSettings() {
        return engine.readSetting("View/UseLocalSettings", "false") === "true";
    }

    function updateShownSettings() {
        var useLocal = useLocalSettings();
        if (useLocal) header.description = qsTr("Local preferences");
        else header.description = qsTr("Global preferences");
        var conf = getConfigPath();

        var sort = engine.readSetting("View/SortRole", "name");
        var order = engine.readSetting("View/SortOrder", "default");

        if (useLocal) {
            sortList.initial = engine.readSetting("Dolphin/SortRole", sort, conf);
            orderList.initial = engine.readSetting("Dolphin/SortOrder", order === "default" ? "0" : "1", conf) === "0" ? "default" : "reversed";
        } else {
            sortList.initial = sort;
            orderList.initial = order;
        }

        var dirsFirst = engine.readSetting("View/ShowDirectoriesFirst", "true");
        var caseSensitive = engine.readSetting("View/SortCaseSensitively", "false");
        var showHidden = engine.readSetting("View/HiddenFilesShown", "false");
        var showThumbs = engine.readSetting("View/PreviewsShown", "false");

        if (useLocal) {
            showDirsFirst.checked = (engine.readSetting("Sailfish/ShowDirectoriesFirst", dirsFirst, conf) === "true");
            sortCaseSensitive.checked = (engine.readSetting("Sailfish/SortCaseSensitively", caseSensitive, conf) === "true");
            showHiddenFiles.checked = (engine.readSetting("Settings/HiddenFilesShown", showHidden, conf) === "true");
            showThumbs = engine.readSetting("Dolphin/PreviewsShown", showThumbs, conf);
        } else {
            showDirsFirst.checked = (dirsFirst === "true");
            sortCaseSensitive.checked = (caseSensitive === "true");
            showHiddenFiles.checked = (showHidden === "true");
        }

        if (showThumbs === "true") thumbList.initial = engine.readSetting("View/PreviewsSize", "medium");
        else thumbList.initial = "none";
    }

    function saveSetting(keyGlobal, keyLocal, trueLocal, falseLocal, valueStr) {
        if (useLocalSettings()) {
            var currentGlobal = engine.readSetting(keyGlobal) === trueLocal ? "true" : "false";

            if (valueStr === currentGlobal) {
                // If the new value matches the currently set global setting,
                // we remove the local setting. This makes sure that local settings
                // are updated as expected when global setting change. We assume
                // that users don't want to "set this setting locally to a fixed value",
                // but instead want to "enable" or "disable" a setting. For example:
                // hidden files are globally hidden; the user shows them explicitly
                // via the local settings. The user hides them again but sets the
                // global setting so they are shown. The user expects them now the
                // be shown in all directories. If we would simply save "hidden
                // file are hidden here", then the user would have to change the
                // local settings again, which is counterintuitive.
                engine.removeSetting(keyLocal, getConfigPath());
            } else {
                engine.writeSetting(keyLocal, (valueStr === "true" ? trueLocal : falseLocal), getConfigPath());
            }
        } else {
            engine.writeSetting(keyGlobal, valueStr);
        }
    }

    Component.onCompleted: {
        updateShownSettings();

    }

    onStatusChanged: if (status === PageStatus.Active) pageStack.pushAttached(Qt.resolvedUrl("SettingsPage.qml"));
}
