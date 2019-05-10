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
                        value: "asc"
                    }
                    ListElement {
                        label: qsTr("reversed")
                        value: "desc"
                    }
                }

                onSelectionChanged: {
                    engine.writeSetting("listing-order", newValue.toString());
                }
            }
        }
    }
}
