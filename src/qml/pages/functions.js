
function goToRoot(animated) {
    pageStack.clear();
    pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"), { dir: "/" }, animated === true ? PageStackAction.Animated : PageStackAction.Immediate);
}

// trims a string from left and right
function trim(s) {
    return s.replace(/^\s+|\s+$/g, "");
}

function sharedStart(array) {
    var A=array.concat().sort(), a1=A[0].split("/"), a2=A[A.length-1].split("/"), L=a1.length, i=0;
    while(i<L && a1[i]===a2[i]) i++;
    return a1.slice(0, i).join("/");
}

function goToFolder(folder) {
    var pagePath = Qt.resolvedUrl("DirectoryPage.qml");
    var prevPage = pageStack.previousPage();
    var cur = "", shared = "", rest = "", basePath = "";

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
            goToRoot(true);
        } else {
            pageStack.pop(existingTarget, PageStackAction.Animated);
        }

        return;
    } else if (shared === "/" || shared === "") {
        goToRoot(false);
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

// bookmark handling
function addBookmark(path) {
    if (!path) return;
    var bookmarks = getBookmarks();
    bookmarks.push(path);
    engine.writeSetting("Bookmarks/"+path, lastPartOfPath(path));
    engine.writeSetting("Bookmarks/Entries", JSON.stringify(bookmarks));
    main.bookmarkAdded(path);
}

function removeBookmark(path) {
    if (!path) return;
    var bookmarks = getBookmarks();
    var filteredBookmarks = bookmarks.filter(function(e) { return e !== path; });
    engine.writeSetting("Bookmarks/Entries", JSON.stringify(filteredBookmarks));
    engine.removeSetting("Bookmarks/"+path);
    main.bookmarkRemoved(path);
}

function hasBookmark(path) {
    if (!path) return false;
    if (engine.readSetting("Bookmarks/"+path) !== "") return true;
    return false;
}

function getBookmarks() {
    try {
        var entries = JSON.parse(engine.readSetting("Bookmarks/Entries"));
        return entries;
    } catch (SyntaxError) {
        engine.writeSetting("Bookmarks/Entries", JSON.stringify([]));
        return [];
    }
}

// returns the text after the last / in a path
function lastPartOfPath(path) {
    if (path === "/") return "";
    var i = path.lastIndexOf("/");
    if (i < -1) return path;
    return path.substring(i+1);
}

function formatPathForTitle(path) {
    if (path === "/") return "File Browser: /";
    return lastPartOfPath(path)+"/";
}

function formatPathForSearch(path) {
    if (path === "/") return qsTr("root"); //: root directory (placeholder in search mask)
    return lastPartOfPath(path);
}

function unicodeArrow() {
    return "\u2192"; // unicode for right pointing arrow symbol (for links)
}

function pasteFiles(targetDir, progressPanel, runBefore) {
    if (engine.clipboardCount === 0) return;
    if (targetDir === undefined) return;

    var existingFiles = engine.listExistingFiles(targetDir);
    if (existingFiles.length > 0) {
      // show overwrite dialog
      var dialog = pageStack.push(Qt.resolvedUrl("OverwriteDialog.qml"),
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
