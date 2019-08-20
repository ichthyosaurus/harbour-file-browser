import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "../pages/functions.js" as Functions

ListItem {
    id: fileItem
    menu: contextMenu
    contentHeight: fileIconSize
    visible: isMatched
    height: isMatched ? contentHeight + (_menuItem ? _menuItem.height : 0) : 0

    // warning: huge performance impact with large directories
    // Behavior on height { NumberAnimation { } }

    // background shown when item is selected
    Rectangle {
        visible: isSelected
        anchors.fill: parent
        color: fileItem.highlightedColor
    }

    FileIcon {
        id: listIcon
        clip: true
        anchors.verticalCenter: thumbnailsShown ? parent.verticalCenter : listLabel.verticalCenter
        x: Theme.paddingLarge
        width: (!thumbnailsShown && fileIconSize === Theme.itemSizeSmall) ? Theme.iconSizeSmall : fileIconSize
        height: width
        showThumbnail: thumbnailsShown
        highlighted: fileItem.highlighted || isSelected
        file: fileModel.appendPath(listLabel.text)
        isDirectory: isDir
        mimeTypeCallback: function() { return fileModel.mimeTypeAt(index); }
        fileIconCallback: function() { return fileIcon; }
    }

    // circle shown when item is selected
    Rectangle {
        visible: isSelected
        anchors.verticalCenter: listLabel.verticalCenter
        x: Theme.paddingLarge - 2*Theme.pixelRatio
        width: Theme.iconSizeSmall + 4*Theme.pixelRatio
        height: width
        color: "transparent"
        border.color: Theme.highlightColor
        border.width: 2.25 * Theme.pixelRatio
        radius: width * 0.5
        onVisibleChanged: if (!visible) selectionGlow.visible = false

        Rectangle {
            id: selectionGlow
            visible: false
            anchors.centerIn: parent
            width: Theme.iconSizeExtraLarge; height: width
            radius: width/2
            color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
        }
    }

    property alias listLabelWidth: listLabel.width // see https://doc.qt.io/qt-5/qtquick-performance.html
    Label {
        id: listLabel
        anchors.left: listIcon.right
        anchors.leftMargin: Theme.paddingMedium
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        y: Theme.paddingSmall
        text: filename
        elide: Text.ElideRight
        color: fileItem.highlighted || isSelected ? Theme.highlightColor : Theme.primaryColor
    }

    Loader {
        asynchronous: false
        anchors {
            left: listIcon.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.paddingLarge
            top: listLabel.bottom
        }
        sourceComponent: Flow {
            anchors.fill: parent
            Label {
                id: sizeLabel
                text: isLink ? (isDir ? (Functions.unicodeArrow()+" "+symLinkTarget) :
                                        (size+" "+qsTr("(link)"))) : (size) //  !(isLink && isDir) ? size : Functions.unicodeArrow()+" "+symLinkTarget
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                id: permsLabel
                visible: !(isLink && isDir)
                text: filekind+permissions
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                id: datesLabel
                visible: !(isLink && isDir)
                text: modified
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            states: [
                State {
                    when: listLabelWidth >= 2*page.width/3
                    PropertyChanges { target: listLabel; wrapMode: Text.NoWrap; elide: Text.ElideRight; maximumLineCount: 1 }
                    PropertyChanges { target: sizeLabel; width: ((isLink && isDir) ? listLabelWidth : listLabelWidth/3); horizontalAlignment: Text.AlignLeft }
                    PropertyChanges { target: permsLabel; width: listLabelWidth/3; horizontalAlignment: Text.AlignHCenter }
                    PropertyChanges { target: datesLabel; width: listLabelWidth/3; horizontalAlignment: Text.AlignRight }
                },
                State {
                    when: listLabelWidth < 2*page.width/3
                    PropertyChanges { target: listLabel; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; elide: Text.ElideRight; maximumLineCount: 2 }
                    PropertyChanges { target: sizeLabel; width: listLabelWidth; horizontalAlignment: Text.AlignLeft }
                    PropertyChanges { target: permsLabel; width: listLabelWidth; horizontalAlignment: Text.AlignLeft }
                    PropertyChanges { target: datesLabel; width: listLabelWidth; horizontalAlignment: Text.AlignLeft }
                }
            ]
        }
    }

    onClicked: {
        if (selectionGlow.visible) {
            toggleSelection(index);
            return;
        }

        if (model.isDir) {
            pageStack.push(Qt.resolvedUrl("../pages/DirectoryPage.qml"),
                           { dir: fileModel.appendPath(listLabel.text) });
        } else {
            pageStack.push(Qt.resolvedUrl("../pages/FilePage.qml"),
                           { file: fileModel.appendPath(listLabel.text) });
        }
    }

    MouseArea {
        width: fileIconSize
        height: parent.height
        onPressed: shiftTimer.start()
        onPositionChanged: if (shiftTimer.running) shiftTimer.stop();
        onReleased: {
            if (!selectionGlow.visible) toggleSelection(index);
            if (shiftTimer.running) shiftTimer.stop();
        }

        Timer {
            id: shiftTimer
            interval: 300
            onTriggered: {
                page.multiSelectionStarted(model.index);
                if (!isSelected) toggleSelection(index, false);
                selectionGlow.visible = true;
                page.multiSelectionFinished.connect(function(index) { selectionGlow.visible = false; });
                page.multiSelectionStarted.connect(function(index) { if (index !== model.index) selectionGlow.visible = false; });
            }
        }
    }

    // enable animated list item removals
    ListView.onRemove: animateRemoval(fileItem)

    // context menu is activated with long press
    Component {
         id: contextMenu
         ContextMenu {
             id: menu
             // cancel delete if context menu is opened
             onActiveChanged: {
                if (!active) return;
                remorsePopup.cancel();
                clearSelectedFiles();
                if (ctxBookmark.visible) ctxBookmark.hasBookmark = Functions.hasBookmark(fileModel.fileNameAt(index))
             }
             FileActions {
                 id: fileActions
                 showLabel: false
                 selectedFiles: function() { return [fileModel.fileNameAt(index)]; }
                 selectedCount: 1
                 showShare: !model.isLink
                 showSelection: false; showEdit: false; showCompress: false
                 onDeleteTriggered: {
                     remorsePopupActive = true;
                     remorsePopup.execute(qsTr("Deleting"), function() {
                         clearSelectedFiles();
                         progressPanel.showText(qsTr("Deleting"));
                         engine.deleteFiles([fileModel.fileNameAt(index)]);
                         menu.close();
                     });
                 }
                 onCutTriggered: menu.close();
                 onCopyTriggered: menu.close();
                 // As the menu is closed when a new page is pushed on the stack,
                 // we cannot receive the transferTriggered signal. (Or rather,
                 // it cannot be sent, because it is deleted.)
                 // This means that transferring from here is impossible,
                 // plus that we cannot notify errors when renaming.
                 // Cut, copy, delete, info, and share work fine, though.
                 showTransfer: false
             }
             MenuItem {
                id: ctxBookmark
                visible: model.isDir
                property bool hasBookmark: visible ? Functions.hasBookmark(fileModel.fileNameAt(index)) : false
                text: hasBookmark ? qsTr("Remove bookmark") : qsTr("Add to bookmarks")
                onClicked: {
                    if (hasBookmark) {
                        Functions.removeBookmark(fileModel.fileNameAt(index));
                        hasBookmark = false;
                    } else {
                        Functions.addBookmark(fileModel.fileNameAt(index));
                        hasBookmark = true;
                    }
                }
             }
         }
     }
}
