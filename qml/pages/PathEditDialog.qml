/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2023 Mirian Margiani
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
import harbour.file.browser.Settings 1.0
import harbour.file.browser.FileData 1.0

import "../js/paths.js" as Paths

Dialog {
    id: dialog
    allowedOrientations: Orientation.All
    property string path
    property string acceptText
    property bool pickFolder: true // set to false to allow selecting a file

    // set this to a function(var newPath) that is
    // called when the dialog is accepted
    property var acceptCallback
    onAccepted: if (acceptCallback) acceptCallback(path)

    // set this to a function(var path) that decides
    // whether or not to include 'path' as suggestion
    property var customFilter
    property bool hideExcluded: false // hide or deactivate excluded suggestions?

    signal suggestionSelected(var filename)
    signal pathReplaced(var newPath)
    signal forceSearchFieldFocus

    canAccept: path !== "" && _isReady
    property bool _isReady: false
    property string _firstSuggestion: ""
    property var _pathRegex: new RegExp('', 'i')
    property real _searchLeftMargin: Theme.itemSizeSmall+Theme.paddingMedium // = SearchField::textLeftMargin
    property string _fnElide: GlobalSettings.generalFilenameElideMode
    property int _nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    property int _nameElideMode: _nameTruncMode === TruncationMode.Fade ?
                                    Text.ElideNone : (_fnElide === 'middle' ?
                                                          Text.ElideMiddle : Text.ElideRight)

    function removeLastPartOfPath(path) {
        var newPath = path
        newPath = newPath.replace(/\/$/, '')
        newPath = '/' + Paths.dirName(newPath)
        newPath = newPath.replace(/\/+/g, '/')
        pathReplaced(newPath)
    }

    Timer {
        id: delayedFocusTimer
        interval: 100
        running: false

        // required to prevent the virtual keyboard from closing when
        // a suggestion is selected; heavy directories still take too
        // long to load and the keyboard closes
        onTriggered: forceSearchFieldFocus()
    }

    SearchEngine {
        id: searchEngine
        dir: ""
        maxResults: 20 // TODO is this expected behaviour?
        onDirChanged: console.log("new dir", dir)
        onMatchFound: {
            var excluded = false;
            if (customFilter && !customFilter(fullname)) {
                if (!hideExcluded) {
                    excluded = true;
                } else {
                    console.log("math excluded:", filename);
                    return;
                }
            }

            if (listModel.count == 0) {
                _firstSuggestion = filename
            }

            listModel.append({ fullname: fullname, filename: filename,
                                 absoluteDir: absoluteDir,
                                 fileIcon: fileIcon, fileKind: fileKind,
                                 isSelected: false, mimeType: mimeType,
                                 excluded: excluded
                             });
        }
        onWorkerErrorOccurred: {
            // TODO is there anything worth showing?
            console.warn("filter error:", message, filename)
        }
    }

    SilicaListView {
        id: hintList
        anchors.fill: parent
        footer: Item { width: 1; height: Theme.horizontalPageMargin }

        // prevent newly added list delegates from stealing focus away from the input field
        currentIndex: -1

        model: ListModel {
            id: listModel
            // updates the model by clearing all data and starting
            // searchEngine search() method asynchronously, using the
            // given text as the search query
            function update(text) {
                clear();
                _firstSuggestion = ""

                if (pickFolder) {
                    searchEngine.filterDirectories(text);
                } else {
                    searchEngine.filterEntries(text);
                }

                console.log("dir filter started (%1 files):".arg(
                                pickFolder ? "excluding" : "including"), text);
            }
        }

        PullDownMenu {
            flickable: hintList

            MenuItem {
                visible: path != "/"
                text: qsTr("Root")
                onDelayedClick: pathReplaced("/")
            }

            MenuItem {
                text: qsTr("Places")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("ShortcutsDialog.qml"))
                    dialog.accepted.connect(function() {
                        pathReplaced(dialog.selectedPath + "/")
                    })
                }
            }

            MenuItem {
                visible: path != "/"
                text: qsTr("Remove last part")
                onDelayedClick: removeLastPartOfPath(dialog.path)
            }
        }

        VerticalScrollDecorator { flickable: hintList }

        header: Item {
            width: parent.width
            height: head.height + Theme.itemSizeMedium + clearLastButton.contentHeight + Theme.paddingSmall

            DialogHeader {
                id: head
                acceptText: dialog.acceptText != "" ?
                                dialog.acceptText :
                                defaultAcceptText
            }

            SearchField {
                id: pathField
                anchors { top: head.bottom; topMargin: Theme.paddingSmall }
                width: parent.width
                placeholderText: pickFolder ?
                    qsTr("Path to a folder") :
                    qsTr("Path to a target")
                // label: canAccept ? qsTr("Path to a folder") :
                //                    qsTr("This path does not lead to a folder.")
                inputMethodHints: Qt.ImhNoPredictiveText |
                                  Qt.ImhUrlCharactersOnly

                EnterKey.enabled: pathField.text.length > 0
                EnterKey.iconSource: {
                    if (canAccept) "image://theme/icon-m-enter-accept"
                    else if (listModel.count == 1 && _firstSuggestion !== "") "image://theme/icon-m-enter-next"
                    else "image://theme/icon-m-enter-close"
                }
                EnterKey.onClicked: {
                    if (canAccept) accept()
                    else if (listModel.count == 1 && _firstSuggestion !== "") suggestionSelected(_firstSuggestion)
                    else pathField.focus = false // force focus away so the keyboard closes
                }

                Component.onCompleted: {
                    forceActiveFocus() // grab focus when the page is openend
                    path = path.replace(/\/+/g, '/')
                    path = path.replace(/\/$/, '')+'/'
                    text = path // set initial text
                }

                onTextChanged: {
                    if (text === "") {
                        text = "/"
                        return
                    }

                    path = text
                    var dir = Paths.dirName(path)
                    if (searchEngine.dir !== dir) {
                        searchEngine.dir = dir ? dir : "/"
                    }

                    if (path.match(/\/$/) != null) {
                        listModel.update("")
                    } else {
                        listModel.update(Paths.lastPartOfPath(path))
                    }

                    var search = Paths.lastPartOfPath(path).replace(/([-.[\](){}\\*?*^$|])/g, "\\$1")
                    dialog._pathRegex = new RegExp(search, 'i')
                    if (text === "" || (pickFolder && !engine.pathIsDirectory(text)) ||
                            (!pickFolder && !engine.pathIsFileOrDirectory(text))) {
                        // Theme.errorColor looks too harsh
                        color = Theme.secondaryHighlightColor
                        _isReady = false
                    } else {
                        color = Theme.primaryColor
                        _isReady = true
                    }
                }

                Connections {
                    target: dialog
                    onSuggestionSelected: {
                        var newPath = '/'+Paths.dirName(path)+filename+'/';
                        newPath = newPath.replace(/\/+/g, '/')
                        pathField.text = newPath
                        pathField.forceActiveFocus()
                        delayedFocusTimer.restart()
                    }
                    onPathReplaced: {
                        path = newPath
                        pathField.text = newPath
                        pathField.forceActiveFocus()
                        delayedFocusTimer.restart()
                    }
                    onForceSearchFieldFocus: {
                        pathField.forceActiveFocus()
                    }
                }
            }

            ListItem {
                id: clearLastButton
                anchors { top: pathField.bottom; topMargin: Theme.paddingSmall }
                width: parent.width
                contentHeight: Theme.itemSizeMedium * 0.9 // two line delegate

                enabled: path != "/"
                opacity: enabled ? 1.0 : Theme.opacityLow
                onClicked: removeLastPartOfPath(dialog.path)

                Icon {
                    source: "image://theme/icon-m-backspace"
                    anchors {
                        right: clearButtonLabel.left; rightMargin: Theme.paddingMedium
                        verticalCenter: clearButtonLabel.verticalCenter
                    }
                }

                Label {
                    id: clearButtonLabel
                    anchors {
                        bottom: parent.bottom
                        top: parent.top
                        left: parent.left; leftMargin: _searchLeftMargin
                        right: parent.right; rightMargin: Theme.horizontalPageMargin
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("Remove last part")
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        delegate: Component {
            Loader {
                height: Theme.itemSizeMedium * 0.9
                asynchronous: true

                sourceComponent: Component {
                    ListItem {
                        id: listItem
                        width: dialog.width
                        contentHeight: Theme.itemSizeMedium * 0.9 // two line delegate
                        enabled: !excluded
                        onClicked: dialog.suggestionSelected(filename)

                        // we don't want this to be animated because the list changes to quickly
                        // ListView.onRemove: animateRemoval(listItem)
                        FileData { id: fileData }

                        Label {
                            id: upper
                            anchors {
                                left: parent.left; leftMargin: _searchLeftMargin
                                right: parent.right; rightMargin: Theme.horizontalPageMargin
                                bottom: parent.verticalCenter
                            }
                            verticalAlignment: Text.AlignBottom
                            text: Theme.highlightText(filename, dialog._pathRegex, Theme.highlightColor)
                            truncationMode: _nameTruncMode
                            elide: _nameElideMode
                            textFormat: Text.StyledText
                            color: excluded ? Theme.secondaryColor :
                                              (upper.highlighted ? Theme.highlightColor :
                                                                   Theme.primaryColor)
                            opacity: excluded ? Theme.opacityLow : 1.0
                        }

                        Label {
                            id: infoLabel
                            anchors {
                                left: parent.left; leftMargin: _searchLeftMargin
                                right: parent.right; rightMargin: Theme.horizontalPageMargin
                                top: parent.verticalCenter
                            }
                            property int files: fileData.filesCount
                            property int folders: fileData.dirsCount
                            text: {
                                if (fileData.isDir) {
                                    if (files > 0 || folders > 0) {
                                        //: hidden if n=0
                                        return (files > 0 ? qsTr("%n file(s)", "", files) : "") +
                                            (files > 0 && folders > 0 ? ", " : "") +
                                            //: hidden if n=0
                                            (folders > 0 ? qsTr("%n folder(s)", "", folders) : "")
                                    } else {
                                        //: as in 'this folder is empty'
                                        return qsTr("empty")
                                    }
                                } else {
                                    return fileData.size
                                }
                            }
                            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            truncationMode: TruncationMode.Fade
                            opacity: excluded ? Theme.opacityLow : 1.0

                            Component.onCompleted: {
                                fileData.file = fullname
                                fileData.refresh()
                                files = fileData.filesCount
                                folders = fileData.dirsCount
                            }
                        }
                    }
                }
            }
        }
    }
}
