import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "../components"

Page {
    id: page
    property string sortBy: "name"
    property int sortOrder: Qt.AscendingOrder

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
                title: qsTr("Sorting")
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.pop();
                }
            }

            SelectableListView {
                title: qsTr("Sort by...")
                initial: engine.readSetting("listing-sort-by")

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
                        value: "modified"
                    }
                    ListElement {
                        label: qsTr("File type")
                        value: "type"
                    }
                }

                onSelectionChanged: {
                    engine.writeSetting("listing-sort-by", newValue.toString());
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

            SelectableListView {
                title: qsTr("Order...")
                initial: engine.readSetting("listing-order")

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
                    engine.writeSetting("listing-order", newValue.toString());
                }
            }

            Spacer { height: 2*Theme.paddingLarge }

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
                id: sortCaseSensitive
                text: qsTr("Sort case-sensitively")
                onCheckedChanged: engine.writeSetting("sort-case-sensitive", sortCaseSensitive.checked.toString())
            }

            TextSwitch {
                id: showThumbnails
                text: qsTr("Show thumbnails where possible")
                onCheckedChanged: engine.writeSetting("show-thumbnails", showThumbnails.checked.toString())
            }
        }
    }

    Component.onCompleted: {
        showDirsFirst.checked = (engine.readSetting("show-dirs-first") === "true");
        sortCaseSensitive.checked = (engine.readSetting("sort-case-sensitive") === "true");
        showHiddenFiles.checked = (engine.readSetting("show-hidden-files") === "true");
        showThumbnails.checked = (engine.readSetting("show-thumbnails") === "true");
    }
}
