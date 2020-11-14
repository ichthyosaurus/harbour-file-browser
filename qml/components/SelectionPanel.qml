import QtQuick 2.0
import Sailfish.Silica 1.0

// bottom dock panel to display file action icons
DockedPanel {
    id: dockPanel
    width: parent.width
    open: false
    height: fileActions.height
    dock: Dock.Bottom
    visible: shouldBeVisible & !Qt.inputMethod.visible

    property alias selectedFiles: fileActions.selectedFiles
    property alias displayClose: fileActions.displayClose
    property alias actions: fileActions
    property alias selectedCount: fileActions.selectedCount // number of selected items
    property bool enabled: true // enable or disable the buttons
    property string overrideText: "" // override text is shown if set, it gets cleared whenever selected file count changes

    // property to indicate that the panel is really visible (open or showing closing animation)
    property bool shouldBeVisible: false
    onOpenChanged: { if (open) shouldBeVisible = true; }
    onMovingChanged: { if (!open && !moving) shouldBeVisible = false; }

    FileActions {
        id: fileActions
        labelText: dockPanel.overrideText === "" ? qsTr("%n file(s) selected", "", dockPanel.selectedCount)
                                                 : dockPanel.overrideText
        errorCallback: function(errorMsg) { notificationPanel.showTextWithTimer(errorMsg, ""); }
        enabled: enabled
    }
}
