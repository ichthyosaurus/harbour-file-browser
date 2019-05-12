import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
    id: column
    width: parent.width

    signal selectionChanged(var newValue)

    property alias title: headerLabel.text
    property alias model: listView.model
    property var initial

    Label {
        id: headerLabel
        x: Theme.horizontalPageMargin
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
        height: contentHeight+Theme.paddingSmall
    }

    SilicaListView {
        id: listView
        width: parent.width
        height: childrenRect.height

        property var selectedIndex

        delegate: BackgroundItem {
            property bool selected: listView.selectedIndex === index
            height: Math.max(Theme.itemSizeSmall, itemLabel.height+2*Theme.paddingMedium)

            Label {
                id: itemLabel
                anchors.verticalCenter: parent.verticalCenter
                x: 2*Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                text: label
            }

            Binding on highlighted {
                when: selected || down
                value: true
            }

            Connections {
                target: column
                onSelectionChanged: {
                    if (value === newValue) {
                        listView.selectedIndex = index
                    }
                }
            }

            onClicked: {
                selectionChanged(value);
            }
        }
    }

    function selectInitial() {
        if (initial) {
            for (var i = 0; i < model.count; i++) {
                if (model.get(i).value === initial) {
                    listView.selectedIndex = i;
                    break;
                }
            }
        }
    }

    onInitialChanged: {
        selectInitial();
    }

    Component.onCompleted: {
        selectInitial();
    }
}
