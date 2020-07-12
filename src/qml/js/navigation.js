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
    var prevPage = pageStack.previousPage();
    var cur = "", shared = "", rest = "", basePath = "", above = null;

    if (prevPage !== null) {
        cur = prevPage.dir
        shared = _sharedStart([folder, cur]);
        console.log("- found previous page")
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
