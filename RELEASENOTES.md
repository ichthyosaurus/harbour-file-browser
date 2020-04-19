
# File Browser Release Notes

## Version 2.1.1-beta (2020-04-19)

Published in OpenRepos on 2020-04-19.

 * Added support for opus audio files: recognize them as audio, and allow internal playback
 * Removed trying to show thumbnails for PDF files and videos: the system thumbnailer
   does not support it

## Version 2.1.0-beta (2020-01-12)

Published in OpenRepos on 2020-01-12.

 * Added file icons for compressed files and for PDF files
 * Implemented a new "Gallery Mode": images will be shown comfortably large, and
   all entries except for images, videos, and directories will be hidden
 * Implemented previewing videos directly
 *     - Note that this is intentionally kept simple.
 *       Use an external app for anything other than quickly checking what the file contains.
 *     - Thumbnail images for videos are not available as they are not supported by the system thumbnailer.
 * Added support for USB OTG devices
 *     - Any device mounted below /run/media/nemo will now be shown together with the SD card
 *     - Added a bottom pulley to the shortcuts page to manually refresh the list of devices
 *     - External storage settings can now directly be accessed via the context menu (see below)
 * Improved usability of bookmarks and shortcuts
 *     - Implemented manually sorting bookmarks
 *     - Fixed wrong icon for deleting bookmarks
 *     - Fixed bookmarks when transferring files
 *     - Moved shortcut to Android storage to the main "Locations" section
 * Improved settings handling to be more robust
 *     - Please note that all *customized* bookmark names will be reset *once*
 *       after installing this update
 *     - Fixed a bug where bookmark names (not the bookmarks themselves) could get lost
 *     - Added runtime-caching of settings to handle missing permissions
 *     - Fixed changing view settings in read-only directories
 *     - Restricted saving local view settings to /home/nemo/* and /run/media/nemo/*,
 *       so even if File Browser is run as root, no unwanted files will be written
 *       anywhere
 *     - Improved settings handling to be more intuitive when resetting a local
 *       value to the global default
 * not Harbour-compliant changes:
 *     - Added showing PDF files directly from the file page (swipe right)
 *       using Sailfish Office
 *     - Added context menu to external devices (bookmark page) to directly
 *       open system settings
 * Fixed a typo on the sorting options page
 * Added option to copy current path to clipboard to the main bottom pulley
 * Fixed showing path in pulley when adding a bookmark via shortcuts page
 * Performance improvements in
 *     - loading directories
 *     - switching between thumbnail modes
 *     - previewing large images

For developers:

 * Internal API changes
 *     - Moved settings from Engine to standalone settings handler
 *     - Replaced separate method for detecting SD cards by method collecting all mounted devices

## Version 2.0.1-beta (2019-12-30)

Published in OpenRepos on 2019-12-30.

 * Updated translations: Swedish, Chinese, Spanish
 * (other translations still need updating - contributors welcome!)

## Version 2.0.0-beta (2019-12-12)

Published in OpenRepos on 2019-12-12.

 * Performance improvements in
 *     - changing directories
 *     - loading directories
 *     - applying new settings
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

Note to developers: for this beta version (2.0.0 and upwards), the licensing was changed to the GNU GPLv3+.

## Version 1.8.0 (2019-05-12)

Published in Jolla store on 2019-05-13.

 * Added a confirmation dialog for file overwriting
 * Fixed colors and icons for Sailfish 3 light ambiences

## Version 1.7.3 (2018-07-05)

Published in Jolla store on 2018-07-05.

 * Fixed the SDCard location for users with an unusual sdcard symlink

## Version 1.7.2 (2018-06-11)

Published in Jolla store on 2018-06-11.

 * Fixed SDCard location for Sailfish 2.2.0
 * Fixed to start on Sailfish 1 phones

## Version 1.7.1 (2018-02-11)

Published in Jolla store on 2018-02-12.

 * Added translations for French, Dutch and Greek
 * Fixed icons for high density screens

## Version 1.7 (2016-06-27)

Published in Jolla store on 2016-06-28.

 * Add translations for Italian, Russian, Spanish and Swedish
 * Small UI improvements to match the Sailfish look

## Version 1.6 (2015-03-22)

Published in Jolla store on 2015-03-23.

 * Add translations for Finnish, German and Simplified Chinese languages
 * Fix occasional search page hangup

## Version 1.5 (2014-09-01)

Published in Jolla store on 2014-09-02.

 * Multiple file selections
 * View contents of tar files
 * Display image size, exif and other metadata
 * Displays broken symbolic links
 * Move and copy symbolic links
 * Display mime type information
 * Display chr, blk, fifo and sock files correctly

## Version 1.4.2 (2014-03-20)

Published in Jolla store on 2014-03-21.

 * Added full public domain license text
 * Fixed path to sd card
 * Fixed deleting symlinks to directories
 * Added view contents to show rpm, apk and zip files

## Version 1.4.1 (2014-01-26)

 * Added Settings page
 * Added show hidden files
 * Added show directories first
 * Added rename files and folders
 * Added create folders
 * Added change permissions
 * Added disk space indicators
 * Fixed two deletes to work simultaneously

## Version 1.3 (2013-12-29)

Published in Jolla store on 2014-01-03.

 * Added filename search
 * Added audio playback
 * Added image preview
 * Added view contents to show text or binary dump

## Version 1.2 (2013-12-23)

 * Added menu to open files with xdg-open
 * Added context menu to cut, copy and paste (move/copy) files
 * Cancel file operations
 * Watches file system for changes to update the views

## Version 1.1 (2013-12-19)

 * Android APK and Sailfish RPM packages can be installed
 * Context menu to delete files and directories

## Version 1.0 (2013-12-17)

Published in Jolla store on 2013-12-19.

 * Initial release

