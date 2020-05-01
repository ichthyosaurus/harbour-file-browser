// functions for handling bookmarks
// (no library because variables from the environment are needed)

.import "paths.js" as Paths

function addBookmark(path) {
    if (!path) return;
    var bookmarks = getBookmarks();
    bookmarks.push(path);
    settings.write("Bookmarks/"+path, Paths.lastPartOfPath(path));
    settings.write("Bookmarks/Entries", JSON.stringify(bookmarks));
    main.bookmarkAdded(path);
}

function removeBookmark(path) {
    if (!path) return;
    var bookmarks = getBookmarks();
    var filteredBookmarks = bookmarks.filter(function(e) { return e !== path; });
    settings.write("Bookmarks/Entries", JSON.stringify(filteredBookmarks));
    settings.remove("Bookmarks/"+path);
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
    settings.write("Bookmarks/Entries", JSON.stringify(bookmarks));
    main.bookmarkMoved(path);
}

function hasBookmark(path) {
    if (!path) return false;
    if (settings.read("Bookmarks/"+path) !== "") return true;
    return false;
}

function getBookmarks() {
    try {
        var entries = JSON.parse(settings.read("Bookmarks/Entries"));
        return entries;
    } catch (SyntaxError) {
        settings.write("Bookmarks/Entries", JSON.stringify([]));
        return [];
    }
}
