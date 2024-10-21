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
import harbour.file.browser.Settings 1.0

TextSwitch {
    id: root

    // required config
    text: ""
    description: ""
    property string key: ''
    property var settingsContainer: GlobalSettings

    // advanced config
    property var clickHandler: defaultClickHandler
    property var defaultClickHandler: function() {
        settingsContainer[key] = !checked
    }

    // The checkedValue may be of any type, it is not
    // restricted to be only a boolean.
    // @disable-check M311
    property var checkedValue: true

    // internal
    Component.onCompleted: {
        checked = Qt.binding(function(){
            return settingsContainer[key] === checkedValue
        })
    }

    automaticCheck: false
    checked: settingsContainer[key] === checkedValue
    onClicked: {
        clickHandler()

        // this is to make sure the binding is re-evaluated
        // when the value has changed
        checked = Qt.binding(function(){
            return settingsContainer[key] === checkedValue
        })
    }
}
