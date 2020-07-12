.pragma library // only load one instance of this script

// functions for handling paths

// returns the text after the last / in a path
function lastPartOfPath(path) {
    if (path === "/") return "";
    var i = path.lastIndexOf("/");
    if (i < -1) return path;
    return path.substring(i+1);
}

function dirName(path) {
    if (path === "/") return "";
    var i = path.lastIndexOf("/");
    if (i < -1) return path;
    return path.substring(0, i+1);
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
