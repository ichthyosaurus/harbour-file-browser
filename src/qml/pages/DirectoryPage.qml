import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string dir: "/"
    property bool initial: false // this is set to true if the page is initial page
    property bool remorsePopupActive: false // set to true when remorsePopup is active
    property bool remorseItemActive: false // set to true when remorseItem is active (item level)
    property bool thumbnailsShown: updateThumbnailsState()
    property int  fileIconSize: Theme.iconSizeSmall
    property alias progressPanel: progressPanel
    property alias notificationPanel: notificationPanel

    FileModel {
        id: fileModel
        dir: page.dir
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

        model: fileModel

        VerticalScrollDecorator { flickable: fileList }

        PullDownMenu {
            MenuItem {
                text: qsTr("Sort")
                onClicked: pageStack.push(Qt.resolvedUrl("SortingPage.qml"), { dir: dir })
            }
            MenuItem {
                text: qsTr("Create Folder")
                onClicked: {
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
                    Functions.pasteFiles(page.dir, progressPanel, clearSelectedFiles);
                }
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                          { dir: page.dir });
            }
            MenuItem {
                id: bookmarkEntry
                property bool hasBookmark: Functions.hasBookmark(dir)
                text: hasBookmark ? qsTr("Remove bookmark") : qsTr("Add to bookmarks")
                onClicked: {
                    clearSelectedFiles();
                    if (hasBookmark) {
                        removeBookmark(dir);
                        hasBookmark = false;
                    } else {
                        addBookmark(dir);
                        hasBookmark = true;
                    }
                }
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }

        header: PageHeader {
            title: Functions.formatPathForTitle(page.dir)
            _titleItem.elide: Text.ElideMiddle

            MouseArea {
                anchors.fill: parent
                onClicked: pageStack.push(Qt.resolvedUrl("SortingPage.qml"), { dir: dir });
            }
        }

        footer: Spacer { }

        delegate: Component {
            Loader {
                width: fileList.width
                source: "../components/DirectoryPageEntry.qml"
            }
        }

        // text if no files or error message
        ViewPlaceholder {
            enabled: fileModel.fileCount === 0 || fileModel.errorMessage !== ""
            text: fileModel.errorMessage !== "" ? fileModel.errorMessage : qsTr("No files")
        }
    }

    signal selectionChanged(var index)
    function toggleSelection(index, notify) {
        fileModel.toggleSelectedFile(index);
        selectionPanel.open = (fileModel.selectedFileCount > 0);
        selectionPanel.overrideText = "";
        if (notify === false) return;
        selectionChanged(index);
    }

    function clearSelectedFiles() {
        fileModel.clearSelectedFiles();
        selectionPanel.open = false;
        selectionPanel.overrideText = "";
    }
    function selectAllFiles() {
        fileModel.selectAllFiles();
        selectionPanel.open = true;
        selectionPanel.overrideText = "";
    }

    SelectionPanel {
        id: selectionPanel
        selectedCount: fileModel.selectedFileCount
        enabled: !page.remorsePopupActive && !page.remorseItemActive
        displayClose: fileModel.selectedFileCount == fileModel.fileCount
        selectedFiles: function() { return fileModel.selectedFiles(); }

        Connections {
            target: selectionPanel.actions
            onCloseTriggered: clearSelectedFiles();
            onSelectAllTriggered: selectAllFiles();
            onDeleteTriggered: {
                var files = fileModel.selectedFiles();
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
        onSettingsChanged: {
            updateThumbnailsState();
        }
    }

    // require page to be x milliseconds active before
    // pushing the attached page, so the page is not pushed
    // while navigating (= while building the back-tree)
    Timer {
        id:  preparationTimer
        interval: 15
        running: false
        repeat: false
        onTriggered: {
            if (status === PageStatus.Active) {
                if (!canNavigateForward) {
                    pageStack.pushAttached(Qt.resolvedUrl("ShortcutsPage.qml"), { currentPath: dir });
                }
                coverText = Functions.lastPartOfPath(page.dir)+"/"; // update cover
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            // clear file selections when the directory is changed
            clearSelectedFiles();
        }

        if (status === PageStatus.Active) {
            preparationTimer.start();
        }

        if (status === PageStatus.Activating && page.initial) {
            page.initial = false;
            Functions.goToFolder(StandardPaths.home);
        }
    }

    function updateThumbnailsState() {
        var showThumbs = engine.readSetting("View/PreviewsShown");
        if (engine.readSetting("View/UseLocalSettings", "false") === "true") {
            thumbnailsShown = engine.readSetting("Dolphin/PreviewsShown", showThumbs, dir+"/.directory") === "true";
        } else {
            thumbnailsShown = showThumbs === "true";
        }

        if (!main.thumbnailsEnabled) thumbnailsShown = false;

        if (thumbnailsShown) {
            var thumbSize = engine.readSetting("View/PreviewsSize", "medium");
            if (thumbSize === "small") {
                fileIconSize = Theme.itemSizeMedium
            } else if (thumbSize === "medium") {
                fileIconSize = Theme.itemSizeExtraLarge
            } else if (thumbSize === "large") {
                fileIconSize = page.width/3
            } else if (thumbSize === "huge") {
                fileIconSize = page.width/3*2
            }
        } else {
            fileIconSize = Theme.itemSizeSmall
        }
    }

    Connections {
        target: main
        onBookmarkAdded: if (path === dir) bookmarkEntry.hasBookmark = true;
        onBookmarkRemoved: if (path === dir) bookmarkEntry.hasBookmark = false;
    }

    signal addBookmark(var path)
    signal removeBookmark(var path)
    onAddBookmark: Functions.addBookmark(path)
    onRemoveBookmark: Functions.removeBookmark(path)
}
