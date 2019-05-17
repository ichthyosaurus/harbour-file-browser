import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: panel
    anchors.fill: parent
    opacity: visible ? 1 : 0
    visible: false
    Behavior on opacity { NumberAnimation { duration: 500 } }

    // there should not be anything underneath
    color: "transparent"

    property var files: []
    property var targets: []
    property string action: ""
    property Page page
    property Item progressPanel

    property int _toGo: 0
    property int _current: 0
    property string _currentDir: ""
    property bool _finished: false

    on_FinishedChanged: {
        if (_finished) {
            page.backNavigation = true
            page.forwardNavigation = true
        }
    }

    MouseArea { // to catch all "stray" clicks
        anchors.fill: parent
        visible: parent.visible
        enabled: visible
    }

    Item {
        id: actionsRelay
        signal accepted
        signal rejected
        function accept() { accepted(); }
        function reject() { rejected(); }
    }

    SilicaListView {
        id: overwriteFileList
        anchors.fill: parent
        anchors.bottomMargin: 0
        clip: true

        model: files

        VerticalScrollDecorator { flickable: overwriteFileList }

        header: Item {
            width: parent.width
            height: header.height + actions.height + label.height + 4*Theme.paddingLarge

            Column {
                anchors.fill: parent

                PageHeader {
                    id: header
                    title: qsTr("Replace?")
                }

                Row {
                    id: actions
                    width: parent.width
                    height: Theme.itemSizeMedium + 2*Theme.paddingLarge
                    spacing: 10

                    BackgroundItem {
                        onClicked: actionsRelay.reject()
                        width: parent.width / 2 - 5
                        contentHeight: Theme.itemSizeMedium
                        _backgroundColor: Theme.rgba(pressed ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor,
                                                     Theme.highlightBackgroundOpacity)
                        Label {
                            text: qsTr("Cancel")
                            anchors.centerIn: parent
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                    }
                    BackgroundItem {
                        onClicked: actionsRelay.accept();
                        width: parent.width / 2 - 5
                        contentHeight: Theme.itemSizeMedium
                        _backgroundColor: Theme.rgba(pressed ? Theme.highlightBackgroundColor : Theme.highlightDimmerColor,
                                                     Theme.highlightBackgroundOpacity)
                        Label {
                            text: qsTr("Overwrite")
                            anchors.centerIn: parent
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                    }
                }

                Label {
                    id: label
                    text: qsTr("These files or folders already exist in %1:").arg(_currentDir)
                    wrapMode: Text.Wrap
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    color: Theme.highlightColor
                }
            }
        }

        delegate: Item {
            id: fileItem
            width: ListView.view.width
            height: listLabel.height

            Label {
                id: listLabel
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                text: modelData
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.primaryColor
            }
        }
    }

    Connections {
        target: engine
        onProgressChanged: progressPanel.text = engine.progressFilename
        onWorkerDone: progressPanel.hide()
        onWorkerErrorOccurred: {
            // the error signal goes to all pages in pagestack, show it only in the active one
            if (progressPanel.open) {
                progressPanel.hide();
                if (message === "Unknown error")
                    filename = qsTr("Trying to move between phone and SD Card? It does not work, try copying.");
                else if (message === "Failure to write block")
                    filename = qsTr("Perhaps the storage is full?");
                notificationPanel.showText(message, filename);
            }
        }
    }

    Connections {
        id: engineConnection
        target: null
        onWorkerDone: panel._doRecursiveTransfer();
    }

    Connections {
        id: mainConnections
        target: null
        onAccepted: {
            mainConnections.target = null
            panel.visible = false;
            panel._doPaste();
        }
        onRejected: {
            mainConnections.target = null;
            panel.visible = false;
            if (panel._toGo > 0) panel._doRecursiveTransfer();
            else _finished = true;
        }
    }

    function startTransfer(toTransfer, targetDirs, selectedAction) {
        page.backNavigation = false;
        page.forwardNavigation = false;

        files = toTransfer;
        targets = targetDirs;
        action = selectedAction;

        _toGo = targets.length;
        _current = 0;
        _finished = false;

        _doRecursiveTransfer();
    }

    function _doRecursiveTransfer() {
        engineConnection.target = null;

        if (action === "copy") {
            engine.copyFiles(files);
        } else if (action === "move") {
            if (_toGo > 1) {
                // Copy! We don't want to remove the source files yet!
                engine.copyFiles(files);
            } else {
                engine.cutFiles(files);
            }
        } else if (action === "link") {
            // not yet implemented
            return;
        }

        _currentDir = targets[_current]
        _toGo -= 1; _current += 1;

        var existingFiles = engine.listExistingFiles(_currentDir);
        if (existingFiles.length > 0) { // overwrite
            mainConnections.target = actionsRelay;
            panel.visible = true;
        } else { // everything's fine
            _doPaste();
        }
    }

    function _doPaste() {
        var panelText = ""
        if (action === "copy") panelText = qsTr("Copying");
        else if (action === "move") panelText = qsTr("Moving");
        else if (action === "link") panelText = qsTr("Linking");
        progressPanel.showText(panelText);

        engineConnection.target = null;
        if (_toGo > 0) engineConnection.target = engine;
        else _finished = true;
        engine.pasteFiles(_currentDir);
    }
}
