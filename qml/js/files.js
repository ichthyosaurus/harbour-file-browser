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

function pasteFiles(targetDir, progressPanel, runBefore) {
    if (engine.clipboardCount === 0) return;
    if (targetDir === undefined) return;

    var existingFiles = engine.listExistingFiles(targetDir);
    if (existingFiles.length > 0) {
      // show overwrite dialog
      var dialog = pageStack.push(Qt.resolvedUrl("../pages/OverwriteDialog.qml"),
                                  { "files": existingFiles })
      dialog.accepted.connect(function() {
          if (progressPanel !== undefined) {
            progressPanel.showText(engine.clipboardContainsCopy ?
                                       qsTr("Copying") : qsTr("Moving"))
          }
          if (runBefore !== undefined) runBefore();
          engine.pasteFiles(targetDir);
      })
    } else {
      // no overwrite dialog
      if (progressPanel !== undefined) {
          progressPanel.showText(engine.clipboardContainsCopy ?
                                     qsTr("Copying") : qsTr("Moving"))
      }
      if (runBefore !== undefined) runBefore();
      engine.pasteFiles(targetDir);
    }
}
