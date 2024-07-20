<!--
SPDX-FileCopyrightText: 2020-2023 Mirian Margiani

SPDX-License-Identifier: GFDL-1.3-or-later
-->

# Settings

## Global Settings

| Key                                | Default value | Allowed values                                | Legacy key (in `[General]`)  | Introduced in
|------------------------------------|---------------|-----------------------------------------------|------------------------------|--------------
| **`[General]`**                    |               |                                               |                              |
| `DefaultFilterAction`              | `filter`      | `filter`/`search`                             |                              |
| `ShowFullDirectoryPaths`           | `false`       | bool                                          |                              |
| `ShowNavigationMenuIcon`           | `true`        | bool                                          |                              |
| `FilenameElideMode`                | `fade`        | `fade`/`end`/`middle`                         |                              |
| `SolidWindowBackground`            | `false`       | bool                                          |                              |
| `InitialDirectoryMode`             | `home`        | `home`/`last`/`custom`                        |                              |
| `CustomInitialDirectoryPath`       | home dir      | any string                                    |                              |
| `LastDirectoryPath`                | home dir      | any string                                    |                              |
| `ShareClipboard`                   | `true`        | bool                                          |                              | 3.1.0
| `UseTrashCan`                      | `true`        | bool                                          |                              | planned for >3.2.0
| **`[Transfer]`**                   |               |                                               |                              |
| `DefaultAction`                    | `none`        | `copy`/`move`/`link`/`none`                   | `default-transfer-action`    |
| **`[View]`**                       |               |                                               |                              |
| `SortRole`                         | `name`        | `name`/`size`/`modificationtime`/`type`       | `listing-sort-by`            |
| `SortOrder`                        | `default`     | `default`/`reversed`                          | `listing-order`              |
| `SortCaseSensitively`              | `false`       | bool                                          | `sort-case-sensitive`        |
| `ShowDirectoriesFirst`             | `true`        | bool                                          | `show-dirs-first`            |
| `ShowHiddenLast`                   | `false`       | bool                                          |                              |
| `HiddenFilesShown`                 | `false`       | bool                                          | `show-hidden-files`          |
| `PreviewsShown`                    | `false`       | bool                                          | `show-thumbnails`            |
| `PreviewsSize`                     | `medium`      | `small`/`medium`/`large`/`huge`               | `thumbnails-size`            |
| `UseLocalSettings`                 | `true`        | bool                                          | `use-local-view-settings`    |
| `ViewMode`                         | `list`        | `list`/`gallery`/`grid`                       |                              | 2.5.0*
| **`[Bookmarks]`**                  |               |                                               |                              |
| `Entries="[\"...\"]"`              |               | ordered array of paths as JSON strings (this field holds only the order of elements, not the elements themselves) | `bookmark-entries` |
| `home#nemo#Devel=Devel`            |               | `path=bookmark name` for each bookmark (with all `/` replaced by `#` to distinguish them from settings groups) | |

**\*** changed from an earlier version, see section *"Obsolete Settings"* below

## Local Settings

Local settings are read from a hidden file named `.directory` in the current directory.
They use the same entries as [KDE](https://kde.org)'s file manager
[Dolphin](https://apps.kde.org/en/dolphin).

| Key                                | Default value | Values
|------------------------------------|---------------|-----------------------------------------------
| **`[Sailfish]`**                   |               | not used by Dolphin
| `SortCaseSensitively`              | `false`       | bool
| `ViewMode`                         | `list`        | `list`/`gallery`/`grid`
| **`[Settings]`**                   |               |
| `HiddenFilesShown`                 | `false`       | bool
| **`[Dolphin]`**                    |               |
| `SortFoldersFirst`                 | `true`        | bool
| `SortHiddenLast`                   | `false`       | bool
| `SortOrder`                        | `0`           | `0`/`1` (`1` = reversed)
| `SortRole`                         | `name`        | `name`/`size`/`modificationtime`/`type`
| `PreviewsShown`                    | `false`       | bool
| `Version`                          | (`4`)         | (not used yet)
| `Timestamp`                        | (`yyyy,mm,dd,hh,mm,ss`) | (not used yet)


## Obsolete Settings

The following settings keys are no longer in use. See also the "Legacy key"
column in the global settings table for keys used prior to version 2.0.0 of the app.

| Key                                | Default value | Values                   | Scope         | Replaced by                 | Introduced in
|------------------------------------|---------------|--------------------------|---------------|-----------------------------|--------------
| `View/EnableGalleryMode`           | `false`       | bool                     | local, global | `View/ViewMode`             | 2.5.0
| `Sailfish/ShowDirectoriesFirst`    | `true`        | bool                     | local         | `Dolphin/SortFoldersFirst`  | 2.5.2
