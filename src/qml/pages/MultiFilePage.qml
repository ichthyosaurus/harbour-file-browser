import QtQuick 2.0
import Sailfish.Silica 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property var files
    property alias notificationPanel: notificationPanel

    RemorsePopup {
        id: remorsePopup
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + 2*Theme.paddingLarge
        VerticalScrollDecorator { flickable: flickable }

        visible: !transferPanel.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                title: qsTr("Selection Properties")
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                spacing: Theme.paddingLarge

                // HighlightImage replaced with a Loader so that HighlightImage or Image
                // can be loaded depending on Sailfish version (lightPrimaryColor is defined on SF3)
                Loader {
                    id: icon
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !imagePreview.visible && !playButton.visible
                    width: 128 * Theme.pixelRatio
                    height: 128 * Theme.pixelRatio
                    Component.onCompleted: {
                        var qml = Theme.lightPrimaryColor ? "../components/HighlightImageSF3.qml"
                                                          : "../components/HighlightImageSF2.qml";
                        setSource(qml, {
                            imgsrc: "../images/large-file-stack.png",
                            imgw: 128 * Theme.pixelRatio,
                            imgh: 128 * Theme.pixelRatio
                        })
                    }
                }

                Label {
                    width: parent.width
                    text: qsTr("%n item(s) selected", "", page.files.length)
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primaryColor
                }

                FileActions {
                    x: -parent.x
                    selectedFiles: function() { return page.files; }
                    errorCallback: function(errorMsg) { notificationPanel.showTextWithTimer(errorMsg, ""); }
                    selectedCount: page.files.length
                    showProperties: false
                    showSelection: false
                    showShare: false
                    showEdit: false
                    showRename: false
                    Component.onCompleted: labelText = "" // forcibly hide 'x files selected'

                    onDeleteTriggered: {
                        remorsePopup.execute(qsTr("Deleting"), function() {
                            var prevPage = pageStack.previousPage();
                            var filesList = page.files;
                            pageStack.pop();
                            if (prevPage.progressPanel) prevPage.progressPanel.showText(qsTr("Deleting"));
                            engine.deleteFiles(filesList);
                        });
                    }
                    onTransferTriggered: {
                        if (selectedAction === "move") {
                            var prevPage = pageStack.previousPage();
                            if (prevPage.progressPanel) transferPanel.progressPanel = prevPage.progressPanel;
                            if (prevPage.notificationPanel) transferPanel.notificationPanel = prevPage.notificationPanel;
                            pageStack.pop();
                        }

                        transferPanel.startTransfer(toTransfer, targets, selectedAction, goToTarget);
                    }
                }

                SizeDetailItem {
                    files: page.files
                }

                DetailList {
                    label: qsTr("Directories")
                    values: getDirectories()
                    maxEntries: 5
                    preprocessor: function(file) {
                        return Functions.lastPartOfPath(file);
                    }
                }

                DetailList {
                    label: qsTr("Files")
                    values: getFiles()
                    maxEntries: 5
                    preprocessor: function(file) {
                        return Functions.lastPartOfPath(file);
                    }
                }
            }
        }
    }

    function getFiles() {
        var ret = [];
        for (var i = 0; i < files.length; i++) {
            if (engine.pathIsFile(files[i])) ret.push(files[i]);
        }
        if (ret.length === 0) ret.push(qsTr("none"));
        return ret;
    }

    function getDirectories() {
        var ret = [];
        for (var i = 0; i < files.length; i++) {
            if (engine.pathIsDirectory(files[i])) ret.push(files[i]);
        }
        if (ret.length === 0) ret.push(qsTr("none"));
        return ret;
    }

    NotificationPanel {
        id: notificationPanel
        page: page
    }

    ProgressPanel {
        id: progressPanel
        page: page
        onCancelled: engine.cancel()
    }

    TransferPanel {
        id: transferPanel
        page: page
        progressPanel: progressPanel
        notificationPanel: notificationPanel
    }
}
