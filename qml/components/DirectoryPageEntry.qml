/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2024 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * File Browser is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * File Browser is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import harbour.file.browser.Settings 1.0

import "../js/paths.js" as Paths

ListItem {
    id: listItem
    contentHeight: _baseEntryHeight + _extraContentHeight
    menu: contextMenu
    ListView.onRemove: animateRemoval(listItem)
    highlighted: down || isSelected || selectionArea.pressed || menuOpen

    property Item _remorseItem
    property int _extraContentHeight: 0
    property alias _listLabelWidth: listLabel.width
    property bool _showSelectionGlow: false
    property bool _galleryModeActiveAvailable: false
    property color _detailsColor: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor

    function deleteMe() {
        _remorseItem = remorseDelete(function(){
            clearSelectedFiles();
            markAsDoomed(fileModel.fileNameAt(index));
            progressPanel.showText(qsTr("Deleting"));
            engine.deleteFiles([fileModel.fileNameAt(index)]);
        });
    }

    onClicked: {
        if (fileModel.selectedFileCount > 0) {
            toggleSelection(index);
            return;
        }

        if (isDir) {
            navigate_goToFolder(fileModel.appendPath(filename));
        } else if (_galleryModeActiveAvailable && fileIcon === "file-image") {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/ViewImagePage.qml"),
                                   { path: fileModel.appendPath(filename), title: filename });
        } else if (_galleryModeActiveAvailable && fileIcon === "file-video") {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/ViewVideoPage.qml"),
                                   { path: fileModel.appendPath(filename), title: filename, autoPlay: true });
        } else {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/FilePage.qml"),
                                   { file: fileModel.appendPath(filename) });
        }
    }

    Connections {
        target: page
        onMultiSelectionFinished: listItem._showSelectionGlow = false
        onMultiSelectionStarted: if (index !== model.index) listItem._showSelectionGlow = false
    }

    Loader {
        id: gallery
        sourceComponent: undefined
        anchors { top: parent.top; left: parent.left; right: parent.right }
        visible: active; active: viewState === "gallery"
    }

    Item {
        id: infoContainer
        anchors {
            left: parent.left; right: parent.right
            top: gallery.bottom; bottom: parent.bottom
        }

        Loader {
            id: listIcon
            x: Theme.paddingLarge
            width: _baseIconSize; height: width
            anchors.verticalCenter: _thumbnailsEnabled ? parent.verticalCenter :
                                                         listLabel.verticalCenter
            sourceComponent: listIconComponent
            asynchronous: index > 20
        }

        Loader {
            // circle shown when item is selected
            anchors.verticalCenter: listLabel.verticalCenter
            x: Theme.paddingLarge - 2*Theme.pixelRatio
            width: Theme.iconSizeSmall + 4*Theme.pixelRatio
            height: width
            sourceComponent: isSelected ? selectionMarkerComponent : null
        }

        Label {
            id: listLabel
            anchors {
                left: listIcon.right; leftMargin: Theme.paddingMedium
                right: parent.right; rightMargin: Theme.paddingLarge
                top: parent.top; topMargin: Theme.paddingSmall
            }
            text: filename
            truncationMode: _nameTruncMode
            elide: _nameElideMode
            highlighted: listItem.highlighted
        }

        Loader {
            sourceComponent: fileDetailsComponent
            asynchronous: index > 20
            anchors {
                left: listIcon.right; leftMargin: Theme.paddingMedium
                right: parent.right; rightMargin: Theme.paddingLarge
                top: listLabel.bottom; bottom: parent.bottom
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

            onClicked: toggleSelection(index);
            onPressAndHold: {
                if (!isSelected) toggleSelection(index, false);
                page.multiSelectionStarted(model.index);
                listItem._showSelectionGlow = true;
            }
        }
    }

    Component {
        id: galleryStillComponent
        Image {
            // 'fillMode: Image.PreserveAspectFit' does not scale up, so we do it manually
            asynchronous: true
            source: dir+"/"+filename
            sourceSize.width: parent.width
            width: parent.width
            opacity: highlighted ? Theme.opacityLow : 1.0
            height: Theme.paddingMedium +
                    (status === Image.Loading ?
                         width : (width * (implicitHeight / implicitWidth)))
        }
    }

    Component {
        id: galleryAnimatedComponent
        AnimatedImage {
            asynchronous: true
            source: dir+"/"+filename
            width: parent.width
            height: Theme.paddingMedium + sourceSize.height * (width / sourceSize.width)
            opacity: highlighted ? Theme.opacityLow : 1.0
        }
    }

    Component {
        id: galleryVideoComponent
        Item {
            height: Theme.itemSizeExtraLarge
            width: parent.width
            opacity: highlighted ? Theme.opacityLow : 1.0
            Image {
                anchors.centerIn: parent
                height: Theme.itemSizeLarge
                source: "image://theme/icon-l-play?" + (listItem.highlighted
                                                        ? Theme.highlightColor :
                                                          Theme.primaryColor)
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    Component {
        id: listIconComponent
        FileIcon {
            showThumbnail: _thumbnailsEnabled
            highlighted: listItem.highlighted
            file: showThumbnail ? dir+"/"+filename : ""
            isDirectory: isDir
            showBusy: isDoomed
            mimeTypeCallback: function() { return fileModel.mimeTypeAt(index); }
            fileIconCallback: function() { return fileIcon; }
        }
    }

    Component {
        id: fileDetailsComponent
        Flow {
            anchors.fill: parent
            Label {
                id: sizeLabel
                text: isLink ? (size+" "+Paths.unicodeArrow()+" "+symLinkTarget) : (size)
                color: _detailsColor
                truncationMode: TruncationMode.Fade
                elide: Text.ElideMiddle
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                id: permsLabel
                visible: !isLink
                text: filekind+permissions
                color: _detailsColor
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                id: datesLabel
                text: modified
                color: _detailsColor
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            states: [
                State {
                    when: _listLabelWidth >= 2*listItem.width/3
                    PropertyChanges { target: listLabel; wrapMode: Text.NoWrap; maximumLineCount: 1 }
                    PropertyChanges { target: sizeLabel; width: (isLink ? _listLabelWidth/3*2 : _listLabelWidth/3); horizontalAlignment: Text.AlignLeft }
                    PropertyChanges { target: permsLabel; width: _listLabelWidth/3; horizontalAlignment: Text.AlignHCenter }
                    PropertyChanges { target: datesLabel; width: _listLabelWidth/3; horizontalAlignment: Text.AlignRight }
                },
                State {
                    when: _listLabelWidth < 2*listItem.width/3
                    PropertyChanges { target: listLabel; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; maximumLineCount: 2 }
                    PropertyChanges { target: sizeLabel; width: _listLabelWidth; horizontalAlignment: Text.AlignLeft }
                    PropertyChanges { target: permsLabel; width: _listLabelWidth; horizontalAlignment: Text.AlignLeft }
                    PropertyChanges { target: datesLabel; width: _listLabelWidth; horizontalAlignment: Text.AlignLeft }
                }
            ]
        }
    }

    Component {
        id: selectionMarkerComponent
        Rectangle {
            visible: isSelected
            color: "transparent"
            border.color: Theme.highlightColor
            border.width: 2.25*Theme.pixelRatio
            radius: width*0.5

            Rectangle {
                id: selectionGlow // TODO use only one globally
                visible: isSelected && listItem._showSelectionGlow
                anchors.centerIn: parent
                width: Theme.iconSizeExtraLarge; height: width
                radius: width/2
                color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
            }
        }
    }

    Component {
        id: contextMenu
        ContextMenu {
            id: menu
            property bool _triggerDelete: false
            onActiveChanged: {
                if (!active) return;
                remorsePopup.cancel(); // cancel delete if context menu is opened
                if (_remorseItem) _remorseItem.cancel();
                clearSelectedFiles();
            }
            onClosed: {
                // delayed action so that menu has already closed when it is re-arranged
                if (_triggerDelete) {
                    listItem.deleteMe();
                }
            }

            FileActions {
                id: fileActions
                showLabel: false
                selectedFiles: function() { return [fileModel.fileNameAt(index)]; }
                selectedCount: 1
                showShare: !model.isLink
                showEdit: fileData.checkSafeToEdit(fileModel.fileNameAt(index))
                showEditLink: model.isLink && fileData.checkSafeToChangeLink(fileModel.fileNameAt(index))
                showSelection: false
                showCompress: false
                onDeleteTriggered: {
                    menu._triggerDelete = true;
                    menu.close();
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
                visible: model.isLink && !!model.symLinkTargetFolder
                text: model.isDir ?
                          qsTr("Open target folder") :
                          qsTr("Open containing folder")
                onDelayedClick: {
                    if (model.isDir) {
                        navigate_goToFolder(symLinkTarget)
                    } else {
                        navigate_goToFolder(symLinkTargetFolder)
                    }
                }
            }

            MenuItem {
                visible: model.isDir
                text: bookmark.marked ? qsTr("Remove bookmark") : qsTr("Add to bookmarks")
                onDelayedClick: bookmark.toggle()

                Bookmark {
                    id: bookmark
                    path: fileModel.fileNameAt(index)
                }
            }
        }
    }

    states: [
        State {
            name: "galleryAvailableBase"
            PropertyChanges {
                target: listItem
                _extraContentHeight: gallery.height
                _galleryModeActiveAvailable: true
            }
            // AnchorChanges { target: listIcon; anchors.verticalCenter: listLabel.verticalCenter }
            AnchorChanges { target: selectionArea; anchors.right: parent.right }
        },
        State {
            name: "galleryAvailableAnimated"; extend: "galleryAvailableBase"
            when:    viewState === "gallery"
                  && fileIcon === "file-image"
                  && String(filename).match(/\.(gif)$/i) !== null
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
            name: "galleryUnavailable"
            // hide gallery view for non-media files (entry is still shown)
            when: viewState === "gallery" && fileIcon !== "file-image" && fileIcon !== "file-video" && !isDir
            PropertyChanges { target: gallery; sourceComponent: undefined }
        }
    ]
}
