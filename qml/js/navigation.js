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
// -- query: search query (only used for type 'search')
//
// TODO: include SearchPage in history

function _pushToStack(stack, page) {
    if (stack && page && page.path && (
                stack.length === 0 ||
                stack[stack.length-1].path.replace(/\/+/g, '/')
                    !== page.path.replace(/\/+/g, '/'))) {
        stack.push(JSON.parse(JSON.stringify(page)));
    }
}

function syncNavStack() {
    if (currentPage.type !== activePage.type ||
            currentPage.path !== activePage.path) {
        _pushToStack(backStack, currentPage);
        currentPage = JSON.parse(JSON.stringify(activePage));
        forwardStack = []; // clear the forward stack because we just started a new branch
    }
}

function goBack() {
    if (!canGoBack()) return;
    var go = backStack.pop();
    _pushToStack(forwardStack, currentPage);
     _debugStacks("goBack")
    _executeHistory(go);
}

function goForward() {
    if (!canGoForward()) return;
    var go = forwardStack.pop();
    _pushToStack(backStack, currentPage);
     _debugStacks("goForward")
    _executeHistory(go);
}

function canGoForward() {
     _debugStacks("canGoForward")
    return forwardStack.length > 0
}
function canGoBack() {
     _debugStacks("canGoBack")
    return backStack.length > 0
}

function _executeHistory(go) {
    currentPage = JSON.parse(JSON.stringify(go));
    if (go.type === "dir") {
        goToFolder(go.path, true) // silent
    } else if (go.type === "search") {
        goToFolder(go.path, true, go.query) // silent, immediately start search
    } else {
        console.error("invalid history type:", go.type)
    }
}

function _debugStacks(hint) {
    console.log("[stacks:", hint+"]", JSON.stringify(backStack),
                "||", JSON.stringify(currentPage),
                "||", JSON.stringify(forwardStack))
}

function _sharedStart(array) {
    var A=array.concat().sort(), a1=A[0].split("/"), a2=A[A.length-1].split("/"), L=a1.length, i=0;
    while(i<L && a1[i]===a2[i]) i++;
    var shared = a1.slice(0, i).join("/");
    shared = shared.replace(/\/+/g, '/');
    shared = shared.replace(/\/$/, '');
    if (shared === '') shared = '/' // at least / is always shared
    return shared;
}

function goToFolder(folder, silent, startSearchQuery) {
    console.log("switching to:", folder)
    var pagePath = Qt.resolvedUrl("../pages/DirectoryPage.qml");
    var shared = "", rest = "", basePath = "", sourceDir = "", above = null;
    folder = folder.replace(/\/+/g, '/')
    folder = folder.replace(/\/$/, '')
    if (folder === '') folder = '/'

    if (pageStack.currentPage.objectName === "directoryPage") {
        console.log("- starting at directory")
        sourceDir = pageStack.currentPage.dir;
    } else {
        var prevPage = pageStack.previousPage();
        while (prevPage && prevPage.objectName !== "directoryPage") {
            // search for the top-most directory page
            prevPage = pageStack.previousPage(prevPage);
        }

        if (prevPage !== null) {
            console.log("- found previous page")
            sourceDir = prevPage.dir
        }
    }

    if (sourceDir === folder) {
        console.log("- already at target")
        shared = sourceDir
    } else {
        shared = _sharedStart([folder, sourceDir]);
    }

    if (!silent && sourceDir !== "") {
        _pushToStack(backStack, currentPage);
        syncNavStack()
        currentPage = {type: "dir", path: folder}
        forwardStack = []; // clear the forward stack because we just started a new branch
        console.log("go STACKS:", JSON.stringify(backStack), "||", JSON.stringify(currentPage), "||", JSON.stringify(forwardStack))
    }

    console.log("- searching...")
    var existingTarget = null;
    existingTarget = pageStack.find(function(page) {
        if (page.objectName === "directoryPage" &&
                page.dir === shared) return true;
        return false;
    })

    if (existingTarget === null) {
        above = null
        rest = folder
        basePath = ""
        console.log("- no shared tree")
    } else {
        console.log("- shared tree found")
        if (shared === folder && startSearchQuery === undefined) {
            pageStack.pop(existingTarget, PageStackAction.Animated);
            console.log("- finished (quick)")
            return
        } else {
            above = existingTarget;
            rest = "/"+folder.slice(shared.length)
            basePath = shared;
            console.log("- determined shared tree: ", basePath, rest);
        }
    }

    // make sure rest contains only single slashes and doesn't
    // start or end with one
    rest = rest.replace(/\/+/g, '/').replace(/^\//, '').replace(/\/$/, '')
    var toPush = []
    var dirs = rest.split("/");

    if (basePath === "") toPush.push({page: pagePath, properties: {dir: "/"}});
    for (var j = 0; j < dirs.length-1; ++j) {
        basePath += "/"+dirs[j];
        toPush.push({page: pagePath, properties: {dir: basePath}});
    }
    toPush.push({page: pagePath, properties: {dir: folder}});

    if (startSearchQuery !== undefined) {
        toPush.push({page: Qt.resolvedUrl("../pages/SearchPage.qml"),
                        properties: {
                            dir: folder,
                            searchText: startSearchQuery,
                            startImmediately: true
                        }})
    }

    if (above !== pageStack.currentPage) {
        console.log("- inserting "+toPush.length+" page(s)")
        pageStack.animatorReplaceAbove(above, toPush);
    } else {
        console.log("- pushing "+toPush.length+" page(s)")
        pageStack.animatorPush(toPush);
    }

    console.log("- done")

    // 2020-05-01: use the commented-out code if pageStack does not support
    // pushing arrays for some reason. This feature might have been added with
    // a recent update. It is supported since at least 3.2.1.20.
    /*var dirs = rest.split("/");
    for (var j = 1; j < dirs.length-1; ++j) {
        basePath += "/"+dirs[j];
        pageStack.animatorPush(pagePath, { dir: basePath }, PageStackAction.Immediate);
    }
    pageStack.animatorPush(pagePath, { dir: folder }, PageStackAction.Animated);*/
}
