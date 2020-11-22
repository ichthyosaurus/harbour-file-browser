# Settings

## Global Settings

| Key                                | Default value | Allowed values                                        | Legacy key (in `[General]`)
|------------------------------------|---------------|-----------------------------------------------|-------------------------
| **`[General]`**                    |               |                                               |
| `DefaultFilterAction`              | `filter`      | `filter`/`search`                             |
| `ShowFullDirectoryPaths`           | `false`       | bool                                          |
| **`[Transfer]`**                   |               |                                               |
| `DefaultAction`                    | `none`        | `copy`/`move`/`link`/`none`                   | `default-transfer-action`
| **`[View]`**                       |               |                                               |
| `SortRole`                         | `name`        | `name`/`size`/`modificationtime`/`type`       | `listing-sort-by`
| `SortOrder`                        | `default`     | `default`/`reversed`                          | `listing-order`
| `SortCaseSensitively`              | `false`       | bool                                          | `sort-case-sensitive`
| `ShowDirectoriesFirst`             | `true`        | bool                                          | `show-dirs-first`
| `HiddenFilesShown`                 | `false`       | bool                                          | `show-hidden-files`
| `PreviewsShown`                    | `false`       | bool                                          | `show-thumbnails`
| `PreviewsSize`                     | `medium`      | `small`/`medium`/`large`/`huge`               | `thumbnails-size`
| `UseLocalSettings`                 | `true`        | bool                                          | `use-local-view-settings`
| `EnableGalleryMode`                | `false`       | bool                                          |
| **`[Bookmarks]`**                  |               |                                               |
| `Entries="[\"...\"]"`              |               | ordered array of paths as JSON strings (this field saves only the order of elements, not the elements themselves) | `bookmark-entries`
| `home#nemo#Devel=Devel`            |               | `path=bookmark name` for each bookmark (with all `/` replaced by `#` to distinguish them from settings groups) |


## Local Settings

Local settings are read from a hidden file named `.directory` in the current directory.
They use the same entries as [KDE](https://kde.org)'s file manager
[Dolphin](https://apps.kde.org/en/dolphin).

| Key                                | Default value | Values
|------------------------------------|---------------|-----------------------------------------------
| **`[Sailfish]`**                   |               | not used by Dolphin
| `ShowDirectoriesFirst`             | `true`        | bool
| `SortCaseSensitively`              | `false`       | bool
| `EnableGalleryMode`                | `false`       | bool
| **`[Settings]`**                   |               |
| `HiddenFilesShown`                 | `false`       | bool
| **`[Dolphin]`**                    |               |
| `SortOrder`                        | `0`           | `0`/`1` (`1` = reversed)
| `SortRole`                         | `name`        | `name`/`size`/`modificationtime`/`type`
| `PreviewsShown`                    | `false`       | bool
| `Version`                          | (`4`)         | (not used yet)
| `Timestamp`                        | (`yyyy,mm,dd,hh,mm,ss`) | (not used yet)
