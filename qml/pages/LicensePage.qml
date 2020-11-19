/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2013 Michael Faro-Tusino
 * SPDX-FileCopyrightText: 2016 Joona Petrell
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

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            x: Theme.horizontalPageMargin
            width: parent.width - x

            PageHeader { title: qsTr("License") }

            SectionHeader {
                text: "Beta Releases"
            }

            Label {
                width: parent.width-parent.x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                text: "This beta release is licensed under the terms of the GNU General Public License. "+
                      "All earlier versions were released into the Public Domain. "+
                      "\n\n"+
                      "This program is free software: you can redistribute it and/or modify "+
                      "it under the terms of the GNU General Public License as published by "+
                      "the Free Software Foundation, either version 3 of the License, or "+
                      "(at your option) any later version. "+
                      "\n\n"+
                      "This program is distributed in the hope that it will be useful, "+
                      "but WITHOUT ANY WARRANTY; without even the implied warranty of "+
                      "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "+
                      "GNU General Public License for more details. "+
                      "\n\n"+
                      "You should have received a copy of the GNU General Public License "+
                      "along with this program.  If not, see <https://www.gnu.org/licenses/>."
            }

            Item {
                id: verticalSpacing
                width: parent.width
                height: 2*Theme.paddingLarge
            }

            SectionHeader {
                text: "Jolla Store Releases"
            }

            Label {
                width: parent.width-parent.x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                text: "This is free and unencumbered software released into the public domain."+
                      "\n\n"+
                      "Anyone is free to copy, modify, publish, use, compile, sell, or "+
                      "distribute this software, either in source code form or as a compiled "+
                      "binary, for any purpose, commercial or non-commercial, and by any "+
                      "means."+
                      "\n\n"+
                      "In jurisdictions that recognize copyright laws, the author or authors "+
                      "of this software dedicate any and all copyright interest in the "+
                      "software to the public domain. We make this dedication for the benefit "+
                      "of the public at large and to the detriment of our heirs and "+
                      "successors. We intend this dedication to be an overt act of "+
                      "relinquishment in perpetuity of all present and future rights to this "+
                      "software under copyright law."+
                      "\n\n"+
                      "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, "+
                      "EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF "+
                      "MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. "+
                      "IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR "+
                      "OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, "+
                      "ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR "+
                      "OTHER DEALINGS IN THE SOFTWARE."+
                      "\n\n"+
                      "For more information, please refer to <http://unlicense.org>."
            }
        }
    }
}
