// functions for handling page navigation
// (no library because variables from the environment are needed)

function _goToRoot(animated) {
    pageStack.clear();
    pageStack.push(Qt.resolvedUrl("../pages/DirectoryPage.qml"), { dir: "/" }, animated === true ? PageStackAction.Animated : PageStackAction.Immediate);
}

function _sharedStart(array) {
    var A=array.concat().sort(), a1=A[0].split("/"), a2=A[A.length-1].split("/"), L=a1.length, i=0;
    while(i<L && a1[i]===a2[i]) i++;
    return a1.slice(0, i).join("/");
}

function goToFolder(folder) {
    var pagePath = Qt.resolvedUrl("../pages/DirectoryPage.qml");
    var prevPage = pageStack.previousPage();
    var cur = "", shared = "", rest = "", basePath = "";

    if (prevPage !== null) {
        cur = prevPage.dir
        shared = _sharedStart([folder, cur]);
    }

    if (shared === folder) {
        var existingTarget = pageStack.find(function(page) {
            if (page.dir === folder) return true;
            return false;
        })
        if (!existingTarget) {
            _goToRoot(true);
        } else {
            pageStack.pop(existingTarget, PageStackAction.Animated);
        }

        return;
    } else if (shared === "/" || shared === "") {
        _goToRoot(false);
        rest = folder
        basePath = ""
    } else if (shared !== "") {
        var existingBase = pageStack.find(function(page) {
            if (page.dir === shared) return true;
            return false;
        })
        pageStack.pop(existingBase, PageStackAction.Immediate);
        rest = folder.replace(shared+"/", "/");
        basePath = shared;
    }

    var dirs = rest.split("/");
    for (var j = 1; j < dirs.length-1; ++j) {
        basePath += "/"+dirs[j];
        pageStack.push(pagePath, { dir: basePath }, PageStackAction.Immediate);
    }
    pageStack.push(pagePath, { dir: folder }, PageStackAction.Animated);
}
