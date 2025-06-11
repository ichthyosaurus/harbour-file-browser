<!--
SPDX-FileCopyrightText: 2013-2016, 2018-2019 Kari Pihkala
SPDX-FileCopyrightText: 2019-2024 Mirian Margiani
SPDX-License-Identifier: GFDL-1.3-or-later
-->

# File Browser Release Notes

## Unreleased

 * Nothing so far

## Version 3.7.0 (2025-06-11)

- Added translations: Arabic
- Updated translations: Chinese, Estonian, Finnish, French, Polish, Portuguese (Brazil), Russian, Spanish, Swedish, Turkish, Ukrainian
- Fixed missing bookmarks file causing issues at startup
- Fixed a warning when starting the app and the file clipboard is empty
- Added support for automatically updating config files
- Added more invalid "external devices" to the ignore list
- Added an "open new window" button to the app cover

## Version 3.6.0 (2025-02-18)

- Added translations: Portuguese (Brazil), Tamil
- Updated translations: Estonian, Finnish, French, German, Italian, Portuguese (Brazil), Russian, Serbian, Slovak, Spanish, Swedish, Tamil, Turkish, Ukrainian
- Added support for analyzing disk space usage using “Space Inspector” (only enabled if “Space Inspector” is installed)
- Added support for play/pause using headphone buttons for audio previews
- Added more unused paths to the mount point ignore list
- Fixed file size info not being updated after editing a text file
- Fixed issues with counting files and folders
- Fixed bookmark warnings when no bookmarks file was found
- Removed bookmark migration that was needed for the switch to Sailjail
- Improved modularity to make it easier to use parts of File Browser in other apps (e.g. “Space Inspector” is built on top of File Browser's core)
- Lots of internal cleanup and modernization

## Version 3.5.0 (2024-10-30)

- Updated translations: Belarusian, Estonian, Spanish, Swedish, Ukrainian
- Added option to create a new folder when manually entering a path (e.g. when selecting a transfer target)
- Fixed the issue where attached pages (shortcuts, settings) would suddenly become blank
- Fixed an issue where the file selection could be lost by accidentally opening a context menu
- Fixed moving directories across partitions, e.g. from the internal memory to a SD card
- Fixed an issue where it was impossible to add the same manual path twice when transferring files, without restarting the app
- Fixed copied/moved files getting new timestamps instead of preserving original timestamps
- Fixed moving files to multiple targets at once
- Fixed system files (special files and broken links) not being counted in the folder size
- Fixed some instances where broken symlinks were ignored instead of being treated as files
- Fixed error message when moving a symlink fails
- Fixed a handful of bugs that could break copying and moving
- Updated Opal.MediaPlayer, now with subtitle support
- Updated all Opal modules, bringing new translations and bug fixes under the hood

## Version 3.4.0 (2024-10-21)

- Updated translations: Estonian, Slovak, Spanish, Swedish, Ukrainian, German, English
- Important change: files are now sorted by modification date instead of file age
-   - This change is necessary to align File Browser's behavior with KDE Dolphin's behavior, so that you see the same sort order when opening a mounted folder on your desktop and when opening it on your phone
-   - If you were using local view settings, you now have to switch sort order in folders where you defined it
-   - Sorting by file age meant that more recently changed files were at the top, sorting by file data means that they are at the bottom now when sorting in ascending order
-   - The old and more mobile-friendly behavior is now emulated by automatically switching sort order when switching sort role
- Added a new setting in "App Settings -> View and Behavior -> Initial view" to choose which view is shown when the app is started (folder, places, or search)
- Added partition size info in the context menu of device shortcuts
- Fixed video preview starting to play when the file details page is entered, instead of when the preview page is actually shown
- Fixed synchronising settings between the global settings page and the view settings page
- Fixed managing files larger than 2 GiB on 32bit devices
-   - Their status, size, and date are now correctly shown in the folder view
-   - They can be put in the clipboard, copied, and moved now
- Fixed a bunch of styling issues on the new Opal.MediaPlayer video preview page
- Fixed styling of gallery video play button in light ambiences
- Fixed thumbnails for video files not appearing in gallery mode
- Fixed starting search via the cover
- Fixed immediately focussing the search field when opening the search page
- Fixed some causes of the shortcuts page or settings page suddenly being blank but it still happens sometimes
- Switched to Opal.SmartScrollbar for displaying the smart scrollbar in long folder views

## Version 3.3.1 (2024-10-19)

- Updated translations: Slovak, Swedish
- Fixed an issue where the video preview would not automatically play when opened from the gallery view
- Fixed gallery video preview styling
- Fixed video preview controls becoming invisible in light ambiences
- Fixed thumbnails not showing for videos in the gallery view

## Version 3.3.0 (2024-10-18)

- Updated translations: Estonian, French, Russian, Slovak, Spanish, Swedish, Ukrainian
- Fixed missing translations so that all available translations are actually shippped!
- Increased maximum file size when editing files using the built-in text editor from 200 KiB to 2 MiB
- Replaced the old video preview page with a shiny new video preview player based
-   - The new player supports seeking and play/pause via headset buttons
-   - You can embed the new player in your own apps using the new Opal.MediaPlayer module
-   - The video player is originally based on Leszek Lesner's video player for Sailfish
- Fixed invalid copyright year on the about page
- Fixed an annoying issue where the app would show only a blank page with a busy spinner when it was started in the background
-   - This might also fix the issue where the shortcuts page sometimes stays blank
-   - The fix is a workaround for a bug in Sailfish and might not work reliably
-   - It does not yet fix the issue where the settings page is sometimes not immediately accessible from the shortcuts page
- Fixed an issue that could cause heavy lag when navigating from a folder on an SD card to the internal memory

## Version 3.2.2 (2024-10-11)

 * Updated translations: English, Russian, Polish, and more
 * Fixed contribution links to Weblate (for contributing translations)
 * Fixed moving bookmarks so they cannot end up in invalid places
 * Implemented moving/ordering bookmarks via drag and drop using Opal.DragDrop
 * Updated list of translations contributors (now generated from Weblate)

## Version 3.2.1 (2024-08-21)

 * Fixed ignoring mount points below base paths using the new config file
 * Note: the generated config file is fine and no manual changes are necessary

## Version 3.2.0 (2024-08-21)

 * Updated translations: Italian, Slovak, Russian, Dutch
 * Added config file to configure ignored mount points
 *   - this makes it easy to hide system paths that show up as external devices
 *   - edit "HOME/.config/harbour-file-browser/ignored-mounts.json" to add custom paths
 *   - please report any missing paths so they can be added to the default list
 * Fixed compatibility with SailfishOS 3.x
 * Added more checks to detect broken bookmark config files

## Version 3.1.1 (2024-08-10)

 * Updated translations: Spanish, Finnish, English, Estonian, Ukrainian, Slovak, Norwegian Bokmål, Swedish, German, Hungarian, Chinese

## Version 3.1.0 (2024-07-26)

 * Updated translations: Spanish, German, Swedish, Ukrainian, Estonian
 * Added support for shortcuts to standard locations on different storage media, like pictures in the internal memory, the SD card, and Android memory
 * Added support for translated standard locations, e.g. Documents and "Dokumente"
 * Added support for configuring thumbnail size for each folder separately
 * Added automatic focus to the search field on the search page after clearing it
 * Added new global option to disable clipboard sharing between File Browser windows
 * Fixed opening the navigation menu by tapping anywhere on the page header of the folder view
 * Fixed creating completely empty files, e.g. to create ".nomedia" files

## Version 3.0.2 (2024-06-29)

 * Updated translations: Spanish, Slovak
 * Fixed "/opt" showing up as external device

## Version 3.0.1 (2024-06-28)

 * Updated translations: Spanish, Estonian, Ukrainian
 * Fixed sharing on 64bit devices (feedback needed!)
 * Fixed large amounts of useless system-internal mount points showing up as external devices

## Version 3.0.0 (2024-06-25)

 * This update finally brings over two years worth of new and refined features, bug fixes, and translation updates!
 * This is a major update with significant improvements above and under the hood!
 * New translations: Ukrainian
 * Updated translations: Finnish, Norwegian, Spanish, Slovak, Swedish, Estonian, French, Russian, Chinese, German, English, Polish, Turkish
 * Removed translations: Swiss German (not available in Sailfish)
 * Removed Paypal donations link, please use Liberapay and avoid Paypal if at all possible
 * Added a smart scrollbar that lets you easily jump to specific files in the middle of long folder listings
 * Added donation info to the "About" page: it is now possible to buy me a cup of coffee :-) (swipe right-to-left multiple times until you reach the "About" page)
 * Added a call-for-support popup that shows up automatically when the app is used frequently
 * Added a new page showing currently copied/cut files (swipe right-to-left to the shortcuts page, then select "Clipboard")
 * Added quick access to overviews of all documents and multimedia files on the shortcuts page (this uses system components that sadly have terrible performance)
 * Added section headers when sorting by file type, which makes it easier to find files of a specific type
 * Added support for creating folders with subfolders and for creating empty files
 * Added support for changing a link's target path
 * Added a very basic text editor, e.g. for quickly editing config files in root mode
 * Added option to set a custom directory to be opened when the app starts
 * Added descriptions for all config options and improved documentation
 * Added option to show hidden files last in the file list
 * Added automatic refreshing of the folder view when file properties change, e.g. when the size changes while copying files
 * Added support for showing shortcuts for all kinds of mounted devices (previously, only folders in /run/media/USER were shown)
 * Added proper support for calculating disk and file sizes (no longer relies on external commands and finally works without causing the app to hang)
 * Added option to configure standard view mode globally
 *   - current options: list and gallery
 *   - planned: grid view
 * Added context menu option to switch to a link's target folder
 * Greatly improved performance when switching between folders, checking bookmarks, editing settings, or reading the "About" page
 * Greatly improved performance of the "edit this path" dialog
 * Improved directory filtering: hidden files will be shown when the filter string starts with a dot
 * Improved root mode:
 *   - it now requires entering your device lock code to access
 *   - note: unlocking is handled by the system, File Browser will never see your lock code
 * Improved feedback in case of errors or unexpected events
 * Improved bookmarks handling and removed no longer needed "refresh" pulley option on the shortcuts page
 * Improved manual sorting and renaming of bookmarks: press and hold, then drag and drop to sort them
 * Improved performance when previewing large image files
 * Fixed synchronization of bookmarks among multiple app windows
 * Fixed sorting directories by modification date and by size
 * Fixed root mode for Sailfish 4.3 and later
 * Fixed keyboard randomly opening and closing when selecting suggestions while editing a path
 * Fixed the path edit dialog misinterpreting empty files as directories
 * Fixed searching for hidden files when they are locally configured to be shown
 * Fixed an issue where trying to cut certain system files could possibly break the copying mechanism
 * Fixed showing search/shortcuts from cover
 * Fixed logging when config migration fails (for Sailjail)
 * Fixed PDF annotations not being saved (not thoroughly tested yet)
 * Fixed calculating folder sizes by not following symbolic links
 * Fixed enabling gallery mode in a folder when it was globally disabled
 * Fixed gallery mode hiding files unnecessarily
 * Fixed many visual glitches, fixed papercuts, added minor quality-of-life features, and added various new icons
 * Removed all dependencies on Busybox
 * Modernized the code base under the hood
 * and much, much more...

 For developers:

 * FileModel now exposes file extensions
 * FileData now exposes directory sizes, link targets, and more file properties
 * Engine now exposes clipboard contents
 * Engine no longer exposes paths of external devices and Android data
 * Added a new settings handler which reduces complexity and should improve performance overall
 *   - import module "harbour.file.browser.Settings"
 *   - use singleton types "GlobalSettings" and "RawSettings" or instantiate "DirectorySettings"
 * Improved the build system to possibly enable more features in Jolla store
 * Refactored the root mode helper build process
 * and much, much more...
 * Note: I do not know of any other apps that use File Browser's current file handling code; if you do, please contact me if there are issues with updating

## Version 2.5.1 (2022-03-30)

 * Hotfix for OpenRepos: fixed disabling sandboxing (Sailjail)

## Version 2.5.0 (2022-03-30)

 * Important note:
 *   - the Jolla store version cannot show all files in Sailfish 4.3 and later
 *   - sharing, PDF viewing, and storage settings are disabled in Jolla store
 *   - please install the unrestricted build from OpenRepos if you need all features
 * New translations: Polish, Indonesian
 * Updated translations: English, German, Swedish, Norwegian Bokmål, Slovak, Estonian, Chinese (China), French, Finnish, Hungarian, Turkish, Spanish
 * Updated list of contributors
 * Added support for backups using MyBackup
 * Added new setting to show/hide solid window background
 * Added a proper "About" page
 * Improved image loading times and error messages
 * Improved discoverability of global vs. local settings
 * Improved error handling on image/video preview page
 * Improved app icon and action icons
 * Improved logging with info about restricted/enabled features
 * Improved opening files externally
 *   - installing RPM and APK files should be possible again
 *   - a possibly upcoming "open with" system feature will be available right away
 * Improved detection of optional features:
 *   - internal PDF viewer will be properly disabled if sailfish-office is not installed
 *   - sharing will be disabled if no supported sharing method can be found
 * Fixed sharing on Sailfish <= 3.4 and Sailfish >= 4.x
 * Fixed opening directories in non-Harbour builds
 * Fixed image rotation for JPEG files
 * Fixed zoom-by-double-tap for images with almost the same dimensions as the screen
 * Fixed "Open" instead of "Install" showing for APK files
 * Changed a settings key: "gallery" mode must be re-enabled once
 * Updated config file location for Sailjail compatibility

## Version 2.4.3 (2021-02-17)

 * New translations: Dutch (Belgium), Estonian
 * Updated translations: Slovak, Hungarian, Norwegian Bokmål, Chinese (China), Swedish, Spanish
 * Fixed double tap to zoom images of square and almost square dimensions
 * Fixed horizontal mode
 *   - File Browser can now be used in all orientations
 *   - Please file a bug report if startup fails and a note about "delaying initialization" appears in the log.
 *   - Part of the fix uses a workaround for a system bug and may break unexpectedly.
 * Improved image page animations

## Version 2.4.2 (2021-02-06)

 * New translations: Czech, Slovak, Hungarian
 * Added support for opening directories with xdg-open
 * Updated list of contributors

## Version 2.4.1 (2021-02-01)

 * Note: translations are now managed using Weblate (https://hosted.weblate.org/projects/harbour-file-browser/) - contributors welcome!
 * New translation: Norwegian Bokmål
 * Updated translations: Spanish, French, Swedish, Chinese, German, ...
 * Added item count to folders in listings
 * Added link target to files in listings
 * Changed file size display units to SI units (i.e. powers of 2, KiB=1024B instead of kB=1000B)
 * Improved performance of file size preview and selecting files
 * Fixed label colors in permissions dialog, rename dialog, transfer dialog, file preview page
 * Fixed hiding empty file info fields
 * Fixed creating numbered file names when pasting over existing files with '.' in their path

## Version 2.4.0 (2021-01-12)

Published in OpenRepos and Jolla store on 2021-01-12 by ichthyosaurus.

 * Finally out of beta
 *   - Configuration is now stored at ~/.config/harbour-file-browser. Copy your beta configuration from ~/.config/harbour-file-browser-beta to keep custom shortcuts.
 *   - You can safely remove the folder ~/.local/share/harbour-file-browser-beta.
 *   - Updated root mode for non-beta release (packaged separately)
 *   - Note: it might be necessary to manually remove the old packages harbour-file-browser-beta and harbour-file-browser-root-beta
 * Updated translations: Swedish, Chinese, German
 * Greatly improved performance when loading folders and moving/deleting files
 *   - before: loading a folder with 5000 images (sorted by modification time) took ~5 seconds, moving/deleting 1 file took ~8 seconds; with times climbing exponentially
 *   - now: loading the same folder (any sorting mode) is nearly instantly, moving/deleting too
 *   - now: sorting mode will no longer noticeably affect performance (sorting by modification time was by far the slowest mode before)
 *   - note: when deleting/moving/filtering more than 200 files the view will lose its position and jump to the top
 * Greatly improved filtering performance
 *   - before: filtering a folder with 5000 images took ~20 seconds, scrolling was nearly impossible
 *   - now: the same folder filters nearly instantly, scrolling is smooth
 *   - note: the folder listing will be updated when closing the top menu
 * Improved navigation performance: switching between folders should feel much more responsive now
 * Fixed a bug causing page navigation by swiping to break
 * Fixed performance issues when opening view preferences
 * Fixed keyboard flickering when opening view preferences
 * Fixed selection panel being closed while one file was still selected
 * Fixed file pages breaking after file(s) have been moved away
 * Fixed folder listings jumping to the top after deleting or transferring files and after changing settings
 * Fixed highlighting files when the context menu is opened, a thumbnail is being shown, or gallery mode is activated
 * Added support for simple wildcards when filtering
 *   - use '*' to match any one or more characters
 *   - use '?' to match any single character
 *   - use '[abc]' to match one character of the group in square brackets
 *   - to include a literal '*' or '?' you have to enclose it in square brackets
 * Added proper user feedback while loading folders
 * Added indicators for files that are being moved/deleted
 * Added an informational placeholder when no file matched the filter
 * Improved suggestions highlighting when manually editing the current path
 * Improved system integration: "open storage settings" menu item will only be shown if storage module is installed
 * Improved navigation menu: duplicate history entries should not happen anymore
 * Improved licensing: the project is now 'reuse'-compliant (cf. https://reuse.software/spec/)

 For developers:

 * Added and improved some documentation
 * Added a new worker thread class for loading, refreshing, and sorting folders in the background
 * Added modification time info from stat(3) to StatFileInfo
 * Implemented custom sorting by modification time, as QDir's performance is terrible
 * Implemented a hashing/caching algorithm for partially refreshing folder listings
 * Improved icon rendering: code can be easily reused in other projects
 * Clarified licensing for all files: documentation is GFDL, some files are CC0 (all files have proper SPDX license headers now)

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
