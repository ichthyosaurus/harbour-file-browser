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

// functions for handling page navigation
// (not a library because variables from the environment are needed)

// Navigation history:
// A new entry is added when switching to a directory or starting a search.
// Other types of pages are not added to the history.
// The latest/current page is always on top of the backStack. When navigating
// back, the top page is moved to forwardStack and the second-to-last entry
// of backStack will be executed.
// When navigating forward, the top entry will be popped, executed,
// and moved to backStack.
//
// The stack objects are as follows:
// { type: string, path: string, properties: object }
// -- type: "search" or "dir"
// -- path: directory path
// -- properties: additional properties, only used for searches
//
// TODO: include SearchPage in history

function goBack() {
    if (!canGoBack()) return;
    if (backStack.length == 1) {
        // Situation: we popped a few pages from the page stack
        // and now we're in a directory that' not in the stacks.
        backStack.push({type: "dir", path: pageStack.currentPage.dir });
    }

    var go = backStack.pop();
    forwardStack.push(go);
    var actually = backStack[backStack.length-1];
    console.log("==>", JSON.stringify(actually), JSON.stringify(go))
    _executeHistory(actually);
}

function goForward() {
    if (!canGoForward()) return;
    var go = forwardStack.pop();
    backStack.push(go);
    _executeHistory(go);
}

function canGoForward() { return forwardStack.length >= 1; }
function canGoBack() {
    if (backStack.length >= 2) {
        return true;
    } else if (backStack.length == 1 &&
               pageStack.currentPage.hasOwnProperty("dir") &&
               pageStack.currentPage.dir !== backStack[0].path) {
        return true;
    }
    return false;
}

function _executeHistory(go) {
    if (go.type === "dir") {
        goToFolder(go.path, true) // silent
    } else if (go.type === "search") {
        goToFolder(go.path, true) // silent
        pageStack.push(Qt.resolvedUrl("../pages/SearchPage.qml"),
                       { dir: go.path }, PageStackAction.Immediate)
    } else {
        console.error("invalid history type:", go.type)
    }
}

function _sharedStart(array) {
    var A=array.concat().sort(), a1=A[0].split("/"), a2=A[A.length-1].split("/"), L=a1.length, i=0;
    while(i<L && a1[i]===a2[i]) i++;
    return a1.slice(0, i).join("/");
}

function goToFolder(folder, silent) {
    console.log("switching to:", folder)
    var pagePath = Qt.resolvedUrl("../pages/DirectoryPage.qml");
    var cur = "", shared = "", rest = "", basePath = "", sourceDir = "", above = null;

    var prevPage = pageStack.previousPage();
    while (prevPage && !prevPage.hasOwnProperty("dir")) {
        prevPage = pageStack.previousPage(prevPage);
    }

    if (prevPage !== null) {
        console.log("- found previous page")
        cur = prevPage.dir
        shared = _sharedStart([folder, cur]);
    }

    if (shared === folder) {
        var existingTarget = pageStack.find(function(page) {
            if (page.dir === folder) return true;
            return false;
        })
        if (!existingTarget) {
            // something weird happened
            // replace the complete stack with a new root page
            pageStack.animatorReplaceAbove(null, Qt.resolvedUrl("../pages/DirectoryPage.qml"), { dir: "/" }, PageStackAction.Animated);
        } else {
            pageStack.pop(existingTarget, PageStackAction.Animated);
        }
        console.log("- finished (quick)")

        return;
    } else if (shared === "/" || shared === "") {
        above = null;
        rest = folder
        basePath = ""
        console.log("- shared:", shared)
    } else if (shared !== "") {
        console.log("- searching...")
        var existingBase = pageStack.find(function(page) {
            if (page.dir === shared) return true;
            return false;
        })
        console.log("- found")
        above = existingBase;
        rest = folder.replace(shared+"/", "/");
        basePath = shared;
        console.log("- found ok")
    }

    // 2020-05-01: use the commented-out code if pageStack does not support
    // pushing arrays for some reason. This feature might have been added with
    // a recent update. It is supported since at least 3.2.1.20.
    console.log("- preparing...")
    var toPush = []
    var dirs = rest.split("/");

    if (basePath === "") toPush.push({page: pagePath, properties: {dir: "/"}});
    for (var j = 1; j < dirs.length-1; ++j) {
        basePath += "/"+dirs[j];
        toPush.push({page: pagePath, properties: {dir: basePath}});
    }
    toPush.push({page: pagePath, properties: {dir: folder}});

    console.log("- pushing...", JSON.stringify(toPush))
    if (!silent) {
        if (backStack.length > 0 && backStack[backStack.length-1].path !== sourceDir) {
            backStack.push({type: "dir", path: sourceDir});
        }
        backStack.push({type: "dir", path: folder});
        forwardStack = []; // clear the forward stack because we just started a new branch
    }

    var chunkSize = 3
    if (toPush.length >= chunkSize+2) {
        // What this tries to fix (but fails):
        // PageStack chokes when pushing too many pages at once. It
        // creates visual bugs where parts of earlier pages are still
        // visible. To work around this, we try pushing the pages in
        // chunks. pageStack.completeAnimation should make sure all
        // transitions are skipped - but it still fails with warnings
        // like 'Warning: cannot push while transition is in progress'...
        var first = toPush.shift();
        pageStack.replaceAbove(above, [first]);
        for (var index = 0; index < toPush.length; index += chunkSize) {
            var chunk = toPush.slice(index, Math.min(toPush.length, index+chunkSize));
            console.log("chunk:", index, toPush.length)
            pageStack.completeAnimation();
            pageStack.animatorPush(chunk);
        }
    } else {
        pageStack.animatorReplaceAbove(above, toPush);
    }

    console.log("- done")

    /*var dirs = rest.split("/");
    for (var j = 1; j < dirs.length-1; ++j) {
        basePath += "/"+dirs[j];
        pageStack.animatorPush(pagePath, { dir: basePath }, PageStackAction.Immediate);
    }
    pageStack.animatorPush(pagePath, { dir: folder }, PageStackAction.Animated);*/
}
