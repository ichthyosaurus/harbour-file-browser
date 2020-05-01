import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0

import "../js/bookmarks.js" as Bookmarks
import "../js/paths.js" as Paths

ListItem {
    id: fileItem
    menu: contextMenu
    contentHeight: Theme.itemSizeSmall
    height: contentHeight + (_menuItem ? _menuItem.height : 0)
    ListView.onRemove: animateRemoval(fileItem) // enable animated list item removals
    highlighted: down || isSelected || selectionArea.pressed
    property alias listLabelWidth: listLabel.width // see https://doc.qt.io/qt-5/qtquick-performance.html
    property bool galleryModeActiveAvailable: false

    Loader {
        id: gallery
        sourceComponent: undefined
        anchors { top: parent.top; left: parent.left; right: parent.right }
        visible: true; active: true
    }

    Component {
        id: galleryStillComponent
        Image {
            // 'fillMode: Image.PreserveAspectFit' does not scale up, so we do it manually
            asynchronous: true
            source: dir+"/"+filename
            sourceSize.width: parent.width
            width: parent.width
            height: Theme.paddingMedium + width * (implicitHeight / implicitWidth)
        }
    }

    Component {
        id: galleryAnimatedComponent
        AnimatedImage {
            asynchronous: true
            source: dir+"/"+filename
            width: parent.width
            height: Theme.paddingMedium + sourceSize.height * (width / sourceSize.width)
        }
    }

    Component {
        id: galleryVideoComponent
        Item {
            height: Theme.itemSizeExtraLarge
            width: parent.width
            Image {
                anchors.centerIn: parent
                height: Theme.itemSizeLarge
                source: "image://theme/icon-l-play?" + (fileItem.highlighted
                    ? Theme.highlightColor : Theme.primaryColor)
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    Item {
        anchors {
            left: parent.left; right: parent.right
            top: gallery.bottom; bottom: parent.bottom
        }

        FileIcon {
            id: listIcon
            x: Theme.paddingLarge
            clip: true
            anchors.verticalCenter: listLabel.verticalCenter
            width: Theme.iconSizeSmall; height: width
            showThumbnail: false

            highlighted: fileItem.highlighted
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

        Label {
            id: listLabel
            anchors {
                left: listIcon.right; leftMargin: Theme.paddingMedium
                right: parent.right; rightMargin: Theme.paddingLarge
                top: parent.top; topMargin: Theme.paddingSmall
            }
            text: filename
            elide: Text.ElideRight
            color: fileItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Loader {
            asynchronous: false
            anchors {
                left: listIcon.right; leftMargin: Theme.paddingMedium
                right: parent.right; rightMargin: Theme.paddingLarge
                top: listLabel.bottom; bottom: parent.bottom
            }
            sourceComponent: Flow {
                anchors.fill: parent

                Label {
                    id: sizeLabel
                    text: isLink ? (isDir ? (Paths.unicodeArrow()+" "+symLinkTarget) :
                                            (size+" "+qsTr("(link)"))) : (size)
                    color: fileItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Label {
                    id: permsLabel
                    visible: !(isLink && isDir)
                    text: filekind+permissions
                    color: fileItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Label {
                    id: datesLabel
                    visible: !(isLink && isDir)
                    text: modified
                    color: fileItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                states: [
                    State {
                        when: listLabelWidth >= 2*fileItem.width/3
                        PropertyChanges { target: listLabel; wrapMode: Text.NoWrap; elide: Text.ElideRight; maximumLineCount: 1 }
                        PropertyChanges { target: sizeLabel; width: ((isLink && isDir) ? listLabelWidth : listLabelWidth/3); horizontalAlignment: Text.AlignLeft }
                        PropertyChanges { target: permsLabel; width: listLabelWidth/3; horizontalAlignment: Text.AlignHCenter }
                        PropertyChanges { target: datesLabel; width: listLabelWidth/3; horizontalAlignment: Text.AlignRight }
                    },
                    State {
                        when: listLabelWidth < 2*fileItem.width/3
                        PropertyChanges { target: listLabel; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; elide: Text.ElideRight; maximumLineCount: 2 }
                        PropertyChanges { target: sizeLabel; width: listLabelWidth; horizontalAlignment: Text.AlignLeft }
                        PropertyChanges { target: permsLabel; width: listLabelWidth; horizontalAlignment: Text.AlignLeft }
                        PropertyChanges { target: datesLabel; width: listLabelWidth; horizontalAlignment: Text.AlignLeft }
                    }
                ]
            }
        }

        MouseArea {
            id: selectionArea
            anchors {
                left: parent.left; right: listLabel.left
                top: parent.top; bottom: parent.bottom
            }

            property int pressAndHoldInterval: 300
            Timer {
                interval: parent.pressAndHoldInterval
                running: parent.pressed
                onTriggered: parent.pressAndHold("")
            }

            onPressAndHold: {
                page.multiSelectionStarted(model.index);
                if (!isSelected) toggleSelection(index, false);
                selectionGlow.visible = true;
                page.multiSelectionFinished.connect(function(index) { selectionGlow.visible = false; });
                page.multiSelectionStarted.connect(function(index) { if (index !== model.index) selectionGlow.visible = false; });
            }

            onClicked: {
                toggleSelection(index);
            }
        }
    }

    onClicked: {
        if (fileModel.selectedFileCount > 0) {
            toggleSelection(index);
            return;
        }

        if (model.isDir) {
            pageStack.push(Qt.resolvedUrl("../pages/DirectoryPage.qml"),
                           { dir: fileModel.appendPath(listLabel.text) });
        } else if (galleryModeActiveAvailable && fileIcon === "file-image") {
            pageStack.push(Qt.resolvedUrl("../pages/ViewImagePage.qml"),
                           { path: fileModel.appendPath(listLabel.text), title: filename });
        } else if (galleryModeActiveAvailable && fileIcon === "file-video") {
            pageStack.push(Qt.resolvedUrl("../pages/ViewVideoPage.qml"),
                           { path: fileModel.appendPath(listLabel.text), title: filename, autoPlay: true });
        } else {
            pageStack.push(Qt.resolvedUrl("../pages/FilePage.qml"),
                           { file: fileModel.appendPath(listLabel.text) });
        }
    }

    states: [
        State {
            name: "hidden"
            when: !isMatched
            PropertyChanges {
                target: fileItem
                visible: false
                height: 0
                contentHeight: 0
            }
        },
        State {
            name: "galleryAvailableBase"
            PropertyChanges {
                target: fileItem
                contentHeight: Theme.itemSizeMedium + gallery.height
                galleryModeActiveAvailable: true
            }
            PropertyChanges { target: listIcon; showThumbnail: false; width: Theme.iconSizeSmall }
            AnchorChanges { target: listIcon; anchors.verticalCenter: listLabel.verticalCenter }
            AnchorChanges { target: selectionArea; anchors.right: parent.right }
        },
        State {
            name: "galleryAvailableAnimated"; extend: "galleryAvailableBase"
            when:    viewState === "gallery"
                  && fileIcon === "file-image"
                  && String(filename).toLowerCase().match(/\.(gif)$/) !== null
            PropertyChanges { target: gallery; sourceComponent: galleryAnimatedComponent }
        },
        State {
            name: "galleryAvailableStill"; extend: "galleryAvailableBase"
            when: viewState === "gallery" && fileIcon === "file-image"
            PropertyChanges { target: gallery; sourceComponent: galleryStillComponent }
        },
        State {
            name: "galleryAvailableVideo"; extend: "galleryAvailableBase"
            when: viewState === "gallery" && fileIcon === "file-video"
            PropertyChanges { target: gallery; sourceComponent: galleryVideoComponent }
        },
        State {
            name: "galleryUnavailable"; extend: "hidden"
            // hide everything except directories, images, and videos
            when: viewState === "gallery" && fileIcon !== "file-image" && fileIcon !== "file-video" && !isDir
        },
        State {
            name: "previewBaseState"
            PropertyChanges { target: listIcon; showThumbnail: true }
            AnchorChanges { target: listIcon; anchors.verticalCenter: parent.verticalCenter }
        },
        State {
            name: "preview/small"; extend: "previewBaseState"
            when: viewState === "preview/small"
            PropertyChanges { target: fileItem; contentHeight: Theme.itemSizeMedium }
            PropertyChanges { target: listIcon; width: Theme.itemSizeMedium }
        },
        State {
            name: "preview/medium"; extend: "previewBaseState"
            when: viewState === "preview/medium"
            PropertyChanges { target: fileItem; contentHeight: Theme.itemSizeExtraLarge }
            PropertyChanges { target: listIcon; width: Theme.itemSizeExtraLarge }
        },
        State {
            name: "preview/large"; extend: "previewBaseState"
            when: viewState === "preview/large"
            PropertyChanges { target: fileItem; contentHeight: fileItem.width/3 }
            PropertyChanges { target: listIcon; width: fileItem.width/3 }
        },
        State {
            name: "preview/huge"; extend: "previewBaseState"
            when: viewState === "preview/huge"
            PropertyChanges { target: fileItem; contentHeight: fileItem.width/3*2 }
            PropertyChanges { target: listIcon; width: fileItem.width/3*2 }
        }
    ]

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
                if (ctxBookmark.visible) ctxBookmark.hasBookmark = Bookmarks.hasBookmark(fileModel.fileNameAt(index))
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
                property bool hasBookmark: visible ? Bookmarks.hasBookmark(fileModel.fileNameAt(index)) : false
                text: hasBookmark ? qsTr("Remove bookmark") : qsTr("Add to bookmarks")
                onClicked: {
                    if (hasBookmark) {
                        Bookmarks.removeBookmark(fileModel.fileNameAt(index));
                        hasBookmark = false;
                    } else {
                        Bookmarks.addBookmark(fileModel.fileNameAt(index));
                        hasBookmark = true;
                    }
                }
            }
        }
    }
}
