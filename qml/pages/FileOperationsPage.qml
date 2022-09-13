/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * File Browser is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * File Browser is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
//import harbour.file.browser.FileData 1.0
//import harbour.file.browser.Settings 1.0
import harbour.file.browser.FileOperations 1.0
import SortFilterProxyModel 0.2

import "../components"
import "../js/paths.js" as Paths

Page {
    id: root

    SortFilterProxyModel {
        id: sortedFileOps
        sourceModel: FileOperations

        sorters: [
            FilterSorter {
                filters: ValueFilter {
                    roleName: "status"
                    value: FileOpStatus.Finished
                    inverted: true
                }
            },
            RoleSorter {
                roleName: "handle"
                ascendingOrder: false
            }

        ]
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: sortedFileOps

        header: PageHeader {
            id: head
            title: qsTr("Tasks")
        }

        VerticalScrollDecorator { flickable: list }

        delegate: ListItem {
            id: item
            width: ListView.view.width
            contentHeight: Theme.itemSizeMedium

            Label {
                anchors {
                    fill: parent
                    margins: Theme.horizontalPageMargin
                }
                text: "handle: %1, status: %2, files: %3".arg(model.handle).arg(model.status).arg(model.files)
            }
        }

        ViewPlaceholder {
            enabled: FileOperations.count === 0
            text: qsTr("Empty")
            hintText: "" // TODO
        }
    }
}
