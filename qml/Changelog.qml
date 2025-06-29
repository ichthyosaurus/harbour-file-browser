/*
 * This file is part of harbour-file-browser.
 * SPDX-FileCopyrightText: Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.0
import "modules/Opal/About"

ChangelogList {
    ChangelogItem {
        version: "3.8.0"
        date: "2025-06-29"
        paragraphs: [
            "- Updated translations: Estonian, Slovak, Swedish, Ukrainian<br>" +
            "- Added an info popup that shows on startup when the app is running in Sailjail<br>" +
            "-   - when running in Sailjail, File Browser doesn't have full access to all files and folders which is confusing for users<br>" +
            "-   - it's recommended to install the app from OpenRepos where Sailjail is disabled<br>" +
            "- Fixed visual glitches when editing bookmarks<br>" +
            "- Updated Opal modules, fixing some visual glitches and adding translations"
        ]
    }
    ChangelogItem {
        version: "3.7.0"
        date: "2025-06-11"
        paragraphs: [
            "- Added translations: Arabic<br>" +
            "- Updated translations: Chinese, Estonian, Finnish, French, Polish, Portuguese (Brazil), Russian, Spanish, Swedish, Turkish, Ukrainian<br>" +
            "- Fixed missing bookmarks file causing issues at startup<br>" +
            "- Fixed a warning when starting the app and the file clipboard is empty<br>" +
            "- Added support for automatically updating config files<br>" +
            "- Added more invalid \"external devices\" to the ignore list<br>" +
            "- Added an \"open new window\" button to the app cover"
        ]
    }
    ChangelogItem {
        version: "3.6.0"
        date: "2025-02-18"
        paragraphs: [
            "- Added translations: Portuguese (Brazil), Tamil<br>" +
            "- Updated translations: Estonian, Finnish, French, German, Italian, Portuguese (Brazil), Russian, Serbian, Slovak, Spanish, Swedish, Tamil, Turkish, Ukrainian<br>" +
            "- Added support for analyzing disk space usage using “Space Inspector” (only enabled if “Space Inspector” is installed)<br>" +
            "- Added support for play/pause using headphone buttons for audio previews<br>" +
            "- Added more unused paths to the mount point ignore list<br>" +
            "- Fixed file size info not being updated after editing a text file<br>" +
            "- Fixed issues with counting files and folders<br>" +
            "- Fixed bookmark warnings when no bookmarks file was found<br>" +
            "- Removed bookmark migration that was needed for the switch to Sailjail<br>" +
            "- Improved modularity to make it easier to use parts of File Browser in other apps (e.g. “Space Inspector” is built on top of File Browser's core)<br>" +
            "- Lots of internal cleanup and modernization"
        ]
    }
    ChangelogItem {
        version: "3.5.0"
        date: "2024-10-30"
        paragraphs: [
            "- Updated translations: Belarusian, Estonian, Spanish, Swedish, Ukrainian<br>" +
            "- Added option to create a new folder when manually entering a path (e.g. when selecting a transfer target)<br>" +
            "- Fixed the issue where attached pages (shortcuts, settings) would suddenly become blank<br>" +
            "- Fixed an issue where the file selection could be lost by accidentally opening a context menu<br>" +
            "- Fixed moving directories across partitions, e.g. from the internal memory to a SD card<br>" +
            "- Fixed an issue where it was impossible to add the same manual path twice when transferring files, without restarting the app<br>" +
            "- Fixed copied/moved files getting new timestamps instead of preserving original timestamps<br>" +
            "- Fixed moving files to multiple targets at once<br>" +
            "- Fixed system files (special files and broken links) not being counted in the folder size<br>" +
            "- Fixed some instances where broken symlinks were ignored instead of being treated as files<br>" +
            "- Fixed error message when moving a symlink fails<br>" +
            "- Fixed a handful of bugs that could break copying and moving<br>" +
            "- Updated Opal.MediaPlayer, now with subtitle support<br>" +
            "- Updated all Opal modules, bringing new translations and bug fixes under the hood"
        ]
    }
    ChangelogItem {
        version: "3.4.0"
        date: "2024-10-21"
        paragraphs: [
            "- Updated translations: Estonian, Slovak, Spanish, Swedish, Ukrainian, German, English<br>" +
            "- Important change: files are now sorted by modification date instead of file age<br>" +
            "-   - This change is necessary to align File Browser's behavior with KDE Dolphin's behavior, so that you see the same sort order when opening a mounted folder on your desktop and when opening it on your phone<br>" +
            "-   - If you were using local view settings, you now have to switch sort order in folders where you defined it<br>" +
            "-   - Sorting by file age meant that more recently changed files were at the top, sorting by file data means that they are at the bottom now when sorting in ascending order<br>" +
            "-   - The old and more mobile-friendly behavior is now emulated by automatically switching sort order when switching sort role<br>" +
            "- Added a new setting in \"App Settings -> View and Behavior -> Initial view\" to choose which view is shown when the app is started (folder, places, or search)<br>" +
            "- Added partition size info in the context menu of device shortcuts<br>" +
            "- Fixed video preview starting to play when the file details page is entered, instead of when the preview page is actually shown<br>" +
            "- Fixed synchronising settings between the global settings page and the view settings page<br>" +
            "- Fixed managing files larger than 2 GiB on 32bit devices<br>" +
            "-   - Their status, size, and date are now correctly shown in the folder view<br>" +
            "-   - They can be put in the clipboard, copied, and moved now<br>" +
            "- Fixed a bunch of styling issues on the new Opal.MediaPlayer video preview page<br>" +
            "- Fixed styling of gallery video play button in light ambiences<br>" +
            "- Fixed thumbnails for video files not appearing in gallery mode<br>" +
            "- Fixed starting search via the cover<br>" +
            "- Fixed immediately focussing the search field when opening the search page<br>" +
            "- Fixed some causes of the shortcuts page or settings page suddenly being blank but it still happens sometimes<br>" +
            "- Switched to Opal.SmartScrollbar for displaying the smart scrollbar in long folder views"
        ]
    }
    ChangelogItem {
        version: "3.3.1"
        date: "2024-10-19"
        paragraphs: [
            "- Updated translations: Slovak, Swedish<br>" +
            "- Fixed an issue where the video preview would not automatically play when opened from the gallery view<br>" +
            "- Fixed gallery video preview styling<br>" +
            "- Fixed video preview controls becoming invisible in light ambiences<br>" +
            "- Fixed thumbnails not showing for videos in the gallery view"
        ]
    }
    ChangelogItem {
        version: "3.3.0"
        date: "2024-10-18"
        paragraphs: [
            "- Updated translations: Estonian, French, Russian, Slovak, Spanish, Swedish, Ukrainian<br>" +
            "- Fixed missing translations so that all available translations are actually shippped!<br>" +
            "- Increased maximum file size when editing files using the built-in text editor from 200 KiB to 2 MiB<br>" +
            "- Replaced the old video preview page with a shiny new video preview player based<br>" +
            "-   - The new player supports seeking and play/pause via headset buttons<br>" +
            "-   - You can embed the new player in your own apps using the new Opal.MediaPlayer module<br>" +
            "-   - The video player is originally based on Leszek Lesner's video player for Sailfish<br>" +
            "- Fixed invalid copyright year on the about page<br>" +
            "- Fixed an annoying issue where the app would show only a blank page with a busy spinner when it was started in the background<br>" +
            "-   - This might also fix the issue where the shortcuts page sometimes stays blank<br>" +
            "-   - The fix is a workaround for a bug in Sailfish and might not work reliably<br>" +
            "-   - It does not yet fix the issue where the settings page is sometimes not immediately accessible from the shortcuts page<br>" +
            "- Fixed an issue that could cause heavy lag when navigating from a folder on an SD card to the internal memory"
        ]
    }
    ChangelogItem {
        version: "3.2.2"
        date: "2024-10-11"
        paragraphs: [
            "- Updated translations: English, Russian, Polish, and more<br>" +
            "- Fixed contribution links to Weblate (for contributing translations)<br>" +
            "- Fixed moving bookmarks so they cannot end up in invalid places<br>" +
            "- Implemented moving/ordering bookmarks via drag and drop using Opal.DragDrop<br>" +
            "- Updated list of translations contributors (now generated from Weblate)"
        ]
    }
    ChangelogItem {
        version: "3.2.1"
        date: "2024-08-21"
        paragraphs: [
            "- Fixed ignoring mount points below base paths using the new config file<br>" +
            "- Note: the generated config file is fine and no manual changes are necessary"
        ]
    }
    ChangelogItem {
        version: "3.2.0"
        date: "2024-08-21"
        paragraphs: [
            "- Updated translations: Italian, Slovak, Russian, Dutch<br>" +
            "- Added config file to configure ignored mount points<br>" +
            "-   - this makes it easy to hide system paths that show up as external devices<br>" +
            "-   - edit \"HOME/.config/harbour-file-browser/ignored-mounts.json\" to add custom paths<br>" +
            "-   - please report any missing paths so they can be added to the default list<br>" +
            "- Fixed compatibility with SailfishOS 3.x<br>" +
            "- Added more checks to detect broken bookmark config files"
        ]
    }
    ChangelogItem {
        version: "3.1.1"
        date: "2024-08-10"
        paragraphs: [
            "- Updated translations: Spanish, Finnish, English, Estonian, Ukrainian, Slovak, Norwegian Bokmål, Swedish, German, Hungarian, Chinese"
        ]
    }
    ChangelogItem {
        version: "3.1.0"
        date: "2024-07-26"
        paragraphs: [
            "- Updated translations: Spanish, German, Swedish, Ukrainian, Estonian<br>" +
            "- Added support for shortcuts to standard locations on different storage media, like pictures in the internal memory, the SD card, and Android memory<br>" +
            "- Added support for translated standard locations, e.g. Documents and \"Dokumente\"<br>" +
            "- Added support for configuring thumbnail size for each folder separately<br>" +
            "- Added automatic focus to the search field on the search page after clearing it<br>" +
            "- Added new global option to disable clipboard sharing between File Browser windows<br>" +
            "- Fixed opening the navigation menu by tapping anywhere on the page header of the folder view<br>" +
            "- Fixed creating completely empty files, e.g. to create \".nomedia\" files"
        ]
    }
    ChangelogItem {
        version: "3.0.2"
        date: "2024-06-29"
        paragraphs: [
            "- Updated translations: Spanish, Slovak<br>" +
            "- Fixed \"/opt\" showing up as external device"
        ]
    }
    ChangelogItem {
        version: "3.0.1"
        date: "2024-06-28"
        paragraphs: [
            "- Updated translations: Spanish, Estonian, Ukrainian<br>" +
            "- Fixed sharing on 64bit devices (feedback needed!)<br>" +
            "- Fixed large amounts of useless system-internal mount points showing up as external devices"
        ]
    }
    ChangelogItem {
        version: "3.0.0"
        date: "2024-06-25"
        paragraphs: [
            "- This update finally brings over two years worth of new and refined features, bug fixes, and translation updates!<br>" +
            "- This is a major update with significant improvements above and under the hood!<br>" +
            "- New translations: Ukrainian<br>" +
            "- Updated translations: Finnish, Norwegian, Spanish, Slovak, Swedish, Estonian, French, Russian, Chinese, German, English, Polish, Turkish<br>" +
            "- Removed translations: Swiss German (not available in Sailfish)<br>" +
            "- Removed Paypal donations link, please use Liberapay and avoid Paypal if at all possible<br>" +
            "- Added a smart scrollbar that lets you easily jump to specific files in the middle of long folder listings<br>" +
            "- Added donation info to the \"About\" page: it is now possible to buy me a cup of coffee :-) (swipe right-to-left multiple times until you reach the \"About\" page)<br>" +
            "- Added a call-for-support popup that shows up automatically when the app is used frequently<br>" +
            "- Added a new page showing currently copied/cut files (swipe right-to-left to the shortcuts page, then select \"Clipboard\")<br>" +
            "- Added quick access to overviews of all documents and multimedia files on the shortcuts page (this uses system components that sadly have terrible performance)<br>" +
            "- Added section headers when sorting by file type, which makes it easier to find files of a specific type<br>" +
            "- Added support for creating folders with subfolders and for creating empty files<br>" +
            "- Added support for changing a link's target path<br>" +
            "- Added a very basic text editor, e.g. for quickly editing config files in root mode<br>" +
            "- Added option to set a custom directory to be opened when the app starts<br>" +
            "- Added descriptions for all config options and improved documentation<br>" +
            "- Added option to show hidden files last in the file list<br>" +
            "- Added automatic refreshing of the folder view when file properties change, e.g. when the size changes while copying files<br>" +
            "- Added support for showing shortcuts for all kinds of mounted devices (previously, only folders in /run/media/USER were shown)<br>" +
            "- Added proper support for calculating disk and file sizes (no longer relies on external commands and finally works without causing the app to hang)<br>" +
            "- Added option to configure standard view mode globally<br>" +
            "-   - current options: list and gallery<br>" +
            "-   - planned: grid view<br>" +
            "- Added context menu option to switch to a link's target folder<br>" +
            "- Greatly improved performance when switching between folders, checking bookmarks, editing settings, or reading the \"About\" page<br>" +
            "- Greatly improved performance of the \"edit this path\" dialog<br>" +
            "- Improved directory filtering: hidden files will be shown when the filter string starts with a dot<br>" +
            "- Improved root mode:<br>" +
            "-   - it now requires entering your device lock code to access<br>" +
            "-   - note: unlocking is handled by the system, File Browser will never see your lock code<br>" +
            "- Improved feedback in case of errors or unexpected events<br>" +
            "- Improved bookmarks handling and removed no longer needed \"refresh\" pulley option on the shortcuts page<br>" +
            "- Improved manual sorting and renaming of bookmarks: press and hold, then drag and drop to sort them<br>" +
            "- Improved performance when previewing large image files<br>" +
            "- Fixed synchronization of bookmarks among multiple app windows<br>" +
            "- Fixed sorting directories by modification date and by size<br>" +
            "- Fixed root mode for Sailfish 4.3 and later<br>" +
            "- Fixed keyboard randomly opening and closing when selecting suggestions while editing a path<br>" +
            "- Fixed the path edit dialog misinterpreting empty files as directories<br>" +
            "- Fixed searching for hidden files when they are locally configured to be shown<br>" +
            "- Fixed an issue where trying to cut certain system files could possibly break the copying mechanism<br>" +
            "- Fixed showing search/shortcuts from cover<br>" +
            "- Fixed logging when config migration fails (for Sailjail)<br>" +
            "- Fixed PDF annotations not being saved (not thoroughly tested yet)<br>" +
            "- Fixed calculating folder sizes by not following symbolic links<br>" +
            "- Fixed enabling gallery mode in a folder when it was globally disabled<br>" +
            "- Fixed gallery mode hiding files unnecessarily<br>" +
            "- Fixed many visual glitches, fixed papercuts, added minor quality-of-life features, and added various new icons<br>" +
            "- Removed all dependencies on Busybox<br>" +
            "- Modernized the code base under the hood<br>" +
            "- and much, much more...<br>" +
            "- *** For developers:<br>" +
            "- FileModel now exposes file extensions<br>" +
            "- FileData now exposes directory sizes, link targets, and more file properties<br>" +
            "- Engine now exposes clipboard contents<br>" +
            "- Engine no longer exposes paths of external devices and Android data<br>" +
            "- Added a new settings handler which reduces complexity and should improve performance overall<br>" +
            "-   - import module \"harbour.file.browser.Settings\"<br>" +
            "-   - use singleton types \"GlobalSettings\" and \"RawSettings\" or instantiate \"DirectorySettings\"<br>" +
            "- Improved the build system to possibly enable more features in Jolla store<br>" +
            "- Refactored the root mode helper build process<br>" +
            "- and much, much more...<br>" +
            "- Note: I do not know of any other apps that use File Browser's current file handling code; if you do, please contact me if there are issues with updating"
        ]
    }
    ChangelogItem {
        version: '2.5.1'
        date: "2022-03-30"
        paragraphs: [
            '- Hotfix for OpenRepos: fixed disabling sandboxing (Sailjail)'
        ]
    }
    ChangelogItem {
        version: '2.5.0'
        date: "2022-03-30"
        paragraphs: [
            '- Important note:<br>' +
            '-   - the Jolla store version cannot show all files in Sailfish 4.3 and later<br>' +
            '-   - sharing, PDF viewing, and storage settings are disabled in Jolla store<br>' +
            '-   - please install the unrestricted build from OpenRepos if you need all features<br>' +
            '- New translations: Polish, Indonesian<br>' +
            '- Updated translations: English, German, Swedish, Norwegian Bokmål, Slovak, Estonian, Chinese (China), French, Finnish, Hungarian, Turkish, Spanish<br>' +
            '- Updated list of contributors<br>' +
            '- Added support for backups using MyBackup<br>' +
            '- Added new setting to show/hide solid window background<br>' +
            '- Added a proper "About" page<br>' +
            '- Improved image loading times and error messages<br>' +
            '- Improved discoverability of global vs. local settings<br>' +
            '- Improved error handling on image/video preview page<br>' +
            '- Improved app icon and action icons<br>' +
            '- Improved logging with info about restricted/enabled features<br>' +
            '- Improved opening files externally<br>' +
            '-   - installing RPM and APK files should be possible again<br>' +
            '-   - a possibly upcoming "open with" system feature will be available right away<br>' +
            '- Improved detection of optional features:<br>' +
            '-   - internal PDF viewer will be properly disabled if sailfish-office is not installed<br>' +
            '-   - sharing will be disabled if no supported sharing method can be found<br>' +
            '- Fixed sharing on Sailfish <= 3.4 and Sailfish >= 4.x<br>' +
            '- Fixed opening directories in non-Harbour builds<br>' +
            '- Fixed image rotation for JPEG files<br>' +
            '- Fixed zoom-by-double-tap for images with almost the same dimensions as the screen<br>' +
            '- Fixed "Open" instead of "Install" showing for APK files<br>' +
            '- Changed a settings key: "gallery" mode must be re-enabled once<br>' +
            '- Updated config file location for Sailjail compatibility'
        ]
    }
    ChangelogItem {
        version: '2.4.3'
        date: "2021-02-17"
        paragraphs: [
            '- New translations: Dutch (Belgium), Estonian<br>' +
            '- Updated translations: Slovak, Hungarian, Norwegian Bokmål, Chinese (China), Swedish, Spanish<br>' +
            '- Fixed double tap to zoom images of square and almost square dimensions<br>' +
            '- Fixed horizontal mode<br>' +
            '-   - File Browser can now be used in all orientations<br>' +
            '-   - Please file a bug report if startup fails and a note about "delaying initialization" appears in the log.<br>' +
            '-   - Part of the fix uses a workaround for a system bug and may break unexpectedly.<br>' +
            '- Improved image page animations'
        ]
    }
    ChangelogItem {
        version: '2.4.2'
        date: "2021-02-06"
        paragraphs: [
            '- New translations: Czech, Slovak, Hungarian<br>' +
            '- Added support for opening directories with xdg-open<br>' +
            '- Updated list of contributors'
        ]
    }
    ChangelogItem {
        version: '2.4.1'
        date: "2021-02-01"
        paragraphs: [
            '- Note: translations are now managed using Weblate (https://hosted.weblate.org/projects/harbour-file-browser/) - contributors welcome!<br>' +
            '- New translation: Norwegian Bokmål<br>' +
            '- Updated translations: Spanish, French, Swedish, Chinese, German, ...<br>' +
            '- Added item count to folders in listings<br>' +
            '- Added link target to files in listings<br>' +
            '- Changed file size display units to SI units (i.e. powers of 2, KiB=1024B instead of kB=1000B)<br>' +
            '- Improved performance of file size preview and selecting files<br>' +
            '- Fixed label colors in permissions dialog, rename dialog, transfer dialog, file preview page<br>' +
            '- Fixed hiding empty file info fields<br>' +
            '- Fixed creating numbered file names when pasting over existing files with “.” in their path'
        ]
    }
    ChangelogItem {
        version: '2.4.0'
        date: "2021-01-12"
        paragraphs: [
            '- Finally out of beta<br>' +
            '-   - Configuration is now stored at ~/.config/harbour-file-browser. Copy your beta configuration from ~/.config/harbour-file-browser-beta to keep custom shortcuts.<br>' +
            '-   - You can safely remove the folder ~/.local/share/harbour-file-browser-beta.<br>' +
            '-   - Updated root mode for non-beta release (packaged separately)<br>' +
            '-   - Note: it might be necessary to manually remove the old packages harbour-file-browser-beta and harbour-file-browser-root-beta<br>' +
            '- Updated translations: Swedish, Chinese, German<br>' +
            '- Greatly improved performance when loading folders and moving/deleting files<br>' +
            '-   - before: loading a folder with 5000 images (sorted by modification time) took ~5 seconds, moving/deleting 1 file took ~8 seconds; with times climbing exponentially<br>' +
            '-   - now: loading the same folder (any sorting mode) is nearly instantly, moving/deleting too<br>' +
            '-   - now: sorting mode will no longer noticeably affect performance (sorting by modification time was by far the slowest mode before)<br>' +
            '-   - note: when deleting/moving/filtering more than 200 files the view will lose its position and jump to the top<br>' +
            '- Greatly improved filtering performance<br>' +
            '-   - before: filtering a folder with 5000 images took ~20 seconds, scrolling was nearly impossible<br>' +
            '-   - now: the same folder filters nearly instantly, scrolling is smooth<br>' +
            '-   - note: the folder listing will be updated when closing the top menu<br>' +
            '- Improved navigation performance: switching between folders should feel much more responsive now<br>' +
            '- Fixed a bug causing page navigation by swiping to break<br>' +
            '- Fixed performance issues when opening view preferences<br>' +
            '- Fixed keyboard flickering when opening view preferences<br>' +
            '- Fixed selection panel being closed while one file was still selected<br>' +
            '- Fixed file pages breaking after file(s) have been moved away<br>' +
            '- Fixed folder listings jumping to the top after deleting or transferring files and after changing settings<br>' +
            '- Fixed highlighting files when the context menu is opened, a thumbnail is being shown, or gallery mode is activated<br>' +
            '- Added support for simple wildcards when filtering<br>' +
            '-   - use “*” to match any one or more characters<br>' +
            '-   - use “?” to match any single character<br>' +
            '-   - use “[abc]” to match one character of the group in square brackets<br>' +
            '-   - to include a literal “*” or “?” you have to enclose it in square brackets<br>' +
            '- Added proper user feedback while loading folders<br>' +
            '- Added indicators for files that are being moved/deleted<br>' +
            '- Added an informational placeholder when no file matched the filter<br>' +
            '- Improved suggestions highlighting when manually editing the current path<br>' +
            '- Improved system integration: "open storage settings" menu item will only be shown if storage module is installed<br>' +
            '- Improved navigation menu: duplicate history entries should not happen anymore<br>' +
            '- Improved licensing: the project is now “reuse”-compliant (cf. https://reuse.software/spec/)<br>' +
            '- *** For developers:<br>' +
            '- Added and improved some documentation<br>' +
            '- Added a new worker thread class for loading, refreshing, and sorting folders in the background<br>' +
            '- Added modification time info from stat(3) to StatFileInfo<br>' +
            "- Implemented custom sorting by modification time, as QDir's performance is terrible<br>" +
            '- Implemented a hashing/caching algorithm for partially refreshing folder listings<br>' +
            '- Improved icon rendering: code can be easily reused in other projects<br>' +
            '- Clarified licensing for all files: documentation is GFDL, some files are CC0 (all files have proper SPDX license headers now)'
        ]
    }
    ChangelogItem {
        version: '2.3.2-beta'
        date: "2021-01-07"
        paragraphs: [
            '- Fixed deleting files via context menu<br>' +
            '- Fixed clearing selection while filtering<br>' +
            '- Added a menu icon to directory headers (can be disabled in the settings)<br>' +
            '- Improved description text for adding custom transfer targets<br>' +
            '- Refactored page navigation and navigation history (even good things can be improved)<br>' +
            '- Fixed some console noise'
        ]
    }
    ChangelogItem {
        version: '2.3.1-beta'
        date: "2020-12-04"
        paragraphs: [
            '- Updated translations: Swedish, Chinese<br>' +
            '- Changed file info icon to the default system icon<br>' +
            '- Changed toolbar icons to 112x112px instead of 64x64px<br>' +
            '- Fixed height and thickness of toolbar icons (lines) to match system icons<br>' +
            "- Fixed file previews so file icons don't scale too much<br>" +
            '- Fixed an error message caused by string formatting'
        ]
    }
    ChangelogItem {
        version: '2.3.0-beta'
        date: "2020-11-22"
        paragraphs: [
            '- Updated translations: Spanish, Swedish, Chinese, German, English (thanks to contributors!)<br>' +
            '- Implemented navigation history: use the directory popup to navigate back and forward (see below)<br>' +
            '- Added support for adding shortcuts to a manually entered path (bottom pulley on the shortcuts page)<br>' +
            '- Added support for adding custom transfer targets by path (top pulley in the transfer dialog)<br>' +
            '- Added a new directory popup (similar to the old one from version <= 1.8.0)<br>' +
            '-   - open it by tapping on the page title in a directory listing<br>' +
            '-   - navigation history: go back, forward, and up ("up" is the same as swiping left)<br>' +
            '-   - quickly toggle viewing hidden files<br>' +
            '-   - edit the current path (or e.g. paste a path from clipboard)<br>' +
            '- Added setting on how to abbreviate/elide filenames<br>' +
            '- Added preview for SQLite databases<br>' +
            '- Improved performance on many pages (directory listings, search, shortcuts, navigation, ...)<br>' +
            '- Fixed a large amount of visual bugs, inconsistencies, and papercuts<br>' +
            '- Fixed many small bugs concerning edge cases in nagivation, settings, etc.<br>' +
            '- Fixed accidentally opening the keyboard when switching to the sort/view settings<br>' +
            '- Allowed rotating all pages (it is still not working perfectly, but this might be a bug in the system)<br>' +
            '- Fixed handling selections: selections will be cleared less often, e.g. helping with sorting files<br>' +
            '- Fixed filtering files case-insensitively<br>' +
            '- Fixed keeping search results without restarting the search after checking a file<br>' +
            '- Implemented rudimentary video error handling (when previewing files)<br>' +
            '- Improved error handling in file previews (rpm, sqlite, zip, ...)<br>' +
            '- Improved file type detection and file icons<br>' +
            '- Improved support for thumbnails (e.g. PDF and video files can have thumbnails now)<br>' +
            '- Added and improved documentation<br>' +
            '- Clarified licenses: GPL v3 (or later) for code, CC-BY-SA 4.0 for graphics<br>' +
            '- Prepared for first non-beta release in Jolla store<br>' +
            '- *** For developers:<br>' +
            '- Restructured the development environment<br>' +
            '- Implemented a new versatile dialog for manually entering paths, including completion suggestions<br>' +
            '- Implemented different search types in the search engine<br>' +
            '- Added support for limiting the amount of search results<br>' +
            '- Added directory info properties to the file data backend'
        ]
    }
    ChangelogItem {
        version: '2.2.2-beta'
        date: "2020-05-29"
        paragraphs: [
            '- Fixed saving settings when the settings file did not exist<br>' +
            '- Fixed showing disk space under SFOS 3.3.x.x<br>' +
            '- Fixed rare possibility of duplicate bookmark entries<br>' +
            '- Fixed bookmarks vanishing when the user renames the configuration folder while the app is running<br>' +
            '- Fixed calculating size info and counting files for links or directories containing links<br>' +
            '- Fixed copying hidden files when copying a directory recursively<br>' +
            '- Improved user notice when a link is broken<br>' +
            '- Improved directory/link state detection (might help with a bug regarding CIFS mounts)<br>' +
            '- *** For developers:<br>' +
            '- Internal API changes<br>' +
            '-   - Documented Engine::isUsingBusybox()<br>' +
            '-   - Added Settings::keys()'
        ]
    }
    ChangelogItem {
        version: '2.2.1-beta'
        date: "2020-05-02"
        paragraphs: [
            '- Added root mode (packaged separately)<br>' +
            '- Fixed inconsistent default setting for "View/UseLocalSettings"<br>' +
            '- Added "open storage settings" to bottom pulley of shortcuts page<br>' +
            '- Disabled opening system settings from shortcuts for Jolla store and when running as root'
        ]
    }
    ChangelogItem {
        version: '2.2.0-beta'
        date: "2020-05-01"
        paragraphs: [
            '- Fixed showing file info page under SailfishOS 3.3.x.x<br>' +
            '- Fixed the same for symlinks to directories on another partition<br>' +
            '- Increased performance when changing directories<br>' +
            '- Shortcut to Android data will be hidden if the directory is not available<br>' +
            '- *** For developers:<br>' +
            '- Internal API changes<br>' +
            '-   - Removed some small helper functions<br>' +
            '-   - Refactored and split scripts and libraries<br>' +
            '-   - Removed Engine::homeFolder()<br>' +
            '-   - Renamed Engine::androidSdcardPath() to Engine::androidDataPath()'
        ]
    }
    ChangelogItem {
        version: '2.1.1-beta'
        date: "2020-04-19"
        paragraphs: [
            '- Added support for opus audio files: recognize them as audio, and allow internal playback<br>' +
            '- Removed trying to show thumbnails for PDF files and videos: the system thumbnailer does not support it'
        ]
    }
    ChangelogItem {
        version: '2.1.0-beta'
        date: "2020-01-12"
        paragraphs: [
            '- Added file icons for compressed files and for PDF files<br>' +
            '- Implemented a new "Gallery Mode": images will be shown comfortably large, and all entries except for images, videos, and directories will be hidden<br>' +
            '- Implemented previewing videos directly<br>' +
            '-   - Note that this is intentionally kept simple. Use an external app for anything other than quickly checking what the file contains.<br>' +
            '-   - Thumbnail images for videos are not available as they are not supported by the system thumbnailer.<br>' +
            '- Added support for USB OTG devices<br>' +
            '-   - Any device mounted below /run/media/nemo will now be shown together with the SD card<br>' +
            '-   - Added a bottom pulley to the shortcuts page to manually refresh the list of devices<br>' +
            '-   - External storage settings can now directly be accessed via the context menu (see below)<br>' +
            '- Improved usability of bookmarks and shortcuts<br>' +
            '-   - Implemented manually sorting bookmarks<br>' +
            '-   - Fixed wrong icon for deleting bookmarks<br>' +
            '-   - Fixed bookmarks when transferring files<br>' +
            '-   - Moved shortcut to Android storage to the main "Locations" section<br>' +
            '- Improved settings handling to be more robust<br>' +
            '-   - Please note that all *customized* bookmark names will be reset *once* after installing this update<br>' +
            '-   - Fixed a bug where bookmark names (not the bookmarks themselves) could get lost<br>' +
            '-   - Added runtime-caching of settings to handle missing permissions<br>' +
            '-   - Fixed changing view settings in read-only directories<br>' +
            '-   - Restricted saving local view settings to the current user\'s user directory and their run-media directory, so even if File Browser is run as root, no unwanted files will be written anywhere<br>' +
            '-   - Improved settings handling to be more intuitive when resetting a local value to the global default<br>' +
            '- not Harbour-compliant changes:<br>' +
            '-   - Added showing PDF files directly from the file page (swipe right) using Sailfish Office<br>' +
            '-   - Added context menu to external devices (bookmark page) to directly open system settings<br>' +
            '- Fixed a typo on the sorting options page<br>' +
            '- Added option to copy current path to clipboard to the main bottom pulley<br>' +
            '- Fixed showing path in pulley when adding a bookmark via shortcuts page<br>' +
            '- Performance improvements in<br>' +
            '-   - loading directories<br>' +
            '-   - switching between thumbnail modes<br>' +
            '-   - previewing large images<br>' +
            '- *** For developers:<br>' +
            '- Internal API changes<br>' +
            '-   - Moved settings from Engine to standalone settings handler<br>' +
            '-   - Replaced separate method for detecting SD cards by method collecting all mounted devices'
        ]
    }
    ChangelogItem {
        version: '2.0.1-beta'
        date: "2019-12-30"
        paragraphs: [
            '- Updated translations: Swedish, Chinese, Spanish<br>' +
            '- (other translations still need updating - contributors welcome!)'
        ]
    }
    ChangelogItem {
        version: '2.0.0-beta'
        date: "2019-12-12"
        paragraphs: [
            '- Performance improvements in<br>' +
            '-   - changing directories<br>' +
            '-   - loading directories<br>' +
            '-   - applying new settings<br>' +
            '- Implemented sharing files (non-Harbour version only)<br>' +
            '- Added file transfer option (quickly copy/move/link multiple files to multiple destinations)<br>' +
            '- Added shortcuts page instead of quick-links menu (swipe right)<br>' +
            '- Added bookmarks option (add from pulley or context menu, access on shortcuts page)<br>' +
            '- Show content preview of file immediately as attached page (swipe right)<br>' +
            '- Improved pulley menu order on file page<br>' +
            '- Moved some entries from pull down menu to push up menu on directory page<br>' +
            '- Added more sorting options for directory listings<br>' +
            '- Added setting to sort case-sensitively or case-insensitively<br>' +
            '- Simplified applying directory settings (top pulley or tap on directory title)<br>' +
            '- Fixed calculating disk space usage<br>' +
            '- Improved file date/time info<br>' +
            '- Added setting to use local view settings for all directories (.directory files from desktop file managers)<br>' +
            '- Improved selection panel and context menu in directory listings<br>' +
            '- Added file actions (copy/rename/share/... to file page)<br>' +
            '- Added quick-filter option to directory listings (open top pulley to maximum)<br>' +
            '- Improved rename dialog<br>' +
            '-   - disabled text prediction<br>' +
            '-   - added support for renaming multiple files at once<br>' +
            '-   - added check if file already exists<br>' +
            '- Improved horizontal app layout<br>' +
            '- Implemented file preview thumbnails<br>' +
            '- Added image viewer page (swipe right from file page)<br>' +
            '- Added "shift" selection of multiple files (long press on file entry to start)<br>' +
            '- Added cover actions (“search” and “show shortcuts”)<br>' +
            '- Added support for selecting text file preview (just like in the Notes app)<br>' +
            '- Implemented computing size of all selected file/directories (with properties page)<br>' +
            '- Implemented computing directory size (visible from properties page)<br>' +
            '- Implemented opening new windows<br>' +
            '- Improved launcher entry<br>' +
            '- Improved support for light ambiences<br>' +
            '- Improved and added some custom icons<br>' +
            '- Added support for animations in image viewer (e.g. GIF files)<br>' +
            '- Added list of contributors (swipe right from settings page)<br>' +
            '- Added support for initial directory as command line argument<br>' +
            '- Added settings page as attached page to shortcuts page (swipe right)<br>' +
            '- Added root mode app icon and highlight cover when running as root<br>' +
            '- Re-built app icon as SVG and generated new png images<br>' +
            '- Improved many strings (translations not updated yet)<br>' +
            '- Updated German translation<br>' +
            '- Polished user interface with improvements here and there<br>' +
            '- **IMPORTANT**: for version 2.0.0 and upwards, the licensing has been changed to the GNU GPL v3 (or later).'
        ]
    }
    ChangelogItem {
        version: '1.8.0'
        date: "2019-05-12"
        paragraphs: [
            '- Added a confirmation dialog for file overwriting<br>' +
            '- Fixed colors and icons for Sailfish 3 light ambiences'
        ]
    }
    ChangelogItem {
        version: '1.7.3'
        date: "2018-07-05"
        paragraphs: [
            '- Fixed the SDCard location for users with an unusual sdcard symlink'
        ]
    }
    ChangelogItem {
        version: '1.7.2'
        date: "2018-06-11"
        paragraphs: [
            '- Fixed SDCard location for Sailfish 2.2.0<br>' +
            '- Fixed to start on Sailfish 1 phones'
        ]
    }
    ChangelogItem {
        version: '1.7.1'
        date: "2018-02-11"
        paragraphs: [
            '- Added translations for French, Dutch and Greek<br>' +
            '- Fixed icons for high density screens'
        ]
    }
    ChangelogItem {
        version: '1.7'
        date: "2016-06-27"
        paragraphs: [
            '- Add translations for Italian, Russian, Spanish and Swedish<br>' +
            '- Small UI improvements to match the Sailfish look'
        ]
    }
    ChangelogItem {
        version: '1.6'
        date: "2015-03-22"
        paragraphs: [
            '- Add translations for Finnish, German and Simplified Chinese languages<br>' +
            '- Fix occasional search page hangup'
        ]
    }
    ChangelogItem {
        version: '1.5'
        date: "2014-09-01"
        paragraphs: [
            '- Multiple file selections<br>' +
            '- View contents of tar files<br>' +
            '- Display image size, exif and other metadata<br>' +
            '- Displays broken symbolic links<br>' +
            '- Move and copy symbolic links<br>' +
            '- Display mime type information<br>' +
            '- Display chr, blk, fifo and sock files correctly'
        ]
    }
    ChangelogItem {
        version: '1.4.2'
        date: "2014-03-20"
        paragraphs: [
            '- Added full public domain license text<br>' +
            '- Fixed path to sd card<br>' +
            '- Fixed deleting symlinks to directories<br>' +
            '- Added view contents to show rpm, apk and zip files'
        ]
    }
    ChangelogItem {
        version: '1.4.1'
        date: "2014-01-26"
        paragraphs: [
            '- Added Settings page<br>' +
            '- Added show hidden files<br>' +
            '- Added show directories first<br>' +
            '- Added rename files and folders<br>' +
            '- Added create folders<br>' +
            '- Added change permissions<br>' +
            '- Added disk space indicators<br>' +
            '- Fixed two deletes to work simultaneously'
        ]
    }
    ChangelogItem {
        version: '1.3'
        date: "2013-12-29"
        paragraphs: [
            '- Added filename search<br>' +
            '- Added audio playback<br>' +
            '- Added image preview<br>' +
            '- Added view contents to show text or binary dump'
        ]
    }
    ChangelogItem {
        version: '1.2'
        date: "2013-12-23"
        paragraphs: [
            '- Added menu to open files with xdg-open<br>' +
            '- Added context menu to cut, copy and paste (move/copy) files<br>' +
            '- Cancel file operations<br>' +
            '- Watches file system for changes to update the views'
        ]
    }
    ChangelogItem {
        version: '1.1'
        date: "2013-12-19"
        paragraphs: [
            '- Android APK and Sailfish RPM packages can be installed<br>' +
            '- Context menu to delete files and directories'
        ]
    }
    ChangelogItem {
        version: '1.0'
        date: "2013-12-17"
        paragraphs: [
            '- Initial release'
        ]
    }
}
