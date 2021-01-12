<!--
SPDX-FileCopyrightText: 2013-2016, 2018-2019 Kari Pihkala
SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
SPDX-License-Identifier: GFDL-1.3-or-later
-->

# File Browser Release Notes

## Unreleased

 * Finally out of beta
 *   - Configuration is now stored at ~/.config/harbour-file-browser. Copy your beta configuration from ~/.config/harbour-file-browser-beta to keep shortcuts.
 *   - You can safely remove the folder ~/.local/share/harbour-file-browser-beta.
 *   - Updated root mode for non-beta release (packaged separately)
 * Fixed a bug causing page navigation by swiping to break
 * Updated Swedish translation
 * Improved suggestions highlighting when manually editing the current path
 * Improved system integration: "open storage settings" menu item will only be shown if storage module is installed

## Version 2.3.2-beta (2021-01-07)

Published in OpenRepos on 2021-01-07 by ichthyosaurus.

 * Fixed deleting files via context menu
 * Fixed clearing selection while filtering
 * Added a menu icon to directory headers (can be disabled in the settings)
 * Improved description text for adding custom transfer targets
 * Refactored page navigation and navigation history (even good things can be improved)
 * Fixed some console noise

## Version 2.3.1-beta (2020-12-04)

Published in OpenRepos on 2020-12-04 by ichthyosaurus.

 * Updated translations: Swedish, Chinese
 * Changed file info icon to the default system icon
 * Changed toolbar icons to 112x112px instead of 64x64px
 * Fixed height and thickness of toolbar icons (lines) to match system icons
 * Fixed file previews so file icons don't scale too much
 * Fixed an error message caused by string formatting

## Version 2.3.0-beta (2020-11-22)

Published in OpenRepos on 2020-11-22 by ichthyosaurus.

 * Updated translations: Spanish, Swedish, Chinese, German, English (thanks to contributors!)
 * Implemented navigation history: use the directory popup to navigate back and forward (see below)
 * Added support for adding shortcuts to a manually entered path (bottom pulley on the shortcuts page)
 * Added support for adding custom transfer targets by path (top pulley in the transfer dialog)
 * Added a new directory popup (similar to the old one from version <= 1.8.0)
 *   - open it by tapping on the page title in a directory listing
 *   - navigation history: go back, forward, and up ("up" is the same as swiping left)
 *   - quickly toggle viewing hidden files
 *   - edit the current path (or e.g. paste a path from clipboard)
 * Added setting on how to abbreviate/elide filenames
 * Added preview for SQLite databases
 * Improved performance on many pages (directory listings, search, shortcuts, navigation, ...)
 * Fixed a large amount of visual bugs, inconsistencies, and papercuts
 * Fixed many small bugs concerning edge cases in nagivation, settings, etc.
 * Fixed accidentally opening the keyboard when switching to the sort/view settings
 * Allowed rotating all pages (it is still not working perfectly, but this might be a bug in the system)
 * Fixed handling selections: selections will be cleared less often, e.g. helping with sorting files
 * Fixed filtering files case-insensitively
 * Fixed keeping search results without restarting the search after checking a file
 * Implemented rudimentary video error handling (when previewing files)
 * Improved error handling in file previews (rpm, sqlite, zip, ...)
 * Improved file type detection and file icons
 * Improved support for thumbnails (e.g. PDF and video files can have thumbnails now)
 * Added and improved documentation
 * Clarified licenses: GPL v3 (or later) for code, CC-BY-SA 4.0 for graphics
 * Prepared for first non-beta release in Jolla store

 For developers:

 * Restructured the development environment
 * Implemented a new versatile dialog for manually entering paths, including completion suggestions
 * Implemented different search types in the search engine
 * Added support for limiting the amount of search results
 * Added directory info properties to the file data backend

## Version 2.2.2-beta (2020-05-29)

Published in OpenRepos on 2020-05-29 by ichthyosaurus.

 * Fixed saving settings when the settings file did not exist
 * Fixed showing disk space under SFOS 3.3.x.x
 * Fixed rare possibility of duplicate bookmark entries
 * Fixed bookmarks vanishing when the user renames the configuration folder while the app is running
 * Fixed calculating size info and counting files for links or directories containing links
 * Fixed copying hidden files when copying a directory recursively
 * Improved user notice when a link is broken
 * Improved directory/link state detection (might help with a bug regarding CIFS mounts)

 For developers:

 * Internal API changes
 *   - Documented Engine::isUsingBusybox()
 *   - Added Settings::keys()

## Version 2.2.1-beta (2020-05-02)

Published in OpenRepos on 2020-05-02 by ichthyosaurus.

 * Added root mode (packaged separately)
 * Fixed inconsistent default setting for "View/UseLocalSettings"
 * Added "open storage settings" to bottom pulley of shortcuts page
 * Disabled opening system settings from shortcuts for Jolla store and when running as root

## Version 2.2.0-beta (2020-05-01)

Published in OpenRepos on 2020-05-01 by ichthyosaurus.

 * Fixed showing file info page under SailfishOS 3.3.x.x
 * Fixed the same for symlinks to directories on another partition
 * Increased performance when changing directories
 * Shortcut to Android data will be hidden if the directory is not available

 For developers:

 * Internal API changes
 *   - Removed some small helper functions
 *   - Refactored and split scripts and libraries
 *   - Removed Engine::homeFolder()
 *   - Renamed Engine::androidSdcardPath() to Engine::androidDataPath()

## Version 2.1.1-beta (2020-04-19)

Published in OpenRepos on 2020-04-19 by ichthyosaurus.

 * Added support for opus audio files: recognize them as audio, and allow internal playback
 * Removed trying to show thumbnails for PDF files and videos: the system thumbnailer does not support it

## Version 2.1.0-beta (2020-01-12)

Published in OpenRepos on 2020-01-12 by ichthyosaurus.

 * Added file icons for compressed files and for PDF files
 * Implemented a new "Gallery Mode": images will be shown comfortably large, and all entries except for images, videos, and directories will be hidden
 * Implemented previewing videos directly
 *   - Note that this is intentionally kept simple. Use an external app for anything other than quickly checking what the file contains.
 *   - Thumbnail images for videos are not available as they are not supported by the system thumbnailer.
 * Added support for USB OTG devices
 *   - Any device mounted below /run/media/nemo will now be shown together with the SD card
 *   - Added a bottom pulley to the shortcuts page to manually refresh the list of devices
 *   - External storage settings can now directly be accessed via the context menu (see below)
 * Improved usability of bookmarks and shortcuts
 *   - Implemented manually sorting bookmarks
 *   - Fixed wrong icon for deleting bookmarks
 *   - Fixed bookmarks when transferring files
 *   - Moved shortcut to Android storage to the main "Locations" section
 * Improved settings handling to be more robust
 *   - Please note that all *customized* bookmark names will be reset *once* after installing this update
 *   - Fixed a bug where bookmark names (not the bookmarks themselves) could get lost
 *   - Added runtime-caching of settings to handle missing permissions
 *   - Fixed changing view settings in read-only directories
 *   - Restricted saving local view settings to /home/nemo/* and /run/media/nemo/*, so even if File Browser is run as root, no unwanted files will be written anywhere
 *   - Improved settings handling to be more intuitive when resetting a local value to the global default
 * not Harbour-compliant changes:
 *   - Added showing PDF files directly from the file page (swipe right) using Sailfish Office
 *   - Added context menu to external devices (bookmark page) to directly open system settings
 * Fixed a typo on the sorting options page
 * Added option to copy current path to clipboard to the main bottom pulley
 * Fixed showing path in pulley when adding a bookmark via shortcuts page
 * Performance improvements in
 *   - loading directories
 *   - switching between thumbnail modes
 *   - previewing large images

 For developers:

 * Internal API changes
 *   - Moved settings from Engine to standalone settings handler
 *   - Replaced separate method for detecting SD cards by method collecting all mounted devices

## Version 2.0.1-beta (2019-12-30)

Published in OpenRepos on 2019-12-30 by ichthyosaurus.

 * Updated translations: Swedish, Chinese, Spanish
 * (other translations still need updating - contributors welcome!)

## Version 2.0.0-beta (2019-12-12)

Published in OpenRepos on 2019-12-12 by ichthyosaurus.

 * Performance improvements in
 *   - changing directories
 *   - loading directories
 *   - applying new settings
 * Implemented sharing files (non-Harbour version only)
 * Added file transfer option (quickly copy/move/link multiple files to multiple destinations)
 * Added shortcuts page instead of quick-links menu (swipe right)
 * Added bookmarks option (add from pulley or context menu, access on shortcuts page)
 * Show content preview of file immediately as attached page (swipe right)
 * Improved pulley menu order on file page
 * Moved some entries from pull down menu to push up menu on directory page
 * Added more sorting options for directory listings
 * Added setting to sort case-sensitively or case-insensitively
 * Simplified applying directory settings (top pulley or tap on directory title)
 * Fixed calculating disk space usage
 * Improved file date/time info
 * Added setting to use local view settings for all directories (.directory files from desktop file managers)
 * Improved selection panel and context menu in directory listings
 * Added file actions (copy/rename/share/... to file page)
 * Added quick-filter option to directory listings (open top pulley to maximum)
 * Improved rename dialog
 *   - disabled text prediction
 *   - added support for renaming multiple files at once
 *   - added check if file already exists
 * Improved horizontal app layout
 * Implemented file preview thumbnails
 * Added image viewer page (swipe right from file page)
 * Added "shift" selection of multiple files (long press on file entry to start)
 * Added cover actions ('search' and 'show shortcuts')
 * Added support for selecting text file preview (just like in the Notes app)
 * Implemented computing size of all selected file/directories (with properties page)
 * Implemented computing directory size (visible from properties page)
 * Implemented opening new windows
 * Improved launcher entry
 * Improved support for light ambiences
 * Improved and added some custom icons
 * Added support for animations in image viewer (e.g. GIF files)
 * Added list of contributors (swipe right from settings page)
 * Added support for initial directory as command line argument
 * Added settings page as attached page to shortcuts page (swipe right)
 * Added root mode app icon and highlight cover when running as root
 * Re-built app icon as SVG and generated new png images
 * Improved many strings (translations not updated yet)
 * Updated German translation
 * Polished user interface with improvements here and there
 * **IMPORTANT**: for version 2.0.0 and upwards, the licensing has been changed to the GNU GPL v3 (or later).

## Version 1.8.0 (2019-05-12)

Published in Jolla store on 2019-05-13 by karip.

 * Added a confirmation dialog for file overwriting
 * Fixed colors and icons for Sailfish 3 light ambiences

## Version 1.7.3 (2018-07-05)

Published in Jolla store on 2018-07-05 by karip.

 * Fixed the SDCard location for users with an unusual sdcard symlink

## Version 1.7.2 (2018-06-11)

Published in Jolla store on 2018-06-11 by karip.

 * Fixed SDCard location for Sailfish 2.2.0
 * Fixed to start on Sailfish 1 phones

## Version 1.7.1 (2018-02-11)

Published in Jolla store on 2018-02-12 by karip.

 * Added translations for French, Dutch and Greek
 * Fixed icons for high density screens

## Version 1.7 (2016-06-27)

Published in Jolla store on 2016-06-28 by karip.

 * Add translations for Italian, Russian, Spanish and Swedish
 * Small UI improvements to match the Sailfish look

## Version 1.6 (2015-03-22)

Published in Jolla store on 2015-03-23 by karip.

 * Add translations for Finnish, German and Simplified Chinese languages
 * Fix occasional search page hangup

## Version 1.5 (2014-09-01)

Published in Jolla store on 2014-09-02 by karip.

 * Multiple file selections
 * View contents of tar files
 * Display image size, exif and other metadata
 * Displays broken symbolic links
 * Move and copy symbolic links
 * Display mime type information
 * Display chr, blk, fifo and sock files correctly

## Version 1.4.2 (2014-03-20)

Published in Jolla store on 2014-03-21 by karip.

 * Added full public domain license text
 * Fixed path to sd card
 * Fixed deleting symlinks to directories
 * Added view contents to show rpm, apk and zip files

## Version 1.4.1 (2014-01-26)

Published in Jolla store by karip.

 * Added Settings page
 * Added show hidden files
 * Added show directories first
 * Added rename files and folders
 * Added create folders
 * Added change permissions
 * Added disk space indicators
 * Fixed two deletes to work simultaneously

## Version 1.3 (2013-12-29)

Published in Jolla store on 2014-01-03 by karip.

 * Added filename search
 * Added audio playback
 * Added image preview
 * Added view contents to show text or binary dump

## Version 1.2 (2013-12-23)

Published in Jolla store by karip.

 * Added menu to open files with xdg-open
 * Added context menu to cut, copy and paste (move/copy) files
 * Cancel file operations
 * Watches file system for changes to update the views

## Version 1.1 (2013-12-19)

Published in Jolla store by karip.

 * Android APK and Sailfish RPM packages can be installed
 * Context menu to delete files and directories

## Version 1.0 (2013-12-17)

Published in Jolla store on 2013-12-19 by karip.

 * Initial release
