//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2021 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
Page{id:root
property url externalUrl
property string title:""
allowedOrientations:Orientation.All
Column{width:parent.width
spacing:(root.orientation&Orientation.LandscapeMask&&Screen.sizeCategory<=Screen.Medium)?Theme.itemSizeExtraSmall:Theme.itemSizeSmall
y:(root.orientation&Orientation.LandscapeMask&&Screen.sizeCategory<=Screen.Medium)?Theme.paddingLarge:Theme.itemSizeExtraLarge
Label{text:title?title:qsTranslate("Opal.About","External Link")
width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignHCenter
color:Theme.highlightColor
font.pixelSize:Theme.fontSizeExtraLarge
wrapMode:Text.Wrap
}Label{text:externalUrl
width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignHCenter
color:Theme.highlightColor
font.pixelSize:Theme.fontSizeMedium
wrapMode:Text.Wrap
}}ButtonLayout{preferredWidth:Theme.buttonWidthMedium
anchors{bottom:parent.bottom
bottomMargin:(root.orientation&Orientation.LandscapeMask&&Screen.sizeCategory<=Screen.Medium)?Theme.itemSizeExtraSmall:Theme.itemSizeMedium
}Button{text:qsTranslate("Opal.About","Open in browser")
onClicked:{Qt.openUrlExternally(externalUrl)
pageStack.pop()
}}Button{Notification{id:copyNotification
previewSummary:qsTranslate("Opal.About","Copied to clipboard: %1").arg(externalUrl)
isTransient:true
appIcon:"icon-lock-information"
icon:"icon-lock-information"
}ButtonLayout.newLine:true
text:qsTranslate("Opal.About","Copy to clipboard")
onClicked:{Clipboard.text=externalUrl
copyNotification.publish()
pageStack.pop()
}}}}