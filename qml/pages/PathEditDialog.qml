/*
 * This file is part of File Browser.
 *
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
import harbour.file.browser.SearchEngine 1.0
import harbour.file.browser.FileData 1.0

import "../js/paths.js" as Paths

Dialog {
    id: dialog
    allowedOrientations: Orientation.All
    property string path
    property string acceptText

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

    canAccept: path !== "" && _isReady
    property bool _isReady: false
    property var _pathRegex: new RegExp('', 'i')
    property real _searchLeftMargin: Theme.itemSizeSmall+Theme.paddingMedium // = SearchField::textLeftMargin
    property string _fnElide: settings.read("General/FilenameElideMode", "fade")
    property int _nameTruncMode: _fnElide === 'fade' ? TruncationMode.Fade : TruncationMode.Elide
    property int _nameElideMode: _nameTruncMode === TruncationMode.Fade ?
                                    Text.ElideNone : (_fnElide === 'middle' ?
                                                          Text.ElideMiddle : Text.ElideRight)

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

            listModel.append({ fullname: fullname, filename: filename,
                                 absoluteDir: absoluteDir,
                                 fileIcon: fileIcon, fileKind: fileKind,
                                 isSelected: false, mimeType: mimeType,
                                 excluded: excluded
                             });
            console.log("match added:", filename);
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
                // placeholder entry: will be replaced by 'remove last part of path'
                listModel.append({ fullname: '(dummy)', filename: '/', absoluteDir: '/',
                                     fileIcon: '', fileKind: '', mimeType: '',
                                     excluded: false, isSelected: false
                                 });
                searchEngine.filterDirectories(text);
                console.log("dir filter started:", text);
            }
        }

        VerticalScrollDecorator { flickable: hintList }

        header: Item {
            width: parent.width
            height: head.height+Theme.itemSizeMedium+Theme.paddingSmall

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
                placeholderText: qsTr("Path to a folder")
                // label: canAccept ? qsTr("Path to a folder") :
                //                    qsTr("This path does not lead to a folder.")
                inputMethodHints: Qt.ImhNoPredictiveText |
                                  Qt.ImhUrlCharactersOnly

                EnterKey.enabled: pathField.text.length > 0
                EnterKey.iconSource: canAccept ? "image://theme/icon-m-enter-accept" :
                                                        "image://theme/icon-m-enter-close"
                EnterKey.onClicked: if (canAccept) accept()

                Component.onCompleted: {
                    forceActiveFocus() // grab focus when the page is openend
                    path = path.replace(/\/+/g, '/')
                    path = path.replace(/\/$/, '')+'/'
                    text = path // set initial text
                }

                onTextChanged: {
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

                    var search = Paths.lastPartOfPath(path).replace(/([.-[\](){}\\*?*^$|])/g, "\\$1")
                    dialog._pathRegex = new RegExp(search, 'i')
                    if (text === "" || !engine.pathIsDirectory(text)) {
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
                    }
                    onPathReplaced: {
                        path = newPath
                        pathField.text = newPath
                        pathField.forceActiveFocus()
                    }
                }
            }
        }

        delegate: Component {
            Loader {
                sourceComponent: Component {
                    ListItem {
                        id: listItem
                        width: dialog.width
                        // contentHeight: Theme.itemSizeMedium // two line delegate
                        contentHeight: Theme.itemSizeSmall // single line delegate
                        enabled: !excluded
                        onClicked: {
                            if (index > 0) {
                                dialog.suggestionSelected(filename)
                            } else {
                                var newPath = path;
                                newPath = newPath.replace(/\/$/, '')
                                newPath = '/'+Paths.dirName(newPath)
                                newPath = newPath.replace(/\/+/g, '/')
                                pathReplaced(newPath)
                            }
                        }

                        // we don't want this to be animated because the list changes to quickly
                        // ListView.onRemove: animateRemoval(listItem)
                        FileData { id: fileData }

                        Icon {
                            visible: index == 0
                            source: "image://theme/icon-m-backspace"
                            anchors {
                                right: upper.left; rightMargin: Theme.paddingMedium
                                verticalCenter: upper.verticalCenter
                            }
                        }

                        Label {
                            id: upper
                            anchors {
                                left: parent.left; leftMargin: _searchLeftMargin
                                right: parent.right; rightMargin: Theme.horizontalPageMargin
                                bottom: index > 0 ? parent.verticalCenter : parent.bottom
                                top: index > 0 ? undefined : parent.top
                            }
                            verticalAlignment: index > 0 ? Text.AlignBottom : Text.AlignVCenter
                            text: index > 0 ?
                                      Theme.highlightText(filename, dialog._pathRegex, Theme.highlightColor) :
                                      qsTr("Remove last part")
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
                            visible: index > 0
                            anchors {
                                left: parent.left; leftMargin: _searchLeftMargin
                                right: parent.right; rightMargin: Theme.horizontalPageMargin
                                top: parent.verticalCenter
                            }
                            property int files: fileData.filesCount
                            property int folders: fileData.dirsCount
                            text: (files > 0 ? qsTr("%n file(s)", "", files).arg(files) : "") + //: hidden if n=0
                                  (files > 0 && folders > 0 ? ", " : "") +
                                  (folders > 0 ? qsTr("%n folder(s)", "", folders).arg(folders) : "") //: hidden if n=0
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
