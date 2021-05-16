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

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.horizontalPageMargin
        VerticalScrollDecorator { }

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
                headerVisible: appName !== '' && pageDescription !== appName
                licenses: root.licenses
                initiallyExpanded: root.licenses.length === 1 && root.attributions.length === 0
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
                }
            }
        }
    }
}
