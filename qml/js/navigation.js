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
// (no library because variables from the environment are needed)

function _sharedStart(array) {
    var A=array.concat().sort(), a1=A[0].split("/"), a2=A[A.length-1].split("/"), L=a1.length, i=0;
    while(i<L && a1[i]===a2[i]) i++;
    return a1.slice(0, i).join("/");
}

function goToFolder(folder) {
    console.log("switching to:", folder)
    var pagePath = Qt.resolvedUrl("../pages/DirectoryPage.qml");
    var cur = "", shared = "", rest = "", basePath = "", above = null;

    var prevPage = pageStack.previousPage();
    while (prevPage && !prevPage.hasOwnProperty("dir")) {
        prevPage = pageStack.previousPage(prevPage);
    }

    if (prevPage !== null) {
        console.log("- found previous page")
        shared = _sharedStart([folder, cur]);
        cur = prevPage.dir
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
    pageStack.animatorReplaceAbove(above, toPush);
    console.log("- done")

    /*var dirs = rest.split("/");
    for (var j = 1; j < dirs.length-1; ++j) {
        basePath += "/"+dirs[j];
        pageStack.animatorPush(pagePath, { dir: basePath }, PageStackAction.Immediate);
    }
    pageStack.animatorPush(pagePath, { dir: folder }, PageStackAction.Animated);*/
}
