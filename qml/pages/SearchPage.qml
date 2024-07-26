/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2015, 2018-2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
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
import harbour.file.browser.SearchEngine 1.0
import harbour.file.browser.FileClipboard 1.0
import harbour.file.browser.Settings 1.0

import "../components"
import "../js/paths.js" as Paths

Page {
    id: page
    objectName: "SearchPage"
    allowedOrientations: Orientation.All

    property string dir: "/" // holds the top directory where all searches will be made
    property string currentDirectory: "" // holds the directory which is being searched by SearchEngine
    property string searchText: "" // holds the initial search text
    property bool startImmediately: false // if search text is given, start search as soon as page is ready

    property bool _initialSearchDone: false
    property string _fnElide: GlobalSettings.generalFilenameElideMode
    property int nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    property int nameElideMode: nameTruncMode === TruncationMode.Fade ?
                                    Text.ElideNone : (_fnElide === 'middle' ?
                                                          Text.ElideMiddle : Text.ElideRight)

    // used to disable SelectionPanel while remorse timer is active
    property bool remorsePopupActive: false // set to true when remorsePopup is active (at top of page)
    property bool remorseItemActive: false // set to true when remorseItem is active (item level)

    property int _selectedFileCount: 0

    // this and its bg worker thread will be destroyed when page is popped from stack
    SearchEngine {
        id: searchEngine
        dir: page.dir

        // react on signals from SearchEngine
        onProgressChanged: page.currentDirectory = directory
        onMatchFound: listModel.append({ fullname: fullname, filename: filename,
                                         absoluteDir: absoluteDir,
                                         fileIcon: fileIcon, fileKind: fileKind,
                                         isSelected: false, mimeType: mimeType
                                       });
        onWorkerDone: { clearCover(); }
        onWorkerErrorOccurred: { clearCover(); notificationPanel.showText(message, filename); }
    }

    RemorsePopup {
        id: remorsePopup
        onCanceled: remorsePopupActive = false
        onTriggered: remorsePopupActive = false
    }

    SilicaListView {
        id: fileList
        anchors.fill: parent
        anchors.bottomMargin: selectionPanel.visible ? selectionPanel.visibleSize : 0
        footer: Spacer { height: Theme.horizontalPageMargin; }
        clip: true

        visible: true
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        // prevent newly added list delegates from stealing focus away from the search field
        currentIndex: -1

        model: ListModel {
            id: listModel
            // updates the model by clearing all data and starting
            // searchEngine search() method asynchronously, using the
            // given text as the search query
            function update(text) {
                if (text === "") searchEngine.cancel();
                clear();
                clearSelectedFiles();
                if (text !== "") {
                    searchEngine.search(text);
                    coverText = qsTr("Searching")+"\n"+text;
                }
            }
        }

        VerticalScrollDecorator { flickable: fileList }

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(main.settingsPage)
            }
        }

        header: Item {
            width: parent.width
            height: head.height + Theme.itemSizeExtraLarge

            PageHeader {
                id: head
                title: qsTr("Search")
                description: page.dir
            }

            Item {
                anchors.top: head.bottom
                width: parent.width
                height: Theme.itemSizeExtraLarge

                SearchField {
                    id: searchField
                    anchors.left: parent.left
                    anchors.right: cancelSearchButton.left
                    y: Theme.paddingSmall
                    placeholderText: qsTr("Search below “%1”").arg(Paths.formatPathForSearch(page.dir))
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                    text: page.searchText

                    // get focus when page is shown for the first time
                    Component.onCompleted: if (!startImmediately) forceActiveFocus();

                    onTextChanged: {
                        if (text == "") {
                            // force focus when the field has been cleared
                            forceActiveFocus()
                        }
                    }

                    // return key on virtual keyboard starts or restarts search
                    EnterKey.enabled: true
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: {
                        notificationPanel.hide();
                        listModel.update(searchField.text);
                        foundText.visible = true;
                        searchField.focus = false;
                    }
                }
                // our own "IconButton" to make the mouse area large and easier to tap
                IconButton {
                    id: cancelSearchButton
                    anchors.right: parent.right
                    anchors.top: searchField.top
                    width: Theme.iconSizeMedium+Theme.paddingLarge
                    height: searchField.height
                    onClicked: {
                            if (!searchEngine.running) {
                                listModel.update(searchField.text);
                                foundText.visible = true;
                            } else {
                                searchEngine.cancel()
                            }
                        }
                    icon.color: Theme.primaryColor
                    icon.source: searchEngine.running ? "image://theme/icon-m-clear" :
                                                           "../images/icon-btn-search.png"
                }
                BusyIndicator {
                    id: searchBusy
                    anchors.centerIn: cancelSearchButton
                    running: searchEngine.running
                    size: BusyIndicatorSize.Small
                }

                Label {
                    id: foundText
                    visible: startImmediately

                    anchors {
                        left: parent.left
                        leftMargin: searchField.textLeftMargin
                        top: searchField.bottom
                        topMargin: -Theme.paddingMedium
                    }

                    text: qsTr("%n hit(s)", "", listModel.count)
                    font.pixelSize: Theme.fontSizeTiny
                    color: searchField.placeholderColor
                }
                Label {
                    anchors {
                        left: foundText.left
                        leftMargin: Theme.itemSizeSmall
                        right: parent.right
                        rightMargin: Theme.paddingLarge
                        top: searchField.bottom
                        topMargin: -Theme.paddingMedium
                    }

                    text: page.currentDirectory
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.secondaryColor
                    elide: Text.ElideMiddle
                }
            }
        }

        delegate: ListItem {
            id: fileItem
            menu: contextMenu
            width: ListView.view.width
            contentHeight: listLabel.height+listAbsoluteDir.height + 13

            // background shown when item is selected
            Rectangle {
                visible: isSelected
                anchors.fill: parent
                color: fileItem.highlightedColor
            }

            FileIcon {
                id: listIcon
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.paddingLarge
                width: Theme.itemSizeSmall
                height: width
                showThumbnail: true
                highlighted: fileItem.highlighted || isSelected
                file: model.fullname
                isDirectory: model.fileKind === "d"
                mimeTypeCallback: function() { return model.mimeType; }
                fileIconCallback: function() { return fileIcon; }
            }

            // circle shown when item is selected
            Rectangle {
                visible: isSelected
                anchors.verticalCenter: listLabel.verticalCenter
                x: Theme.paddingLarge - 2*Theme.pixelRatio
                width: Theme.iconSizeSmall + 4*Theme.pixelRatio
                height: Theme.iconSizeSmall + 4*Theme.pixelRatio
                color: "transparent"
                border.color: Theme.highlightColor
                border.width: 2.25 * Theme.pixelRatio
                radius: width * 0.5
            }
            Label {
                id: listLabel
                y: Theme.paddingSmall
                anchors {
                    left: listIcon.right; leftMargin: Theme.paddingMedium
                    right: parent.right; rightMargin: Theme.paddingLarge
                }
                text: filename
                textFormat: Text.PlainText
                truncationMode: nameTruncMode
                elide: nameElideMode
                color: fileItem.highlighted || isSelected ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: listAbsoluteDir
                anchors {
                    left: listIcon.right; leftMargin: Theme.paddingMedium
                    right: parent.right; rightMargin: Theme.paddingLarge
                    top: listLabel.bottom
                }
                text: absoluteDir
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                elide: Text.ElideLeft
            }

            onClicked: {
                if (model.fileKind === "d") {
                    pageStack.animatorPush(Qt.resolvedUrl("DirectoryPage.qml"),
                                           { dir: model.fullname });
                } else {
                    pageStack.animatorPush(Qt.resolvedUrl("FilePage.qml"),
                                           { file: model.fullname });
                }
            }
            MouseArea {
                width: Theme.itemSizeSmall
                height: parent.height
                onClicked: {
                    if (!model.isSelected) {
                        _selectedFileCount++;
                        var item = { fullname: fullname, filename: filename,
                            absoluteDir: absoluteDir,
                            fileIcon: fileIcon, fileKind: fileKind,
                            isSelected: true
                        };
                        fileList.model.set(index, item);
                    } else {
                        _selectedFileCount--;
                        var item2 = { fullname: fullname, filename: filename,
                            absoluteDir: absoluteDir,
                            fileIcon: fileIcon, fileKind: fileKind,
                            isSelected: false
                        };
                        fileList.model.set(index, item2);
                    }
                    selectionPanel.open = (_selectedFileCount > 0);
                    selectionPanel.overrideText = "";
                }
            }

            RemorseItem {
                id: remorseItem
                onTriggered: remorseItemActive = false
                onCanceled: remorseItemActive = false
            }

            // delete file after remorse time
            function deleteFile(deleteFilename) {
                remorseItemActive = true;
                remorseItem.execute(fileItem, qsTr("Deleting"), function() {
                    progressPanel.showText(qsTr("Deleting"));
                    engine.deleteFiles([ deleteFilename ]);
                });
            }

            // enable animated list item removals
            ListView.onRemove: animateRemoval(fileItem)

            // context menu is activated with long press, visible if search is not running
            Component {
                 id: contextMenu
                 ContextMenu {
                     // cancel delete if context menu is opened
                     onActiveChanged: { remorsePopup.cancel(); clearSelectedFiles(); }
                     MenuItem {
                         text: qsTr("Go to containing folder")
                         onClicked: navigate_goToFolder(model.absoluteDir)
                     }
                     MenuItem {
                        text: qsTr("Cut")
                        onClicked: FileClipboard.setPaths([model.fullname], FileClipMode.Cut)
                     }
                     MenuItem {
                         text: qsTr("Copy")
                         onClicked: {
                             FileClipboard.setPaths([model.fullname], FileClipMode.Copy)
                         }
                     }
                     MenuItem {
                         text: qsTr("Delete")
                         onClicked: deleteFile(model.fullname);
                     }
                 }
             }
        }
    }

    function clearCover() {
        coverText = qsTr("Search");
    }

    // a bit hackery: these are called from selection panel
    function selectedFiles() {
        var list = [];
        for (var i = 0; i < listModel.count; ++i) {
            var item = listModel.get(i);
            if (item.isSelected)
                list.push(item.fullname);
        }
        return list;
    }
    function clearSelectedFiles() {
        for (var i = 0; i < listModel.count; ++i) {
            // get returns a reference to the item
            // changing the item properties changes its properties in the list
            var item = listModel.get(i);
            item.isSelected = false;
        }
        _selectedFileCount = 0;
        selectionPanel.overrideText = "";
    }
    function selectAllFiles() {
        for (var i = 0; i < listModel.count; ++i) {
            // get returns a reference to the item
            // changing the item properties changes its properties in the list
            var item = listModel.get(i);
            item.isSelected = true;
        }
        _selectedFileCount = listModel.count;
        selectionPanel.overrideText = "";
    }

    SelectionPanel {
        id: selectionPanel
        selectedCount: _selectedFileCount
        enabled: !page.remorsePopupActive && !page.remorseItemActive
        displayClose: _selectedFileCount === listModel.count
        selectedFiles: parent.selectedFiles

        Connections {
            target: selectionPanel.actions
            onCloseTriggered: clearSelectedFiles();
            onSelectAllTriggered: selectAllFiles();
            onDeleteTriggered: {
                var files = selectedFiles();
                remorsePopupActive = true;
                remorsePopup.execute(qsTr("Deleting"), function() {
                    clearSelectedFiles();
                    progressPanel.showText(qsTr("Deleting"));
                    engine.deleteFiles(files);
                });
            }
            onTransferTriggered: {
                if (remorsePopupActive) return;
                if (transferPanel.status === Loader.Ready) transferPanel.item.startTransfer(toTransfer, targets, selectedAction, goToTarget);
                else notificationPanel.showText(qsTr("Internally not ready"), qsTr("Please simply try again"));
            }
        }
    }

    // connect signals from engine to panels
    Connections {
        target: engine
        onProgressChanged: progressPanel.text = engine.progressFilename
        onWorkerDone: progressPanel.hide()
        onWorkerErrorOccurred: {
            // the error signal goes to all pages in pagestack, show it only in the active one
            if (progressPanel.open) {
                progressPanel.hide();
                notificationPanel.showText(message, filename);
            }
        }

        // item got deleted by worker, so remove it from list
        onFileDeleted: {
            for (var i = 0; i < listModel.count; ++i) {
                var item = listModel.get(i);
                if (item.fullname === fullname) {
                    listModel.remove(i)
                    return;
                }
            }
        }
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

    Loader {
        id: transferPanel
        asynchronous: true
        anchors.fill: parent
        Component.onCompleted: {
            setSource(Qt.resolvedUrl("../components/TransferPanel.qml"),
                      { "page": page, "progressPanel": progressPanel,
                        "notificationPanel": notificationPanel });
        }
        Connections {
            target: transferPanel.item
            onOverlayShown: { fileList.visible = false; }
            onOverlayHidden: { fileList.visible = true; }
        }
    }

    onStatusChanged: {
        if (_initialSearchDone) return;
        if (status === PageStatus.Activating) {
            // clearSelectedFiles();
            clearCover();

            // TODO enable once it no longer messes up the page stack
            // main.activePage = {type: "search", path: dir, query: searchText};
            // navigate_syncNavStack();
        } else if (status === PageStatus.Active &&
                   startImmediately === true && searchText !== "") {
            listModel.update(searchText);
            _initialSearchDone = true;
        }
    }
}
