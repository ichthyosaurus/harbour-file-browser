//@ This file is part of opal-supportme.
//@ https://github.com/Pretty-SFOS/opal-supportme
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import"private/LinkHandler"
BackgroundItem{id:root
width:parent.width
height:_body.height+2*Theme.paddingMedium
property url icon
property string title
property string description
property url link
readonly property Item bodyItem:_body
readonly property HighlightImage iconItem:_iconItem
readonly property Label titleLabel:_titleLabel
readonly property Label descriptionLabel:_descriptionLabel
readonly property bool __isLink:link!=""
Binding on palette.primaryColor{when:!__isLink
value:palette.highlightColor
}Binding on highlightedColor{when:!__isLink
value:"transparent"
}onClicked:{if(__isLink){LinkHandler.openOrCopyUrl(link)
}}Item{id:_body
x:Theme.horizontalPageMargin
width:parent.width-2*x
height:childrenRect.height
anchors.verticalCenter:parent.verticalCenter
HighlightImage{id:_iconItem
anchors{left:parent.left
top:parent.top
}Binding on highlighted{when:!__isLink
value:false
}source:root.icon
width:112
height:width
}Label{id:_titleLabel
anchors{left:iconItem.right
leftMargin:Theme.paddingLarge
right:parent.right
top:parent.top
}font.pixelSize:Theme.fontSizeLarge
wrapMode:Text.Wrap
text:root.title
}Label{id:_descriptionLabel
anchors{left:_titleLabel.left
right:_titleLabel.right
top:_titleLabel.bottom
topMargin:Theme.paddingSmall
}font.pixelSize:Theme.fontSizeExtraSmall
wrapMode:Text.Wrap
text:root.description
}}}