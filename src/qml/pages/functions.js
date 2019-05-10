
// Go to root using the optional operationType parameter
// @param operationType PageStackAction.Immediate or Animated, Animated is default)
function goToRoot(operationType) {
    if (operationType !== PageStackAction.Immediate) operationType = PageStackAction.Animated;
    pageStack.clear();
    pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"), { dir: "/" }, operationType);
}

function goToShortcuts(operationType) {
    if (operationType !== PageStackAction.Immediate) operationType = PageStackAction.Animated;
    pageStack.clear();
    pageStack.push(Qt.resolvedUrl("ShortcutsPage.qml"), {}, operationType);
    return;
}

// returns true if string s1 starts with string s2
function startsWith(s1, s2)
{
    if (!s1 || !s2)
        return false;

    var start = s1.substring(0, s2.length);
    return start === s2;
}

// trims a string from left and right
function trim(s)
{
    return s.replace(/^\s+|\s+$/g, "");
}

function sharedStart(array){
    var A=array.concat().sort(), a1=A[0].split("/"), a2=A[A.length-1].split("/"), L=a1.length, i=0;
    while(i<L && a1[i]===a2[i]) i++;
    return a1.slice(0, i).join("/");
}

function goToFolder(folder) {
    var pagePath = Qt.resolvedUrl("DirectoryPage.qml");
    var prevPage = pageStack.previousPage();
    var cur = "", shared = "", rest = "";

    if (prevPage !== null) {
        cur = prevPage.dir
        shared = sharedStart([folder, cur]);
    }

    if (shared === folder) {
        var existingTarget = pageStack.find(function(page) {
            if (page.dir === folder) return true;
            return false;
        })
        if (!existingTarget) {
            goToRoot();
        } else {
            pageStack.pop(existingTarget, PageStackAction.Animated);
        }

        return;
    } else if (shared === "/" || shared === "") {
        goToRoot();
        rest = folder
    } else if (shared !== "") {
        var existingBase = pageStack.find(function(page) {
            if (page.dir === shared) return true;
            return false;
        })
        pageStack.pop(existingBase, PageStackAction.Immediate);
        rest = folder.replace(shared+"/", "");
    }

    var dirs = rest.split("/");
    var path = "";
    for (var j = 1; j < dirs.length-1; ++j) {
        path += "/"+dirs[j];
        pageStack.push(pagePath, { dir: path }, PageStackAction.Immediate);
    }
    pageStack.push(pagePath, { dir: folder }, PageStackAction.Animated);
}

// Goes to Home folder
function goToHome()
{
    goToFolder(engine.homeFolder());
}

function formatPathForTitle(path)
{
    if (path === "/")
        return "File Browser: /";

    var i = path.lastIndexOf("/");
    if (i < -1)
        return path;

    return path.substring(i+1)+"/";
}

// returns the text after the last / in a path
function lastPartOfPath(path)
{
    if (path === "/")
        return "";

    var i = path.lastIndexOf("/");
    if (i < -1)
        return path;

    return path.substring(i+1);
}

function formatPathForSearch(path)
{
    if (path === "/")
        return "root";

    var i = path.lastIndexOf("/");
    if (i < -1)
        return path;

    return path.substring(i+1);
}

function unicodeArrow()
{
    return "\u2192"; // unicode for right pointing arrow symbol (for links)
}
