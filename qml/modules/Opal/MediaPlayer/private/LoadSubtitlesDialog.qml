import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Qt.labs.folderlistmodel 2.1

Dialog {
    id: root
    allowedOrientations: Orientation.All
    canAccept: !!selected.toString()

    // settings
    property string forFile: ''
    // fallback path is Downloads because that
    // should be accessible for most apps
    property string inFolder: StandardPaths.download
    property var nameFilters: ["*.srt"]

    property var preferredLocales: [
        Qt.locale().name.split('_')[0],
        Qt.locale().name,
        'en'
    ]

    // dialog result
    property url selected
    property int _selectedLocaleIndex: -1

    // internal
    readonly property string _forFileBase: !!forFile ?
        forFile.match(/\/(([^/]+?)\..*?)$/)[2] : ''
    readonly property string _forFileFull: !!forFile ?
        forFile.match(/\/(([^/]+?)\..*?)$/)[1] : ''

    function _updateInitialSelection(subtitleBaseName, subtitleUrl) {
        // formats matched:
        // video file: video.mp4 | base: video
        // srt files:
        // - video.srt
        // - video.locale.srt (e.g. video.en.srt)
        // - video.mp4.srt
        // - video.mp4.locale.srt

        var found = false
        var localeIndex = -1

        if (subtitleBaseName === forFile ||
                subtitleBaseName === _forFileBase ||
                subtitleBaseName === _forFileFull) {
            found = true
        }

        if (subtitleBaseName.indexOf('.') >= 0) {
            var locale = String(subtitleBaseName.slice(
                        subtitleBaseName.lastIndexOf('.')+1))
            localeIndex = preferredLocales.indexOf(locale)
            var noLocale = String(subtitleBaseName.split('.').slice(0, -1))

            // @disable-check M126
            if (noLocale == forFile ||
                    // @disable-check M126
                    noLocale == _forFileBase ||
                    // @disable-check M126
                    noLocale == _forFileFull) {
                found = true
            }
        }

        if (found) {
            if (!selected) {
                // nothing selected -> select this one
                found = true
            } else if (localeIndex >= 0) {
                // selected and we have a locale ->
                // verify if it is a closer match
                if (_selectedLocaleIndex < 0 ||
                        localeIndex < _selectedLocaleIndex) {
                    found = true
                } else {
                    found = false
                }
            } else {
                // selected and no locale on this one ->
                // keep the old selection
                found = false
            }
        }

        if (found) {
            selected = subtitleUrl
            _selectedLocaleIndex = localeIndex
        }
    }

    Component {
        id: pickerComponent

        FilePickerPage {
            nameFilters: root.nameFilters
            onSelectedContentPropertiesChanged: {
                root.selected = selectedContentProperties.url
            }
        }
    }

    SilicaListView {
        id: view
        anchors.fill: parent

        header: DialogHeader {}

        PullDownMenu {
            MenuItem {
                text: qsTranslate("Opal.MediaPlayer",
                                  "Select from file system")
                onClicked: {
                    pageStack.animatorPush(pickerComponent)
                }
            }
        }

        ViewPlaceholder {
            enabled: view.count === 0
            text: qsTranslate("Opal.MediaPlayer",
                "No files ready")
            hintText:
                qsTranslate("Opal.MediaPlayer",
                "Copy subtitle files in the SRT format " +
                "next to the video file to open them quickly.") +
                "\n\n" +
                qsTranslate("Opal.MediaPlayer",
                "Pull down to pick a file.")
        }

        model: FolderListModel {
            folder: root.inFolder
            nameFilters: root.nameFilters
            rootFolder: root.inFolder
            showDirs: false
            showDotAndDotDot: false
            showHidden: false
            showOnlyReadable: true
            sortField: FolderListModel.Name
            sortReversed: false
        }

        delegate: ListItem {
            id: item

            property url _url: fileURL
            property string _fileName: fileName

            // We don't use fileBaseName here because it strips away
            // everything after the first dot. We want to keep locale
            // info that is separated by a dot from the filename. Also,
            // video files often contain dots in their names.
            property string _baseName: fileName.indexOf('.') > 0 ?
                fileName.slice(0, fileName.lastIndexOf('.')) : fileName

            width: root.width
            contentHeight: Math.max(
                Theme.itemSizeSmall,
                label.height + 1*Theme.paddingMedium)
            onClicked: {
                root.selected = _url
            }

            Label {
                id: label
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                anchors.verticalCenter: parent.verticalCenter
                highlighted: item.highlighted || item.down ||
                    root.selected.toString() === item._url.toString()
                text: item._fileName
            }

            Component.onCompleted: {
                root._updateInitialSelection(item._baseName, item._url)
            }
        }
    }
}
