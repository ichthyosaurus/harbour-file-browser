<!--
SPDX-FileCopyrightText: 2013 Michael Faro-Tusino
SPDX-FileCopyrightText: 2013 karip
SPDX-FileCopyrightText: 2013-2016 Kari Pihkala
SPDX-FileCopyrightText: 2019-2021 Mirian Margiani

SPDX-License-Identifier: GFDL-1.3-or-later
-->

# File Browser for Sailfish OS

A file manager application to view and browser files on
[Sailfish OS](https://sailfishos.org/) and [Jolla phones](http://jolla.com/).

There is a [FAQ](https://github.com/ichthyosaurus/harbour-file-browser/blob/master/FAQ.md)
about most common questions.

This repository contains the development of version 2.0.0 and upwards of File
Browser. See the [release notes](https://github.com/ichthyosaurus/harbour-file-browser/blob/master/CHANGELOG.md)
for further details.

### Warning

USE AT YOUR OWN RISK. This app can be used to corrupt files on the phone
and make the phone unusable. The author of File Browser does not take any
responsibility if that happens. So, be careful.

### Features

 - Browse and search files and folders on the phone
 - Open files (if xdg-open finds a preferred application)
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

### Acknowledgements

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

## Building and contributing

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for details on how you can
contribute.

If you want to contribute code changes, you can setup your environment by
following the steps below. This is not needed for contributing to translations,
as they are managed using [Weblate](https://hosted.weblate.org/projects/harbour-file-browser/).

1. Get the source code
2. Open `harbour-file-browser.pro` in Sailfish OS IDE (Qt Creator for Sailfish)
3. To run on emulator, select the `i486` target and press the run button
4. To build for the device, select the `armv7hl` target and deploy all,
   the RPM packages will be in the RPMS folder

## License

[![GNU GPL v3.0](http://www.gnu.org/graphics/gplv3-127x51.png)](http://www.gnu.org/licenses/gpl.html)
[![OSI](http://opensource.org/trademarks/opensource/OSI-Approved-License-100x137.png)](https://opensource.org/licenses/GPL-3.0)

File Browser is released under the terms of the
[GNU General Public License v3 (or later)](https://spdx.org/licenses/GPL-3.0-or-later.html).

    File Browser is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    File Browser is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

The source code is available [on Github](https://github.com/ichthyosaurus/harbour-file-browser).

All documentation is released under the terms of the
[GNU Free Documentation License v1.3 (or later)](https://spdx.org/licenses/GFDL-1.3-or-later.html).

    Permission is granted to copy, distribute and/or modify this document
    under the terms of the GNU Free Documentation License, Version 1.3
    or any later version published by the Free Software Foundation;
    with the Invariant Sections being [none yet], with the Front-Cover Texts
    being [none yet], and with the Back-Cover Texts being [none yet].
    You should have received a copy of the GNU Free Documentation License
    along with this document.  If not, see <http://www.gnu.org/licenses/>.
