/*
 * This file is part of harbour-file-browser.
 * SPDX-FileCopyrightText: Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.0
import "modules/Opal/About"

ChangelogList {
    ChangelogItem {
        version: '2.5.1'
        date: "2022-03-30"
        paragraphs: [
            '- Hotfix for OpenRepos: fixed disabling sandboxing (Sailjail)<br>' +
        '' ]
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
            '- Updated config file location for Sailjail compatibility<br>' +
        '' ]
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
            '- Improved image page animations<br>' +
        '' ]
    }
    ChangelogItem {
        version: '2.4.2'
        date: "2021-02-06"
        paragraphs: [
            '- New translations: Czech, Slovak, Hungarian<br>' +
            '- Added support for opening directories with xdg-open<br>' +
            '- Updated list of contributors<br>' +
        '' ]
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
            '- Fixed creating numbered file names when pasting over existing files with “.” in their path<br>' +
        '' ]
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
            '- Clarified licensing for all files: documentation is GFDL, some files are CC0 (all files have proper SPDX license headers now)<br>' +
        '' ]
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
            '- Fixed some console noise<br>' +
        '' ]
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
            '- Fixed an error message caused by string formatting<br>' +
        '' ]
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
            '- Added directory info properties to the file data backend<br>' +
        '' ]
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
            '-   - Added Settings::keys()<br>' +
        '' ]
    }
    ChangelogItem {
        version: '2.2.1-beta'
        date: "2020-05-02"
        paragraphs: [
            '- Added root mode (packaged separately)<br>' +
            '- Fixed inconsistent default setting for "View/UseLocalSettings"<br>' +
            '- Added "open storage settings" to bottom pulley of shortcuts page<br>' +
            '- Disabled opening system settings from shortcuts for Jolla store and when running as root<br>' +
        '' ]
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
            '-   - Renamed Engine::androidSdcardPath() to Engine::androidDataPath()<br>' +
        '' ]
    }
    ChangelogItem {
        version: '2.1.1-beta'
        date: "2020-04-19"
        paragraphs: [
            '- Added support for opus audio files: recognize them as audio, and allow internal playback<br>' +
            '- Removed trying to show thumbnails for PDF files and videos: the system thumbnailer does not support it<br>' +
        '' ]
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
            '-   - Restricted saving local view settings to /home/nemo/* and /run/media/nemo/*, so even if File Browser is run as root, no unwanted files will be written anywhere<br>' +
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
            '-   - Replaced separate method for detecting SD cards by method collecting all mounted devices<br>' +
        '' ]
    }
    ChangelogItem {
        version: '2.0.1-beta'
        date: "2019-12-30"
        paragraphs: [
            '- Updated translations: Swedish, Chinese, Spanish<br>' +
            '- (other translations still need updating - contributors welcome!)<br>' +
        '' ]
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
            '- **IMPORTANT**: for version 2.0.0 and upwards, the licensing has been changed to the GNU GPL v3 (or later).<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.8.0'
        date: "2019-05-12"
        paragraphs: [
            '- Added a confirmation dialog for file overwriting<br>' +
            '- Fixed colors and icons for Sailfish 3 light ambiences<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.7.3'
        date: "2018-07-05"
        paragraphs: [
            '- Fixed the SDCard location for users with an unusual sdcard symlink<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.7.2'
        date: "2018-06-11"
        paragraphs: [
            '- Fixed SDCard location for Sailfish 2.2.0<br>' +
            '- Fixed to start on Sailfish 1 phones<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.7.1'
        date: "2018-02-11"
        paragraphs: [
            '- Added translations for French, Dutch and Greek<br>' +
            '- Fixed icons for high density screens<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.7'
        date: "2016-06-27"
        paragraphs: [
            '- Add translations for Italian, Russian, Spanish and Swedish<br>' +
            '- Small UI improvements to match the Sailfish look<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.6'
        date: "2015-03-22"
        paragraphs: [
            '- Add translations for Finnish, German and Simplified Chinese languages<br>' +
            '- Fix occasional search page hangup<br>' +
        '' ]
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
            '- Display chr, blk, fifo and sock files correctly<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.4.2'
        date: "2014-03-20"
        paragraphs: [
            '- Added full public domain license text<br>' +
            '- Fixed path to sd card<br>' +
            '- Fixed deleting symlinks to directories<br>' +
            '- Added view contents to show rpm, apk and zip files<br>' +
        '' ]
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
            '- Fixed two deletes to work simultaneously<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.3'
        date: "2013-12-29"
        paragraphs: [
            '- Added filename search<br>' +
            '- Added audio playback<br>' +
            '- Added image preview<br>' +
            '- Added view contents to show text or binary dump<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.2'
        date: "2013-12-23"
        paragraphs: [
            '- Added menu to open files with xdg-open<br>' +
            '- Added context menu to cut, copy and paste (move/copy) files<br>' +
            '- Cancel file operations<br>' +
            '- Watches file system for changes to update the views<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.1'
        date: "2013-12-19"
        paragraphs: [
            '- Android APK and Sailfish RPM packages can be installed<br>' +
            '- Context menu to delete files and directories<br>' +
        '' ]
    }
    ChangelogItem {
        version: '1.0'
        date: "2013-12-17"
        paragraphs: [
            '- Initial release<br>' +
        '' ]
    }
}
