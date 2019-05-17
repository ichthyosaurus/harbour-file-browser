import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: action
    property string selection: ""

    Row {
        anchors.fill: parent

        BackgroundItem {
            id: first
            width: parent.width / 3
            contentHeight: parent.height
            _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)

            Label { text: qsTr("Copy");  anchors.centerIn: parent; color: first.highlighted ? Theme.highlightColor : Theme.primaryColor }

            onClicked: action.selection = "copy"
            highlighted: action.selection === "copy"
        }
        BackgroundItem {
            id: second
            width: parent.width / 3
            contentHeight: parent.height
            _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)

            Label { text: qsTr("Move");  anchors.centerIn: parent; color: second.highlighted ? Theme.highlightColor : Theme.primaryColor }

            onClicked: action.selection = "move"
            highlighted: action.selection === "move"
        }
        BackgroundItem {
            id: third
            width: parent.width / 3
            contentHeight: parent.height
            _backgroundColor: Theme.rgba(highlighted ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)

            Label { text: qsTr("Link");  anchors.centerIn: parent; color: third.highlighted ? Theme.highlightColor : Theme.primaryColor }

            onClicked: action.selection = "link"
            highlighted: action.selection === "link"
        }
    }
}
