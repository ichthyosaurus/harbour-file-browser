/*
 * This file asks for your support.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024-2025 Mirian Margiani
 */

import QtQuick 2.0
import Opal.SupportMe 1.0

SupportDialog {
    SupportAction {
        icon: SupportIcon.Liberapay
        title: qsTr("Donate on %1").arg("Liberapay")
        description: qsTr("Pay the amount of a cup of coffee, a slice " +
                          "of pizza, or a ticket to the theater.")
        link: "https://liberapay.com/ichthyosaurus"
    }

    SupportAction {
        icon: SupportIcon.Weblate
        title: qsTr("Translate on %1").arg("Weblate")
        description: qsTr("Help with translating this app in as many " +
                          "languages as possible.")
        link: "https://hosted.weblate.org/projects/harbour-file-browser"
    }

    SupportAction {
        icon: SupportIcon.Git
        title: qsTr("Develop on %1").arg("GitHub")
        description: qsTr("Support with maintenance and packaging, " +
                          "write code, or provide valuable bug reports.")
        link: "https://github.com/ichthyosaurus/harbour-file-browser"
    }

    DetailsDrawer {
        title: qsTr("Why should you care?")

        DetailsParagraph {
            text: qsTr("This project is built with love and passion by a " +
                       "single developer in their spare time, and is provided " +
                       "to you free of charge.")
        }

        DetailsParagraph {
            text: qsTr("I develop Free Software because I am convinced that " +
                       "it is the ethical thing to do - and it is a fun hobby. " +
                       "However, developing software takes a lot of time and effort. " +
                       "As Sailfish and living in general costs money, I need your " +
                       "support to be able to spend time on non-paying projects " +
                       "like this.")
        }
    }

    DetailsDrawer {
        title: qsTr("Why donate?")

        DetailsParagraph {
            text: qsTr("If you can afford it, donating is the easiest way " +
                       "to ensure that I can continue working on apps " +
                       "for Sailfish. Any amount is appreciated, be it a cup " +
                       "of coffee, a slice of pizza, or more.")
        }
    }
}
