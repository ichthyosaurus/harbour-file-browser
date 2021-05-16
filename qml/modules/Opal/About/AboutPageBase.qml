//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2021 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import "private/functions.js" as Func
import "private"


Page {
    id: page


    property string appName: ""


    property string iconSource: ""


    property string versionNumber: ""


    property string releaseNumber: "1"


    property string description: ""


    property var mainAttributions: []


    property var authors: []


    property var __effectiveMainAttribs: Func.makeStringListConcat(authors, mainAttributions, false)


    property string sourcesUrl: ""


    property string translationsUrl: ""


    property list<License> licenses


    property list<Attribution> attributions


    readonly property DonationsGroup donations: DonationsGroup { }


    property list<InfoSection> extraSections


    property list<ContributionSection> contributionSections


    property alias flickable: _flickable


    property alias _pageHeaderItem: _pageHeader


    property alias _iconItem: _icon


    property alias _develInfoSection: _develInfo


    property alias _licenseInfoSection: _licenseInfo


    property alias _donationsInfoSection: _donationsInfo

    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: _flickable
        contentHeight: column.height
        anchors.fill: parent
        VerticalScrollDecorator { }

        onContentHeightChanged: {
            if (_flickable.contentHeight > page.height &&
                    _flickable.contentHeight - _pageHeader.origHeight +
                    Theme.paddingMedium < page.height) {
                var to = (page.height - (_flickable.contentHeight-_pageHeader.origHeight)) / 2 + Theme.paddingMedium
                if (to < paddingAnim.to) paddingAnim.to = to

                hideAnim.restart()
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: 1.5*Theme.paddingLarge

            PageHeader {
                id: _pageHeader
                property real origHeight: height
                title: qsTranslate("Opal.About", "About")
                Component.onCompleted: origHeight = height

                ParallelAnimation {
                    id: hideAnim
                    FadeAnimator {
                        target: _pageHeader
                        to: 0.0
                        duration: 80
                    }
                    SmoothedAnimation {
                        id: paddingAnim
                        target: _pageHeader
                        property: "height"
                        to: _pageHeader.origHeight
                        duration: 80
                    }
                }
            }

            Image {
                id: _icon
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeExtraLarge
                height: Theme.itemSizeExtraLarge
                fillMode: Image.PreserveAspectFit
                source: iconSource
                verticalAlignment: Image.AlignVCenter
            }

            Column {
                width: parent.width - 2*Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    visible: appName !== ""
                    text: appName
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    width: parent.width
                    visible: String(versionNumber !== "")
                    text: qsTranslate("Opal.About", "Version %1").arg(
                              (String(releaseNumber) === "1") ?
                                  versionNumber :
                                  versionNumber+"-"+releaseNumber)
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2*Theme.horizontalPageMargin
                text: description
                onLinkActivated: Qt.openUrlExternally(link)
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                horizontalAlignment: Text.AlignHCenter
                linkColor: palette.secondaryColor
                palette.primaryColor: Theme.highlightColor
            }

            InfoSection {
                id: _develInfo
                width: parent.width
                title: qsTranslate("Opal.About", "Development")
                enabled: contributionSections.length > 0 || attributions.length > 0
                text: __effectiveMainAttribs.join(', ')
                showMoreLabel: qsTranslate("Opal.About", "show contributors")
                onClicked: {
                    pageStack.animatorPush("private/ContributorsPage.qml", {
                                               'appName': appName,
                                               'sections': contributionSections,
                                               'attributions': attributions,
                                               'mainAttributions': __effectiveMainAttribs
                                           })
                }
            }

            Column {
                width: parent.width
                spacing: parent.spacing
                children: extraSections
            }

            InfoSection {
                id: _donationsInfo
                visible: donations.services.length > 0 || donations.text !== ''
                width: parent.width
                title: qsTranslate("Opal.About", "Donations")
                enabled: false
                text: donations.text === '' ? donations.defaultTextGeneral :
                                              donations.text
                __donationButtons: donations.services
            }

            InfoSection {
                id: _licenseInfo
                width: parent.width
                title: qsTranslate("Opal.About", "License")
                enabled: licenses.length > 0
                onClicked: pageStack.animatorPush("private/LicensePage.qml", {
                    'appName': appName, 'licenses': licenses, 'attributions': attributions })
                text: enabled === false ?
                          qsTranslate("Opal.About", "This is proprietary software. All rights reserved.") :
                          ((licenses[0].name !== "" && licenses[0].error !== true) ?
                               licenses[0].name : licenses[0].spdxId)
                smallPrint: licenses[0].customShortText
                showMoreLabel: qsTranslate("Opal.About", "show license(s)", "", licenses.length+attributions.length)
                buttons: [
                    InfoButton {
                        text: qsTranslate("Opal.About", "Translations")
                        onClicked: Qt.openUrlExternally(translationsUrl)
                        enabled: translationsUrl !== ''
                    },
                    InfoButton {
                        text: qsTranslate("Opal.About", "Source Code")
                        onClicked: Qt.openUrlExternally(sourcesUrl)
                        enabled: sourcesUrl !== ''
                    }
                ]

                clip: true
                Behavior on height { SmoothedAnimation { duration: 80 } }
            }

            Item {
                id: bottomVerticalSpacing
                width: parent.width
                height: Theme.paddingMedium
            }
        }
    }

    Component.onCompleted: {




        if (__silica_applicationwindow_instance &&
                __silica_applicationwindow_instance._defaultPageOrientations) {
            __silica_applicationwindow_instance._defaultPageOrientations = Orientation.All
        }
    }
}
