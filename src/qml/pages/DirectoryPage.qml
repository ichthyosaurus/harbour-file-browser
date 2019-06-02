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
    property alias hasBookmark: bookmarkEntry.hasBookmark
    property string currentFilter: ""

    signal viewFilterChanged(var filterString)
    signal clearViewFilter()
    signal multiSelectionStarted(var index)
    signal multiSelectionFinished(var index)
    signal selectionChanged(var index)

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
            id: pullDownMenu
            on_AtFinalPositionChanged: filterField.forceActiveFocus()
            onActiveChanged: filterField.focus = false

            MenuItem {
                text: qsTr("View Preferences")
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

            SearchField {
                id: filterField
                width: parent.width
                height: Theme.itemSizeSmall
                placeholderText: qsTr("Filter directory contents")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                font.pixelSize: Theme.fontSizeMedium
                onTextChanged: {
                    page.viewFilterChanged(text);
                    page.currentFilter = text;
                    if (text === "") pullDownMenu.close();
                }

                // return key on virtual keyboard starts or restarts search
                EnterKey.enabled: true
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                   { dir: page.dir, searchText: filterField.text });
                }
                Component.onCompleted: {
                    page.clearViewFilter.connect(function() { text = ""; })
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
                    toggleBookmark();
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

    Connections {
        id: quickSelectionConnections
        property var startIndex
        target: null
        onSelectionChanged: {
            quickSelectionConnections.target = null;
            multiSelectionFinished(startIndex);
            if (quickSelectionConnections.startIndex === undefined) return;
            if (quickSelectionConnections.startIndex > index) {
                for (var i = quickSelectionConnections.startIndex-1; i > index; i--) {
                    toggleSelection(i, false);
                }
            } else if (quickSelectionConnections.startIndex === index) {
                quickSelectionConnections.startIndex = undefined;
                return;
            } else {
                for (var j = quickSelectionConnections.startIndex+1; j < index; j++) {
                    toggleSelection(j, false);
                }
            }
            quickSelectionConnections.startIndex = undefined;
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

    function toggleBookmark() {
        if (hasBookmark) {
            Functions.removeBookmark(dir);
            hasBookmark = false;
        } else {
            Functions.addBookmark(dir);
            hasBookmark = true;
        }
    }

    Connections {
        target: main
        onBookmarkAdded: if (path === dir) bookmarkEntry.hasBookmark = true;
        onBookmarkRemoved: if (path === dir) bookmarkEntry.hasBookmark = false;
    }
}
