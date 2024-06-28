dnl/// SPDX-FileCopyrightText: 2023 Mirian Margiani
dnl/// SPDX-License-Identifier: GFDL-1.3-or-later

ifdef(${__X_summary}, ${
A comprehensive file manager for local files on [Sailfish OS](https://sailfishos.org/).
})dnl

ifdef(${__X_description}, ${
ifdef(${__X_readme}, ${This repository contains the development of version 2.0.0 and upwards of __name.
See the [release notes](__full_repo_url/blob/main/CHANGELOG.md)
for further details.

## Warning
})dnl

**Use at your own risk**. You can use this app to corrupt files and break
Sailfish on your device. The author ifdef(${__X_readme}, ${of __name}) does not
take any responsibility if that happens. So, be careful.

## Features

- Browse and search files and folders
- Share files and open files in an external app
- Preview contents of images files, audio files, video files,
  compressed archives, databases, etc.
- Select multiple files (by tapping the file icons)
- Quickly copy, link, or move large amounts of files at once
- Bulk rename, delete, or edit files and folders
- Edit file and folder permissions
- Create new files and folders
- Show and hide hidden files (filenames starting with a dot)
- Open multiple windows and move files between them
- Copy, edit, or manually enter paths
- Quickly filter files from the top pulley menu
- Set per-folder view preferences
- Save custom quick shortcuts for navigating and moving files

... and much more.

ifdef(${__X_harbour}, ${
## Limitations in this version
}, ${
## Limitations in Jolla's Harbour store
})

__name in Jolla's Harbour store cannot show all files due to mandatory
sandboxing (Sailjail) since Sailfish OS 4.4. Inaccessible folders appear empty
as there is no way for the app to determine if a folder is actually empty or
simply presented as empty by the system.

Additionally, some file previews and integrated access to storage settings are
disabled.

ifdef(${__X_harbour}, ${
If you need full access to all files, please install __name from
[OpenRepos](https://openrepos.net/content/ichthyosaurus/file-browser).
}, ${
The version on [OpenRepos](https://openrepos.net/content/ichthyosaurus/file-browser)
is not affected by these limitations.
})

## Permissions

__name requires the following permissions:

- Audio: for playing previews of audio files
- MediaIndexing: to list all documents
- RemovableMedia: for browsing USB sticks and SD cards
- UserDirs and PublicDir: to show as many files as possible while restricted by Sailjail

**Note:** sandboxing is only enabled for builds in Jolla's Harbour store. The
version on [OpenRepos](https://openrepos.net/content/ichthyosaurus/file-browser)
has no such restrictions and can show all files.
})

## Root mode

__name can run with administrator privileges to give you unrestricted access to
your system. To use this feature, you must install
[Root mode for __name](https://openrepos.net/content/ichthyosaurus/root-mode-file-browser-v2)
from OpenRepos. Root mode is protected by your lock code.

ifdef(${__X_openrepos}, ${
[translated names to help OpenRepo's search function: harbour-file-browser, harbour-file-browser-beta, File Browser, File Manager, Filemanager, Filebrowser, Files, Tiedostoselain, Dateiverwaltung, Pliki, ...]
}, ${})
