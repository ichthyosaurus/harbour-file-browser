/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2021 Mirian Margiani
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
import Sailfish.Silica 1.0 as S
import "../modules/Opal/About" as A

A.AboutPageBase {
    id: page
    allowedOrientations: S.Orientation.All

    appName: "File Browser"
    appIcon: Qt.resolvedUrl("../images/harbour-file-browser.png")
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    appReleaseType: RELEASE_TYPE
    description: qsTr("A fully-fledged file manager for Sailfish OS.")

    mainAttributions: ["Mirian Margiani", "karip"]
    sourcesUrl: "https://github.com/ichthyosaurus/harbour-file-browser"
    translationsUrl: "https://hosted.weblate.org/projects/harbour-file-browser/main-translations/"

    licenses: A.License { spdxId: "GPL-3.0-or-later" }
    attributions: [
        A.Attribution {
            name: "JHead"
            entries: ["Matthias Wandel", qsTr("adapted by karip")]
            licenses: A.License { spdxId: "GPL-3.0-or-later" }
        },
        A.Attribution {
            name: "SortFilterProxyModel"
            entries: ["2016 Pierre-Yves Siret"]
            licenses: A.License { spdxId: "MIT" }
        },
        A.Attribution {
            name: "Opal.About"
            entries: "2018-2021 Mirian Margiani"
            licenses: A.License { spdxId: "GPL-3.0-or-later" }
        }
    ]

    /* donations.text: donations.defaultTextCoffee
    donations.services: A.DonationService {
        name: "LiberaPay"
        url: "https://liberapay.com/ichthyosaurus/"
    } */

    contributionSections: [
        A.ContributionSection {
            title: qsTr("Development")
            groups: [
                A.ContributionGroup {
                    title: qsTr("Programming")
                    entries: ["Mirian Margiani", "karip", "Joona Petrell",
                        "Michael Faro-Tusino", "Alin Marin Elena", "jklingen",
                        "Benna", "Malte Veerman", "Marcin Mielniczuk", "Arusekk"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Icon Design")
                    entries: ["Sailfish (Jolla)", "karip", "Mirian Margiani"]
                }
            ]
        },
        A.ContributionSection {
            title: qsTr("Translations")
            groups: [
                A.ContributionGroup {
                    title: qsTr("English")
                    entries: ["karip", "Mirian Margiani"]
                },
                A.ContributionGroup {
                    title: qsTr("German")
                    entries: ["jklingen", "karip", "Mirian Margiani"]
                },
                A.ContributionGroup {
                    title: qsTr("Finnish")
                    entries: ["karip", "Tathhu"]
                },
                A.ContributionGroup {
                    title: qsTr("Chinese")
                    entries: ["Tyler Temp", "dashinfantry", "玉堂白鹤"]
                },
                A.ContributionGroup {
                    title: qsTr("Russian")
                    entries: ["Petr Tsymbarovich"]
                },
                A.ContributionGroup {
                    title: qsTr("Swedish")
                    entries: ["Åke Engelbrektson"]
                },
                A.ContributionGroup {
                    title: qsTr("Italian")
                    entries: ["Tichy"]
                },
                A.ContributionGroup {
                    title: qsTr("Spanish")
                    entries: ["Carmen F. B."]
                },
                A.ContributionGroup {
                    title: qsTr("French")
                    entries: ["Quent-in (Quentí)", "karip", "J. Lavoie", "K. Herbert"]
                },
                A.ContributionGroup {
                    title: qsTr("Dutch")
                    entries: ["Nathan Follens"]
                },
                A.ContributionGroup {
                    title: qsTr("Greek")
                    entries: ["Dimitrios Glentadakis"]
                },
                A.ContributionGroup {
                    title: qsTr("Norwegian")
                    entries: ["Bokmål: Allan Nordhøy"]
                },
                A.ContributionGroup {
                    title: qsTr("Czech")
                    entries: ["Malakay X"]
                },
                A.ContributionGroup {
                    title: qsTr("Slovak")
                    entries: ["Ladislav Hodas"]
                },
                A.ContributionGroup {
                    title: qsTr("Hungarian")
                    entries: ["Sz. G"]
                },
                A.ContributionGroup {
                    title: qsTr("Estonian")
                    entries: ["Priit Jõerüüt"]
                },
                A.ContributionGroup {
                    title: qsTr("Polish")
                    entries: ["Patryk Szkudlarek"]
                },
                A.ContributionGroup {
                    title: qsTr("Indonesian")
                    entries: ["liimee"]
                }
            ]
        }
    ]
}
