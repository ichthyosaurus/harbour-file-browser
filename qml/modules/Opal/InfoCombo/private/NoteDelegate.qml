//@ This file is part of opal-infocombo.
//@ https://github.com/Pretty-SFOS/opal-infocombo
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
Column{id:root
signal linkActivated(var link)
width:parent.width
spacing:Theme.paddingSmall
height:childrenRect.height
Item{width:1
height:Theme.paddingMedium
}Label{width:parent.width-2*x
x:Theme.horizontalPageMargin
horizontalAlignment:Text.AlignRight
font.pixelSize:Theme.fontSizeSmall
truncationMode:TruncationMode.Fade
color:palette.secondaryHighlightColor
linkColor:palette.secondaryColor
textFormat:Text.StyledText
height:text.length?implicitHeight:0
text:modelData.title
onLinkActivated:root.linkActivated(link)
}Label{width:parent.width-2*x
x:Theme.horizontalPageMargin
font.pixelSize:Theme.fontSizeSmall
color:palette.secondaryHighlightColor
linkColor:palette.secondaryColor
textFormat:Text.StyledText
wrapMode:Text.Wrap
text:modelData.text
onLinkActivated:root.linkActivated(link)
}}