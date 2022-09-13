/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2020-2022 Mirian Margiani
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

// functions for handling bookmarks
// (no library because variables from the environment are needed)

.import "paths.js" as Paths
.import harbour.file.browser.Settings 1.0 as Settings

function _defaultFor(arg, val) {
    return typeof arg !== 'undefined' ? arg : val;
}

function addBookmark(path, name) {
    if (!path) return;
    path = path.replace(/\/+/g, '/');
    path = path.replace(/\/$/, '');
    name = _defaultFor(name, Paths.lastPartOfPath(path))
    Settings.RawSettings.write("Bookmarks/"+path, name);

    var bookmarks = getBookmarks();
    bookmarks.push(path);
    Settings.RawSettings.write("Bookmarks/Entries", JSON.stringify(bookmarks));
    main.bookmarkAdded(path);
}

function removeBookmark(path) {
    if (!path) return;
    var bookmarks = getBookmarks();
    var filteredBookmarks = bookmarks.filter(function(e) { return e !== path; });
    Settings.RawSettings.write("Bookmarks/Entries", JSON.stringify(filteredBookmarks));
    Settings.RawSettings.remove("Bookmarks/"+path);
    main.bookmarkRemoved(path);
}

function moveBookmark(path) {
    if (!path) return;
    var bookmarks = getBookmarks();
    var oldIndex = undefined;

    for (var i = 0; i < bookmarks.length; i++) {
        if (bookmarks[i] === path) {
            oldIndex = i;
            break;
        }
    }

    var newIndex = oldIndex === 0 ? bookmarks.length-1 : oldIndex-1;
    bookmarks.splice(newIndex, 0, bookmarks.splice(oldIndex, 1)[0]);
    Settings.RawSettings.write("Bookmarks/Entries", JSON.stringify(bookmarks));
    main.bookmarkMoved(path);
}

function hasBookmark(path) {
    if (!path) return false;
    if (Settings.RawSettings.read("Bookmarks/"+path) !== "") return true;
    return false;
}

function getBookmarks() {
    try {
        var entries = JSON.parse(Settings.RawSettings.read("Bookmarks/Entries"));
        // remove duplicates
        entries = entries.filter(function(value, index, self){ return self.indexOf(value) === index; });
        return entries;
    } catch (SyntaxError) {
        // The ordering field seems to be empty. It is possible that it was lost because
        // the user moved the settings folder while the app was running. There is no way
        // to restore it, but at least we can make sure all entries are still shown.
        var keys = Settings.RawSettings.keys("Bookmarks").filter(function(e) { return e !== 'Entries'; });
        Settings.RawSettings.write("Bookmarks/Entries", JSON.stringify(keys));
        return keys;
    }
}

function getBookmarkName(path) {
    if (path === "") return "";
    var name = Settings.RawSettings.read("Bookmarks/"+path);

    if (name === "") {
        console.warn("empty bookmark name for", path, "- reset to default value");
        removeBookmark(path);
        addBookmark(path);
    }

    return name;
}
