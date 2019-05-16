import QtQuick 2.6
import Sailfish.Silica 1.0

Row {
    id: group
    property var tiedTo

    states: [
        State {
            name: "vertical"
            when: isUpright
            AnchorChanges {
                target: group
                anchors.top: tiedTo.bottom
                anchors.verticalCenter: undefined
                anchors.left: undefined
                anchors.horizontalCenter: parent.horizontalCenter
            }
        },
        State {
            name: "horizontal"
            when: !isUpright
            AnchorChanges {
                target: group
                anchors.top: undefined
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: tiedTo.right
                anchors.horizontalCenter: undefined
            }
            PropertyChanges {
                target: group
                anchors.leftMargin: Theme.paddingLarge
            }
        }
    ]

    spacing: Theme.paddingLarge
}
