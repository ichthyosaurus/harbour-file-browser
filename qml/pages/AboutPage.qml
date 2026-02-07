/*
 * This file is part of harbour-file-browser.
 * SPDX-FileCopyrightText: 2021-2026 Mirian Margiani
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
    objectName: "AboutPage"

    appName: "File Browser"
    appIcon: Qt.resolvedUrl("../images/%1.png".arg(Qt.application.name))
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    appReleaseType: RELEASE_TYPE

    sourcesUrl: "https://github.com/ichthyosaurus/%1".arg(Qt.application.name)
    homepageUrl: "https://forum.sailfishos.org/t/file-browser-support-and-feedback-thread/4566"
    translationsUrl: "https://hosted.weblate.org/projects/%1".arg(Qt.application.name)
    changelogList: Qt.resolvedUrl("../Changelog.qml")
    licenses: A.License { spdxId: "GPL-3.0-or-later" }

    donations.text: donations.defaultTextCoffee
    donations.services: [
        A.DonationService {
            name: "Liberapay"
            url: "https://liberapay.com/ichthyosaurus"
        }
    ]

    description: qsTr("A fully-fledged file manager for Sailfish OS.")
    mainAttributions: ["2019-%1 Mirian Margiani".arg((new Date()).getFullYear()), "2013-2019 karip"]

    attributions: [
        A.Attribution {
            name: "JHead (2.97)"
            entries: ["Matthias Wandel", /*qsTr*/("2014 adapted by karip"), /*qsTr*/("2021 adapted by ichthyosaurus")]
            licenses: A.License { spdxId: "GPL-3.0-or-later" }
            sources: "https://www.sentex.net/~mwandel/jhead/"
        },
        A.Attribution {
            name: "OSMScout Migration"
            entries: ["2021 Lukáš Karas"]
            licenses: A.License { spdxId: "GPL-2.0-or-later" }
            sources: "https://github.com/Karry/osmscout-sailfish/blob/35c12584e7016fc3651b36ef7c2b6a0898fd4ce1/src/Migration.cpp"
        }
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
        //>>> GENERATED LIST OF TRANSLATION CREDITS
        A.ContributionSection {
            title: qsTr("Translations")
            groups: [
                A.ContributionGroup {
                    title: qsTr("Ukrainian")
                    entries: [
                        "Artem",
                        "Bohdan Kolesnyk",
                        "Dan",
                        "Tymofii Lytvynenko",
                        "mihajlo0743",
                        "Максим Горпиніч"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Turkish")
                    entries: [
                        "Burak Hüseyin Ekseli",
                        "E-Akcaer",
                        "Oğuz Ersen",
                        "TCr3",
                        "ToldYouThat",
                        "Turker",
                        "İbrahim Dinç"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Tamil")
                    entries: [
                        "தமிழ்நேரம்"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Swedish")
                    entries: [
                        "Allan Nordhøy",
                        "Luna Jernberg",
                        "bittin1ddc447d824349b2",
                        "Åke Engelbrektson"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Spanish")
                    entries: [
                        "Carmen F. B.",
                        "Francisco Serrador",
                        "Jaime Marquínez Ferrándiz",
                        "Lucas Peinado",
                        "lucasengithub"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Slovak")
                    entries: [
                        "Ladislav Hodas",
                        "Milan Šalka"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Serbian")
                    entries: [
                        "dex girl"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Russian")
                    entries: [
                        "Evgeniy Khramov",
                        "Lilia Savciuc",
                        "Mika",
                        "Petr Tsymbarovich",
                        "Romeostar",
                        "RoundedRectangle",
                        "Victor K",
                        "Yurt Page",
                        "gfbdrgn",
                        "sandworm88"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Romanian")
                    entries: [
                        "Florin Voicu"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Portuguese")
                    entries: [
                        "ssantos"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Polish")
                    entries: [
                        "Eryk Michalak",
                        "J3Extreme",
                        "Patryk Szkudlarek",
                        "neloduka-sobe",
                        "senza"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Norwegian Bokmål")
                    entries: [
                        "Allan Nordhøy",
                        "Frank Paul Silye"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Italian")
                    entries: [
                        "Mauro Scomparin",
                        "Tichy",
                        "luca rastelli"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Indonesian")
                    entries: [
                        "Arif Budiman",
                        "Jacque Fresco",
                        "Reza Almanda",
                        "itsfihanni",
                        "liimee"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Hungarian")
                    entries: [
                        "Gergely Turi",
                        "Sz. G.",
                        "f3rr31"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Greek")
                    entries: [
                        "Dimitrios Glentadakis"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("German")
                    entries: [
                        "Mirian Margiani",
                        "Phil Jope",
                        "jklingen",
                        "karip"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("French")
                    entries: [
                        "David D.",
                        "J. Lavoie",
                        "Jerome M",
                        "K. Herbert",
                        "Laurent FAVOLE",
                        "Maxime Leroy",
                        "Mirian Margiani",
                        "Quent-in (Quentí)",
                        "karip"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Finnish")
                    entries: [
                        "Elmeri Länsiharju",
                        "Jyri-Petteri Paloposki",
                        "Lassi Määttä",
                        "Tathhu",
                        "karip"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Estonian")
                    entries: [
                        "Priit Jõerüüt"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("English")
                    entries: [
                        "Allan Nordhøy",
                        "Mirian Margiani",
                        "karip"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Dutch (Belgium)")
                    entries: [
                        "Nathan Follens"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Dutch")
                    entries: [
                        "Anna Wolf",
                        "Nathan Follens",
                        "Pieter Bikkel"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Czech")
                    entries: [
                        "Jiří Vírava",
                        "Malakay X",
                        "Michal Čihař"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Chinese")
                    entries: [
                        "Jason Cai",
                        "Tyler Temp",
                        "dashinfantry",
                        "joe (ourmicroid)",
                        "petter0011",
                        "yangyangdaji",
                        "复予",
                        "玉堂白鹤"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Brazilian Portuguese")
                    entries: [
                        "John Peter Sa",
                        "Mateus Liberale Gomes",
                        "Thiago Carmona"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Belarusian")
                    entries: [
                        "Toha"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Arabic")
                    entries: [
                        "Moayad Ibrahim"
                    ]
                }
            ]
        }
        //<<< GENERATED LIST OF TRANSLATION CREDITS
    ]
}
