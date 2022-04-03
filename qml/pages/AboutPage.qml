/*
 * This file is part of harbour-file-browser.
 * SPDX-FileCopyrightText: 2021-2022 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
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

    mainAttributions: ["2019-2022 Mirian Margiani", "2013-2019 karip"]
    sourcesUrl: "https://github.com/ichthyosaurus/harbour-file-browser"
    homepageUrl: "https://forum.sailfishos.org/t/file-browser-support-and-feedback-thread/4566"
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
            name: "OSMScout Migration"
            entries: ["2021 Lukáš Karas"]
            licenses: A.License { spdxId: "GPL-2.0-or-later" }
            sources: "https://github.com/Karry/osmscout-sailfish/blob/35c12584e7016fc3651b36ef7c2b6a0898fd4ce1/src/Migration.cpp"
        },
        A.OpalAboutAttribution {}
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
                    entries: ["karip", "Tathhu", "Jyri-Petteri Paloposki"]
                },
                A.ContributionGroup {
                    title: qsTr("Chinese")
                    entries: ["Tyler Temp", "dashinfantry", "玉堂白鹤", "joe (ourmicroid)"]
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
                    entries: ["Carmen F. B.", "Lucas Peinado"]
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
                    entries: ["Sz. G", "f3rr31"]
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
                    entries: ["liimee", "Reza Almanda", "Jacque Fresco"]
                },
                A.ContributionGroup {
                    title: qsTr("Turkish")
                    entries: ["ToldYouThat", "Oğuz Ersen", "E-Akcaer"]
                }
            ]
        }
    ]
}
