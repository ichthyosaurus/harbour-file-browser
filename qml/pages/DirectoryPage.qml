/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014, 2016, 2018-2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Joona Petrell
 * SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
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

import "../components"
import "../js/bookmarks.js" as Bookmarks
import "../js/paths.js" as Paths
import "../js/files.js" as Files

Page {
    id: page
    objectName: "directoryPage"
    allowedOrientations: Orientation.All
    property bool _ready: false
    property string _activeDir: ""
    property string dir: "/"

    property bool remorsePopupActive: false // set to true when remorsePopup is active
    property bool remorseItemActive: false // set to true when remorseItem is active (item level)
    property alias progressPanel: progressPanel
    property alias notificationPanel: notificationPanel
    property alias hasBookmark: bookmarkEntry.hasBookmark
    property string currentFilter: ""
    // set to true when full dir path should be shown in page header
    property bool fullPathShown: (settings.read("General/ShowFullDirectoryPaths", "false") === "true")
    // set to true to enable starting deep search when pressing 'Enter' in filter input
    property bool quickSearchEnabled: (settings.read("General/DefaultFilterAction", "filter") === "search")
    property bool navMenuIconShown: (settings.read("General/ShowNavigationMenuIcon", "true") === "true")

    property string viewState: updateThumbnailsState() // state for list delegates
    property int _baseIconSize: (viewState === '' || viewState === 'gallery') ? Theme.iconSizeSmall : _baseEntryHeight
    property bool _thumbnailsEnabled: viewState !== '' && viewState !== 'gallery'
    property int _baseEntryHeight: {
        if (viewState === 'gallery') {
            return Theme.itemSizeMedium
        } else if (viewState === "preview/small") {
            return Theme.itemSizeMedium
        } else if (viewState === "preview/medium") {
            return Theme.itemSizeExtraLarge
        } else if (viewState === "preview/large") {
            return width/3
        } else if (viewState === "preview/huge") {
            return width/3*2
        } else {
            return Theme.itemSizeSmall
        }
    }

    property string _fnElide: settings.read("General/FilenameElideMode", "fade")
    property int _nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    property int _nameElideMode: _nameTruncMode === TruncationMode.Fade ?
                                    Text.ElideNone : (_fnElide === 'middle' ?
                                                          Text.ElideMiddle : Text.ElideRight)

    signal clearViewFilter()
    signal multiSelectionStarted(var index)
    signal multiSelectionFinished(var index)
    signal selectionChanged(var index)
    signal markAsDoomed(var file)

    onMarkAsDoomed: fileModel.markAsDoomed(file)

    FileModel {
        id: fileModel
        dir: _activeDir
        filterString: currentFilter
        // page.status does not exactly work - root folder seems to be active always??
        active: page.status === PageStatus.Active
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
        clip: true

        visible: true
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        // We explicitly disable the model to show an error
        // message or the current status.
        model: (statusMessage.enabled || busyIndicator.enabled) ?
                   null : fileModel

        VerticalScrollDecorator { flickable: fileList }

        PullDownMenu {
            id: pullDownMenu
            on_AtFinalPositionChanged: {
                if (!_filterBlocked) {
                    filterField.forceActiveFocus()
                }
            }
            onActiveChanged: filterField.enabled = active
            enabled: !dirPopup.active
            busy: fileModel.busy || fileModel.partlyBusy

            // We explicitly block the filter field when a
            // menu item is selected so the keyboard won't flicker
            // while a new page is pushed on the stack.
            // After returning the user has to enable the filter
            // field once manually by clicking on it.
            // This is the only solution that actually worked
            // because on_AtFinalPositionChanged seems to be
            // quite unreliable/buggy. (We shouldn't be using it anyways.)
            property bool _filterBlocked: false

            MenuItem {
                text: qsTr("View Preferences")
                onClicked: {
                    pullDownMenu._filterBlocked = true;
                    pageStack.push(Qt.resolvedUrl("SortingPage.qml"), { "dir": dir })
                }
            }
            MenuItem {
                text: qsTr("Create Folder")
                onClicked: {
                    pullDownMenu._filterBlocked = true;
                    var dialog = pageStack.push(Qt.resolvedUrl("CreateFolderDialog.qml"),
                                          { path: page.dir })
                    dialog.accepted.connect(function() {
                        if (dialog.errorMessage !== "")
                            notificationPanel.showText(dialog.errorMessage, "")
                    })
                }
            }
            MenuItem {
                visible: engine.clipboardCount > 0
                text: qsTr("Paste") +
                      (engine.clipboardCount > 0 ? " ("+engine.clipboardCount+")" : "")
                onClicked: {
                    if (remorsePopupActive) return;
                    Files.pasteFiles(page.dir, progressPanel, clearSelectedFiles);
                }
            }

            Item {
                height: Theme.itemSizeMedium
                width: parent.width

                TextField {
                    id: filterField
                    width: parent.width-2*clearFilterButton.width
                    height: Theme.itemSizeMedium
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: qsTr("Filter directory contents")
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter

                    background: null
                    onTextChanged: page.currentFilter = text;
                    onActiveFocusChanged: {
                        if (pullDownMenu._filterBlocked) {
                            pullDownMenu._filterBlocked = !activeFocus
                        }
                    }

                    EnterKey.enabled: true
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: {
                        if (page.quickSearchEnabled) {
                            pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                           { dir: page.dir, searchText: filterField.text,
                                               startImmediately: true });
                        } else {
                            pullDownMenu.close();
                        }
                    }
                    Component.onCompleted: {
                        page.clearViewFilter.connect(function() { text = ""; })
                    }
                }

                IconButton {
                    id: clearFilterButton
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        leftMargin: Theme.horizontalPageMargin
                        top: filterField.top
                    }
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    icon.source: "image://theme/icon-m-clear"
                    enabled: filterField.enabled
                    opacity: filterField.text.length > 0 ? 1 : 0
                    Behavior on opacity { FadeAnimation {} }

                    onClicked: {
                        filterField.text = "";
                        pullDownMenu.close();
                    }
                }

                IconButton {
                    id: searchFilterButton
                    anchors {
                        left: parent.left
                        rightMargin: Theme.horizontalPageMargin
                        leftMargin: Theme.horizontalPageMargin
                        top: filterField.top
                    }
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    icon.source: "../images/icon-btn-search.png"
                    enabled: filterField.enabled
                    highlighted: down || page.quickSearchEnabled
                    opacity: filterField.text.length > 0 ? 1 : 0
                    Behavior on opacity { FadeAnimation {} }

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                            { dir: page.dir, searchText: filterField.text,
                              startImmediately: true });
                    }
                }
            }
        }

        PushUpMenu {
            id: bottomPulley
            busy: pullDownMenu.busy
            property bool _toggleBookmark: false
            onActiveChanged: { // delay action until menu is closed
                if (!active && _toggleBookmark) toggleBookmark()
                else _toggleBookmark = false
            }
            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                          { dir: page.dir })
            }
            MenuItem {
                id: bookmarkEntry
                property bool hasBookmark: Bookmarks.hasBookmark(dir)
                text: hasBookmark ? qsTr("Remove bookmark") : qsTr("Add to bookmarks")
                onClicked: bottomPulley._toggleBookmark = true
            }
            MenuItem {
                text: qsTr("Copy path to clipboard")
                onClicked: Clipboard.text = page.dir
            }
        }

        header: PageHeader {
            id: header
            title: Paths.formatPathForTitle(page.dir)
            description: page.fullPathShown ? Paths.dirName(page.dir) : ""
            Component.onCompleted: dirPopup.menuTop = y+height

            leftMargin: (navMenuIconShown ? menuIcon.width + Theme.paddingMedium : 0)
                        + Theme.horizontalPageMargin
            _titleItem.elide: Text.ElideMiddle

            IconButton {
                id: menuIcon
                visible: navMenuIconShown
                anchors {
                    left: parent.left; leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
                opacity: Theme.opacityHigh
                icon.source: "image://theme/icon-m-menu"
                highlighted: true
            }

            BackgroundItem {
                anchors.fill: parent
                onClicked: dirPopup.show()
                onPressAndHold: dirPopup.show()
            }
        }

        footer: Column {
            x: 0; width: page.width
            height: footerSpacer.height +
                    (footerLabel.visible ? topSpacer.height + footerLabel.height : 0)
            Spacer {
                id: topSpacer
                visible: footerLabel.visible
                height: Theme.paddingLarge
            }

            Row {
                id: footerLabel
                visible: page.currentFilter !== ""
                spacing: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                layoutDirection: Qt.RightToLeft
                IconButton {
                    id: clearButton
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.iconSizeMedium
                    onClicked: page.clearViewFilter()
                    icon.source: "image://theme/icon-m-clear"
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: page.width-(2*Theme.horizontalPageMargin+parent.spacing+clearButton.width)
                    color: Theme.highlightColor
                    text: qsTr("filtered by: %1").arg(currentFilter)
                    // use elide instead of fade because it must be truncated on the right
                    truncationMode: TruncationMode.Elide
                    elide: "ElideRight"
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Spacer { id: footerSpacer }
        }

        delegate: Component {
            DirectoryPageEntry {}
        }

        // text if no files or error message
        ViewPlaceholder {
            id: statusMessage
            enabled: !busyIndicator.enabled &&
                     _activeDir !== "" &&
                     (fileModel.fileCount === 0 || fileModel.errorMessage !== "")
            text: fileModel.errorMessage !== "" ? fileModel.errorMessage : qsTr("Empty")
            hintText: fileModel.errorMessage !== "" ? "" : qsTr("This directory contains no files.")
        }

        PageBusyIndicator {
            id: busyIndicator
            enabled: fileModel.busy
            running: enabled
        }
    }

    DirectoryPopup {
        id: dirPopup
        directory: _activeDir
        flickable: fileList
    }

    Connections {
        id: quickSelectionConnections
        property int startIndex: -1
        target: null
        onSelectionChanged: {
            target = null;
            multiSelectionFinished(startIndex);
            fileModel.selectRange(startIndex, index);
            startIndex = -1;
        }
    }

    onMultiSelectionStarted: {
        quickSelectionConnections.startIndex = index;
        quickSelectionConnections.target = page;
    }

    function toggleSelection(index, notify) {
        fileModel.toggleSelectedFile(index);
        selectionPanel.open = (fileModel.selectedFileCount > 0);
        selectionPanel.overrideText = "";
        if (notify === false) return;
        selectionChanged(index);
    }

    function clearSelectedFiles() {
        fileModel.clearSelectedFiles();
        selectionPanel.overrideText = "";
    }
    function selectAllFiles() {
        fileModel.selectAllFiles();
        selectionPanel.overrideText = "";
    }

    SelectionPanel {
        id: selectionPanel
        selectedCount: fileModel.selectedFileCount
        enabled: !page.remorsePopupActive && !page.remorseItemActive
        displayClose: fileModel.selectedFileCount == fileModel.filteredFileCount
        selectedFiles: function() { return fileModel.selectedFiles(); }

        Connections {
            target: selectionPanel.actions
            onCloseTriggered: clearSelectedFiles()
            onSelectAllTriggered: selectAllFiles()
            onCutTriggered: clearSelectedFiles()
            onCopyTriggered: clearSelectedFiles()
            onDeleteTriggered: {
                var files = fileModel.selectedFiles();
                remorsePopupActive = true;
                remorsePopup.execute(qsTr("Deleting"), function() {
                    fileModel.markSelectedAsDoomed();
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
        onStatusChanged: {
            if (status === Loader.Ready) {
                item.overlayShown.connect(function() { fileList.visible = false; });
                item.overlayHidden.connect(function() { fileList.visible = true; });
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
                if (message === "Unknown error")
                    filename = qsTr("Trying to move between phone and SD Card? It does not work, try copying.");
                else if (message === "Failure to write block")
                    filename = qsTr("Perhaps the storage is full?");

                notificationPanel.showText(message, filename);
            }
        }
    }

    Connections {
        target: settings
        onViewSettingsChanged: {
            if (localPath !== "" && localPath !== dir) return;
            updateThumbnailsState();
        }
        onSettingsChanged: {
            if (key === 'General/FilenameElideMode') {
                page._fnElide = settings.read("General/FilenameElideMode", "fade");
            } else if (key === 'General/DefaultFilterAction') {
                page.quickSearchEnabled = (settings.read("General/DefaultFilterAction", "filter") === "search");
            } else if (key === 'General/ShowFullDirectoryPaths') {
                page.fullPathShown = (settings.read("General/ShowFullDirectoryPaths", "false") === "true");
            } else if (key === 'General/ShowNavigationMenuIcon') {
                page.navMenuIconShown = (settings.read("General/ShowNavigationMenuIcon", "true") === "true")
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!canNavigateForward) {
                pageStack.completeAnimation();
                pageStack.pushAttached(Qt.resolvedUrl("ShortcutsPage.qml"), { currentPath: dir });
            }
            coverText = Paths.lastPartOfPath(page.dir.replace(/\/$/, ''))+"/"; // update cover
        } else if (status === PageStatus.Activating && _activeDir !== dir) {
            console.log("loading", dir);
            _activeDir = dir;
            main.activePage = {type: "dir", path: dir};
            navigate_syncNavStack();
        }
    }

    function updateThumbnailsState() {
        var showThumbs = settings.read("View/PreviewsShown", "false");
        var galleryActive = settings.read("View/EnableGalleryMode", "false");

        if (settings.read("View/UseLocalSettings", "true") === "true") {
            showThumbs = settings.read("Dolphin/PreviewsShown", showThumbs, dir+"/.directory");
            galleryActive = settings.read("Sailfish/EnableGalleryMode", galleryActive, dir+"/.directory");
        }

        if (galleryActive === "true") {
            viewState = "gallery";
        } else if (showThumbs === "true") {
            viewState = "preview/" + settings.read("View/PreviewsSize", "medium");
        } else {
            viewState = "";
        }
    }

    function toggleBookmark() {
        if (hasBookmark) {
            Bookmarks.removeBookmark(dir);
            hasBookmark = false;
        } else {
            Bookmarks.addBookmark(dir);
            hasBookmark = true;
        }
    }

    Component.onCompleted: {
        main.bookmarkAdded.connect(function(path) { if (path === dir) bookmarkEntry.hasBookmark = true; });
        main.bookmarkRemoved.connect(function(path) { if (path === dir) bookmarkEntry.hasBookmark = false; });
    }
}
