/*
 * This file is part of harbour-file-browser.
 * SPDX-FileCopyrightText: 2021-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/*
 * Translators:
 * Please add yourself to the list of contributors below. If your language is already
 * in the list, add your name to the 'entries' field. If you added a new translation,
 * create a new section at the top of the list.
 *
 * Other contributors:
 * Please add yourself to the relevant list of contributors.
 *
 * <...>
 *  ContributionGroup {
 *      title: qsTr("Your language")
 *      entries: ["Existing contributor", "YOUR NAME HERE"]
 *  },
 * <...>
 *
 */

import QtQuick 2.0
import Sailfish.Silica 1.0 as S
import "../modules/Opal/About" as A
import "../modules/Opal/Attributions"

A.AboutPageBase {
    id: root

    appName: "File Browser"
    appIcon: Qt.resolvedUrl("../images/%1.png".arg(Qt.application.name))
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    appReleaseType: RELEASE_TYPE

    allowDownloadingLicenses: false
    sourcesUrl: "https://github.com/ichthyosaurus/%1".arg(Qt.application.name)
    homepageUrl: "https://forum.sailfishos.org/t/file-browser-support-and-feedback-thread/4566"
    translationsUrl: "https://hosted.weblate.org/projects/%1".arg(Qt.application.name)
    licenses: A.License { spdxId: "GPL-3.0-or-later" }

    donations.text: donations.defaultTextCoffee
    donations.services: [
        A.DonationService {
            name: "Liberapay"
            url: "https://liberapay.com/ichthyosaurus"
        }
    ]

    description: qsTr("A fully-fledged file manager for Sailfish OS.")
    mainAttributions: ["2019-2024 Mirian Margiani", "2013-2019 karip"]

    attributions: [
        A.Attribution {
            name: "JHead (2.97)"
            entries: ["Matthias Wandel", /*qsTr*/("2014 adapted by karip"), /*qsTr*/("2021 adapted by ichthyosaurus")]
            licenses: A.License { spdxId: "GPL-3.0-or-later" }
            sources: "https://www.sentex.net/~mwandel/jhead/"
        },
        A.Attribution {
            name: "SortFilterProxyModel"
            entries: ["2016 Pierre-Yves Siret"]
            licenses: A.License { spdxId: "MIT" }
            sources: "https://github.com/oKcerG/SortFilterProxyModel"
        },
        A.Attribution {
            name: "OSMScout Migration"
            entries: ["2021 Lukáš Karas"]
            licenses: A.License { spdxId: "GPL-2.0-or-later" }
            sources: "https://github.com/Karry/osmscout-sailfish/blob/35c12584e7016fc3651b36ef7c2b6a0898fd4ce1/src/Migration.cpp"
        },
        A.Attribution {
            name: "PatchManager List View"
            entries: ["2018 Coderus"]
            licenses: A.License { spdxId: "BSD-3-Clause" }
            sources: "https://github.com/sailfishos-patches/patchmanager"
        },
        OpalAboutAttribution {},
        OpalInfoComboAttribution {},
        OpalComboDataAttribution {}
    ]

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
                    entries: ["Tyler Temp", "dashinfantry", "玉堂白鹤", "joe (ourmicroid)", "yangyangdaji"]
                },
                A.ContributionGroup {
                    title: qsTr("Ukrainian")
                    entries: ["Tymofii Lytvynenko", "mihajlo0743", "Artem"]
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
                    entries: ["Quent-in (Quentí)", "karip", "J. Lavoie", "K. Herbert", "Maxime Leroy"]
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
                },
                A.ContributionGroup {
                    title: qsTr("Russian")
                    entries: ["Petr Tsymbarovich", "Evgeniy Khramov"]
                }
            ]
        }
    ]
}
