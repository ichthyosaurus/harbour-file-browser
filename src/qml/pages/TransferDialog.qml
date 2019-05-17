import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions
import "../components"

Dialog {
    id: dialog
    property var toTransfer: []
    property var targets: []
    property string selectedAction: ""
    property string errorMessage: ""

    allowedOrientations: Orientation.All
    canAccept: false

    NotificationPanel {
        id: notificationPanel
        z: 100
        page: page
    }

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
            onItemSelected: dialog.updateStatus();
            onItemDeselected: dialog.updateStatus();

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
                    onSelectionChanged: {
                        dialog.selectedAction = selection
                        dialog.updateStatus();
                    }
                }
            }
        }
    }

    function updateStatus() {
        if (selectedAction !== "" && shortcutsView._selectedIndex.length > 0) {
            canAccept = true;
        } else {
            canAccept = false;
        }
    }

    onAccepted: {
        targets = shortcutsView.getSelectedLocations();
    }

    Component.onCompleted: {
        if (!toTransfer.length) {
            canAccept = false;
            notificationPanel.showTextWithTimer(qsTr("Nothing selected to transfer"), "");
        }
    }
}
