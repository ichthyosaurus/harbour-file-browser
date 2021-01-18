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
    id: base
    width: parent.width
    spacing: 0

    property string label
    property var values
    property int maxEntries: -1
    property var preprocessor: function(str) { return str; }

    Repeater {
        model: maxEntries > 0 ? (maxEntries > values.length ? values.length : maxEntries) : values.length
        delegate: DetailItem {
            label: index === 0 ? base.label : ""
            value: preprocessor(values[index])
        }
    }

    Label {
        id: moreText
        visible: maxEntries > 0 && values.length > maxEntries
        text: qsTr("... and %n more", "", values.length-maxEntries)
        anchors {
            left: parent.horizontalCenter
            right: parent.right
            leftMargin: Theme.paddingSmall
            rightMargin: Theme.horizontalPageMargin
            topMargin: Theme.paddingSmall
        }
        horizontalAlignment: Text.AlignLeft
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }
}
