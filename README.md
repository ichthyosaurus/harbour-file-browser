<!--
SPDX-FileCopyrightText: 2013 Michael Faro-Tusino
SPDX-FileCopyrightText: 2013 karip
SPDX-FileCopyrightText: 2013-2016 Kari Pihkala
SPDX-FileCopyrightText: 2019-2022 Mirian Margiani

SPDX-License-Identifier: GFDL-1.3-or-later
-->

![File Browser banner](icon-src/banner.png)

# File Browser for Sailfish OS

[![Translations](https://hosted.weblate.org/widgets/harbour-file-browser/-/main-translations/svg-badge.svg)](https://hosted.weblate.org/projects/harbour-file-browser/main-translations/)
[![Source code license](https://img.shields.io/badge/source_code-GPL--3.0--or--later-yellowdarkgreen)](https://github.com/ichthyosaurus/harbour-file-browser/tree/main/LICENSES)
[![REUSE status](https://api.reuse.software/badge/github.com/ichthyosaurus/harbour-file-browser)](https://api.reuse.software/info/github.com/ichthyosaurus/harbour-file-browser)
[![Development status](https://img.shields.io/badge/development-active-blue)](https://github.com/ichthyosaurus/harbour-file-browser)
<!-- [![Liberapay donations](https://img.shields.io/liberapay/receives/ichthyosaurus)](https://liberapay.com/ichthyosaurus) -->

A file manager application to view and browser files on
[Sailfish OS](https://sailfishos.org/) and [Jolla phones](http://jolla.com/).

This repository contains the development of version 2.0.0 and upwards of File
Browser. See the [release notes](https://github.com/ichthyosaurus/harbour-file-browser/blob/master/CHANGELOG.md)
for further details.

### Warning

USE AT YOUR OWN RISK. This app can be used to corrupt files on the phone
and make the phone unusable. The author of File Browser does not take any
responsibility if that happens. So, be careful.

### Features

 - Browse and search files and folders on the phone
 - Open files with an external app
 - View image files and pictures as thumbnails or in a gallery
 - Play back WAV, MP3, OGG, and FLAC audio
 - Install Android APK and Sailfish RPM packages
 - View contents of APK, RPM, ZIP and TAR packages
 - Preview contents of video, text, SQLite databases, and binary files
 - Select multiple files (by tapping the file icons)
 - Link, cut, move, copy and paste multiple files at once (by long pressing an
   item or tapping the file icons)
 - Rename files and folders
 - Create new folders
 - Delete files and folders (by long pressing an item or tapping the file icons)
 - Show hidden files (filenames starting with a dot)
 - Edit file and folder permissions
 - Open multiple windows
 - Copy, edit, or manually enter paths
 - Quickly filter files from the top pulley
 - Set per-folder view preferences
 - Save custom quick shortcuts for navigating and moving files

... and much more.

### Permissions

File Browser requires the following permissions since Sailfish OS 4.4:

- Audio: for playing audio files inline
- MediaIndexing: to list all documents (not yet used)
- RemovableMedia: for browsing USB sticks and SD cards
- UserDirs and PublicDir: to show as many files as possible while restricted by Sailjail

**Note:** Sandboxing is only enabled for builds in Jolla's Harbour store. This
version cannot show all files. The version on OpenRepos will have no such restrictions.

### Limitations in Jolla Store (Harbour)

**Note:** The OpenRepos version has no such restrictions.

Starting with SailfishOS version 4.4, File Browser suffers from severe
limitations due to sandboxing (Sailjail).

- only the contents of the current user's data directories (Documents, Pictures,
  ...) can be accessed, removable media might be accessible
- disabled features: sharing, integrated access to storage settings, integrated
  PDF viewer
- file and directory info might be incomplete
   - directory contents may not be counted correctly
   - file and directory sizes might be calculated incorrectly or not at all
- some file previews may be incomplete or unavailable
   - archives: ZIP, TAR, RPM, APK
   - databases: SQLite

This list is probably incomplete and it will hopefully shrink again.

## Help and support

There is a [FAQ](https://github.com/ichthyosaurus/harbour-file-browser/blob/master/FAQ.md)
about some common questions.

If your question is not listed there, please visit the
[thread in the Sailfish forums](https://forum.sailfishos.org/t/file-browser-support-and-feedback-thread/4566).
You are also welcome to leave a comment on [OpenRepos](https://openrepos.net/content/ichthyosaurus/file-browser)
or in the Jolla store.

## Translations

It would be wonderful if the app could be translated in as many languages as possible!

Translations are managed using [Weblate](https://hosted.weblate.org/projects/harbour-file-browser/).
Please prefer this over pull request (which are still welcome, of course).
If you just found a minor problem, you can also
[leave a comment in the forum](https://forum.sailfishos.org/t/file-browser-support-and-feedback-thread/4566)
or [open an issue](https://github.com/ichthyosaurus/harbour-file-browser/issues/new).

Please include the following details:

1. the language you were using
2. where you found the error
3. the incorrect text
4. the correct translation

### Manually updating translations

Please prefer using [Weblate](https://hosted.weblate.org/projects/harbour-file-browser/)
over this.

You can follow these steps to manually add or update a translation:

1. *If it did not exist before*, create a new catalog for your language by copying the
   base file [translations/harbour-file-browser.ts](translations/harbour-file-browser.ts).
   Then add the new translation to [harbour-file-browser.pro](harbour-file-browser.pro).
2. Add yourself to the list of contributors in [qml/pages/AboutPage.qml](qml/pages/AboutPage.qml).
3. Translate the app's name in [harbour-file-browser.desktop](harbour-file-browser.desktop)
   if there is a (short) native term for "file manager" or "file browser" in your language.

See [the Qt documentation](https://doc.qt.io/qt-5/qml-qtqml-date.html#details) for
details on how to translate date formats to your *local* format.

## Building and contributing

*Bug reports, and contributions for translations, bug fixes, or new features are always welcome!*

1. Clone the repository: `https://github.com/ichthyosaurus/harbour-file-browser.git`
2. Open `harbour-file-browser.pro` in Sailfish OS IDE (Qt Creator for Sailfish)
3. To run on emulator, select the `i486` target and press the run button
4. To build for the device, select the `armv7hl` target and deploy all,
   the RPM packages will be in the RPMS folder

Please do not forget to add yourself to the list of contributors in
[qml/pages/AboutPage.qml](qml/pages/AboutPage.qml)!

## Acknowledgements

File Browser had been developed since 2013 by [karip](https://github.com/karip)
up until version 1.8.0. Source code and compiled packages of legacy versions
(which were released into the public domain) are still available in karip's
repository [on Github](https://github.com/karip/harbour-file-browser).

Exif data embedded in image files is displayed with [JHead](http://www.sentex.net/~mwandel/jhead/),
which is a public domain Exif manipulation tool.

### Other file managers

There is a very handy two-paned file manager called Cargo Dock
in the Jolla Store. Give it a try if you are moving a lot of files.

There are a number of other file managers available in OpenRepos.

## License

File Browser is released under the terms of the
[GNU General Public License v3 (or later)](https://spdx.org/licenses/GPL-3.0-or-later.html).
The source code is available [on Github](https://github.com/ichthyosaurus/harbour-file-browser).
All documentation is released under the terms of the
[GNU Free Documentation License v1.3 (or later)](https://spdx.org/licenses/GFDL-1.3-or-later.html).

This project follows the [REUSE specification](https://api.reuse.software/info/github.com/ichthyosaurus/harbour-file-browser).
