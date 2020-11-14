// functions for handling files
// (no library because variables from the environment are needed)

function pasteFiles(targetDir, progressPanel, runBefore) {
    if (engine.clipboardCount === 0) return;
    if (targetDir === undefined) return;

    var existingFiles = engine.listExistingFiles(targetDir);
    if (existingFiles.length > 0) {
      // show overwrite dialog
      var dialog = pageStack.push(Qt.resolvedUrl("../pages/OverwriteDialog.qml"),
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
