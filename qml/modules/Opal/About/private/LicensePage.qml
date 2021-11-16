//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2021 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: root
    property list<License> licenses
    property list<Attribution> attributions
    property bool enableSourceHint: true
    property alias pageDescription: pageHeader.description
    property string appName
    property string mainSources
    property string mainHomepage

    allowedOrientations: Orientation.All

    function _downloadLicenses() {
        for (var lic in licenses) {
            licenses[lic].__online = true
        }

        for (var attr in attributions) {
            for (var lic in attributions[attr].licenses) {
                attributions[attr].licenses[lic].__online = true
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { }

        PullDownMenu {
            MenuItem {
                text: qsTranslate("Opal.About", "Download license texts")
                onClicked: _downloadLicenses()
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: pageHeader
                title: qsTranslate("Opal.About", "License(s)", "", licenses.length+attributions.length)
                description: appName
            }

            Label {
                visible: enableSourceHint
                width: parent.width - 2*Theme.horizontalPageMargin
                height: visible ? implicitHeight + Theme.paddingLarge : 0
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
                text: qsTranslate("Opal.About", "Note: please check the source code for most accurate information.")
            }

            LicenseListPart {
                visible: root.licenses.length > 0
                title: appName
                headerVisible: appName !== '' && root.attributions.length > 0
                licenses: root.licenses
                initiallyExpanded: root.licenses.length === 1 && root.attributions.length === 0
                homepage: mainHomepage
                sources: mainSources
            }

            Repeater {
                model: attributions
                delegate: LicenseListPart {
                    title: modelData.name
                    headerVisible: title !== '' && pageDescription !== title
                    licenses: modelData.licenses
                    extraTexts: modelData.__effectiveEntries
                    initiallyExpanded: root.licenses.length === 0 &&
                                       root.attributions.length === 1 &&
                                       root.attributions[0].licenses.length === 1
                    homepage: modelData.homepage
                    sources: modelData.sources
                }
            }
        }
    }
}
