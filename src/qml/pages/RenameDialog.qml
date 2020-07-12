import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/paths.js" as Paths

Dialog {
    id: dialog
    allowedOrientations: Orientation.All
    canAccept: _readyCount === files.length

    property var files: []
    property var newFiles: []
    property string basePath: ""
    property string errorMessages: []
    property int _readyCount: 0

    Component.onCompleted: basePath = Paths.dirName(files[0])

    onAccepted: {
        for (var i = 0; i < repeater.count; i++) {
            var item = repeater.itemAt(i);
            if (!item) continue;
            var res = engine.rename(item.originalName, item.nameField.text);
            if (res[1] !== "") errorMessages.push(res[1])
            newFiles.push(res[0]);
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 2*Theme.paddingLarge

            DialogHeader {
                id: dialogHeader
                acceptText: qsTr("Rename")
            }

            Repeater {
                id: repeater
                model: files.length
                Component.onCompleted: itemAt(0).nameField.forceActiveFocus();

                delegate: Column {
                    property alias nameField: newNameLabel
                    property string originalName: files[index]

                    height: titleLabel.height + Theme.paddingLarge + newNameLabel.height
                    width: dialog.width

                    Label {
                        id: titleLabel
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        text: qsTr("Give a new name for\n%1").arg(parent.originalName)
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                    }

                    Spacer { height: Theme.paddingLarge}

                    TextField {
                        id: newNameLabel
                        width: parent.width
                        placeholderText: qsTr("New name")
                        label: qsTr("New name")
                        inputMethodHints: Qt.ImhNoPredictiveText

                        // when enter is pressed, either
                        // - go to next text field
                        // - accept dialog (if possible)
                        // - else hide the virtual keyboard
                        EnterKey.enabled: newNameLabel.text.length > 0
                        EnterKey.iconSource: ((index < files.length-1) ? "image://theme/icon-m-enter-next" :
                            (dialog.canAccept ? "image://theme/icon-m-enter-accept" : "image://theme/icon-m-enter-close"))
                        EnterKey.onClicked: {
                            var next = repeater.itemAt(index+1)
                            if (next && next.nameField) next.nameField.forceActiveFocus();
                            else if (dialog.canAccept) accept();
                        }

                        property bool notifiedAsReady: false
                        onTextChanged: {
                            if (text === "" || engine.exists(basePath+text)) {
                                color = "red";

                                if (notifiedAsReady) {
                                    dialog._readyCount -= 1;
                                    notifiedAsReady = false;
                                }
                            } else {
                                color = Theme.primaryColor;

                                if (!notifiedAsReady) {
                                    dialog._readyCount += 1;
                                    notifiedAsReady = true;
                                }
                            }
                        }

                        Component.onCompleted: {
                            text = Paths.lastPartOfPath(parent.originalName)
                            dialog._readyCount = 0; notifiedAsReady = false;
                        }
                    }
                }
            }
        }
    }
}
