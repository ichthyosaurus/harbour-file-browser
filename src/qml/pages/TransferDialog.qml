import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions
import "../components"

Dialog {
    id: dialog
    property var toTransfer: []
    property var targets: []
    property var selectedAction
    property string errorMessage: ""

    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        VerticalScrollDecorator { }

        ShortcutsList {
            id: shortcutsView
            width: flickable.width
            height: flickable.height - 2*Theme.horizontalPageMargin
            sections: ["bookmarks", "locations", "android", "external"]
            selectable: true
            multiSelect: true

            header: Item {
                width: dialog.width
                height: head.height + action.height + Theme.paddingLarge

                DialogHeader { id: head }
                TransferActionBar {
                    id: action
                    width: parent.width
                    height: Theme.itemSizeMedium
                    anchors.top: head.bottom
                    anchors.topMargin: Theme.paddingMedium
                    onSelectionChanged: dialog.selectedAction = selection
                }
            }
        }
    }

    onAccepted: {
        targets = shortcutsView.getSelectedLocations();
        console.log("TRANSFER ACCEPTED", toTransfer, targets, selectedAction)
    }
}
