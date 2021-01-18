/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
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

import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
    id: column
    width: parent.width

    signal selectionChanged(var newValue)

    property alias title: headerLabel.text
    property alias model: listView.model
    property var initial

    Label {
        id: headerLabel
        x: Theme.horizontalPageMargin
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
        height: contentHeight+Theme.paddingSmall
    }

    SilicaListView {
        id: listView
        width: parent.width
        height: childrenRect.height

        property var selectedIndex

        delegate: BackgroundItem {
            property bool selected: listView.selectedIndex === index
            height: Math.max(Theme.itemSizeSmall, itemLabel.height+2*Theme.paddingMedium)

            Label {
                id: itemLabel
                anchors.verticalCenter: parent.verticalCenter
                x: 2*Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                text: label
            }

            Binding on highlighted {
                when: selected || down
                value: true
            }

            Connections {
                target: column
                onSelectionChanged: {
                    if (value === newValue) {
                        listView.selectedIndex = index
                    }
                }
            }

            onClicked: {
                selectionChanged(value);
            }
        }
    }

    function selectInitial() {
        if (initial) {
            for (var i = 0; i < model.count; i++) {
                if (model.get(i).value === initial) {
                    listView.selectedIndex = i;
                    break;
                }
            }
        }
    }

    onInitialChanged: {
        selectInitial();
    }

    Component.onCompleted: {
        selectInitial();
    }
}
