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
import "../components"

Page {
    allowedOrientations: Orientation.All

    // update cover
    onStatusChanged: if (status === PageStatus.Activating) main.coverText = qsTr("Contributors")

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + 2*Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Contributors") }

            SectionHeader { text: qsTr("Development") }

            DetailList {
                label: qsTr("Programming")
                values: ["Mirian Margiani", "karip", "Joona Petrell",
                    "Michael Faro-Tusino", "Alin Marin Elena", "jklingen",
                    "Benna", "Malte Veerman", "Marcin Mielniczuk"
                ]
            }

            DetailList {
                label: qsTr("Icon Design")
                values: ["Sailfish (Jolla)", "karip", "Mirian Margiani"]
            }

            SectionHeader { text: qsTr("Translations") }

            DetailList {
                label: qsTr("English")
                values: ["karip", "Mirian Margiani"]
            }
            DetailList {
                label: qsTr("German")
                values: ["jklingen", "karip", "Mirian Margiani"]
            }
            DetailList {
                label: qsTr("Finnish")
                values: ["karip", "Tathhu"]
            }
            DetailList {
                label: qsTr("Chinese")
                values: ["Tyler Temp", "dashinfantry"]
            }
            DetailList {
                label: qsTr("Russian")
                values: ["Petr Tsymbarovich"]
            }
            DetailList {
                label: qsTr("Swedish")
                values: ["Åke Engelbrektson"]
            }
            DetailList {
                label: qsTr("Italian")
                values: ["Tichy"]
            }
            DetailList {
                label: qsTr("Spanish")
                values: ["Carmen F. B."]
            }
            DetailList {
                label: qsTr("French")
                values: ["Quent-in (Quentí)", "karip", "J. Lavoie", "K. Herbert"]
            }
            DetailList {
                label: qsTr("Dutch")
                values: ["Nathan Follens"]
            }
            DetailList {
                label: qsTr("Greek")
                values: ["Dimitrios Glentadakis"]
            }
            DetailList {
                label: qsTr("Norwegian Bokmål")
                values: ["Allan Nordhøy"]
            }
        }
    }
}
