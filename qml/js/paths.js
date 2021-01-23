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

.pragma library // only load one instance of this script

// functions for handling paths

// returns the text after the last / in a path
function lastPartOfPath(path) {
    path = path.replace(/\/+/g, '/');
    if (path === "/") return "";
    var i = path.lastIndexOf("/");
    if (i < -1) return path;
    return path.substring(i+1);
}

function dirName(path) {
    path = path.replace(/\/+/g, '/');
    if (path === "/") return "";
    var i = path.lastIndexOf("/");
    if (i < -1) return path;
    return path.substring(0, i+1);
}

function formatPathForTitle(path) {
    if (path === "/") return "File Browser: /";
    path = path.replace(/\/$/, '');
    return lastPartOfPath(path)+'/';
}

function formatPathForSearch(path) {
    //: root directory (placeholder instead of "/" in search mask)
    if (path === "/") return qsTr("root");
    return lastPartOfPath(path);
}

function unicodeArrow() {
    return "\u2192"; // unicode symbol: right pointing arrow (for links)
}

function unicodeBrokenArrow() {
    return "\u219b"; // unicode symbol: right pointing arrow with stroke (for broken links)
}
