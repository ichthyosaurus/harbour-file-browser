
// Go to root using the optional operationType parameter
// @param operationType PageStackAction.Immediate or Animated, Animated is default)
function goToRoot(operationType) {
    if (operationType !== PageStackAction.Immediate) operationType = PageStackAction.Animated;
    main.lastPath = "/"
    pageStack.clear();
    pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"), { dir: "/" }, operationType);
}

function goToShortcuts(operationType) {
    if (operationType !== PageStackAction.Immediate) operationType = PageStackAction.Animated;
    pageStack.clear();
    pageStack.push(Qt.resolvedUrl("ShortcutsPage.qml"), { lastPath: main.lastPath }, operationType);
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

function goToFolder(folder)
{
//    // first, go to root so that the page stack has only one page
//    goToRoot(PageStackAction.Immediate);

//    // open the folders one by one
//    var dirs = folder.split("/");
//    var path = "";
//    for (var i = 1; i < dirs.length; ++i) {
//        path += "/"+dirs[i];
//        // animate the last push
//        var action = (i < dirs.length-1) ? PageStackAction.Immediate : PageStackAction.Animated;
//        pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"), { dir: path }, action);
//    }

    main.lastPath = folder;
    var dirs = folder.split("/");
    var path = "";
    var pagePath = Qt.resolvedUrl("DirectoryPage.qml");

    // open the folders one by one
    pageStack.clear();
    pageStack.push(pagePath, { dir: "/" }, PageStackAction.Immediate);
    for (var i = 1; i < dirs.length-1; ++i) {
        path += "/"+dirs[i];
        pageStack.push(pagePath, { dir: path }, PageStackAction.Immediate);
    }
    pageStack.push(pagePath, { dir: folder }, PageStackAction.Animated);


//    // prepare the folders one by one
//    var dirs = folder.split("/");
//    var path = "";
//    var pages = [{'page': Qt.resolvedUrl("DirectoryPage.qml"), 'properties': { dir: '/' }}];

//    for (var i = 1; i < dirs.length; ++i) {
//        if (i < dirs.length-1) {
//            path += "/"+dirs[i];
//            pages.push({'page': Qt.resolvedUrl("DirectoryPage.qml"), 'properties': { dir: path }});
//        }
//    }

//    main.lastPath = folder
//    pageStack.clear();
//    pageStack.push(pages, { dir: path + "/"+dirs[dirs.length-1] }, PageStackAction.Immediate);
//    pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"), { dir: path }, PageStackAction.Animated);


//    main.lastPath = folder
//    //pageStack.clear();
//    //pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"), { dir: folder }, PageStackAction.Animated);

//    // prepare the folders one by one
//    var dirs = folder.split("/");
//    var path = "";
//    var pages = [{'page': Qt.resolvedUrl("DirectoryPage.qml"), 'properties': { dir: '/' }}];

//    for (var i = 1; i < dirs.length; ++i) {
//        path += "/"+dirs[i];
//        pages.push({'page': Qt.resolvedUrl("DirectoryPage.qml"), 'properties': { dir: path }});
//    }

//    pageStack.clear();
//    pageStack.push(pages, { dir: path }, PageStackAction.Animated);
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

function unicodeBlackDownPointingTriangle()
{
    return "\u25be"; // unicode for down pointing triangle symbol (for top dir dropdown)
}
