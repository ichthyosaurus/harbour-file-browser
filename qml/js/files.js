/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020 Mirian Margiani
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

// functions for handling files
// (no library because variables from the environment are needed)

.import harbour.file.browser.FileClipboard 1.0 as Clip

function _getPanelText() {
    if (Clip.FileClipboard.mode == Clip.FileClipMode.Copy) {
        return qsTr("Copying")
    } else if (Clip.FileClipboard.mode == Clip.FileClipMode.Cut) {
        return qsTr("Moving")
    } else if (Clip.FileClipboard.mode == Clip.FileClipMode.Link) {
        return qsTr("Linking")
    } else {
        console.log("error: unknown file clip mode:", Clip.FileClipboard.mode)
        return qsTr("Unknown")
    }
}

function pasteFiles(targetDir, progressPanel, runBefore) {
    Clip.FileClipboard.validate();

    if (Clip.FileClipboard.count === 0) return;
    if (targetDir === undefined) return;

    var existingFiles = Clip.FileClipboard.listExistingFiles(targetDir, true, true);

    if (existingFiles.length > 0) {
        // show overwrite dialog
        var dialog = pageStack.push(Qt.resolvedUrl("../pages/OverwriteDialog.qml"),
                                    { "files": existingFiles })

        dialog.accepted.connect(function() {
            if (progressPanel !== undefined) {
                progressPanel.showText(_getPanelText())
            }

            if (runBefore !== undefined) runBefore();
            engine.pasteFiles(Clip.FileClipboard.paths, targetDir, Clip.FileClipboard.mode);
        })
    } else {
        // no overwrite dialog
        if (progressPanel !== undefined) {
            progressPanel.showText(_getPanelText())
        }

        if (runBefore !== undefined) runBefore();
        engine.pasteFiles(Clip.FileClipboard.paths, targetDir, Clip.FileClipboard.mode);
    }
}
