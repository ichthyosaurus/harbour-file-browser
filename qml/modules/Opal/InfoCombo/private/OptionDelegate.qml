//@ This file is part of opal-infocombo.
//@ https://github.com/Pretty-SFOS/opal-infocombo
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
SilicaControl{id:root
height:column.height
width:parent.width
highlighted:false
property bool allowChanges
property ComboBox comboBox
property int modelIndex
signal linkActivated(var link)
Column{id:column
width:parent.width
TextSwitch{id:toggle
height:implicitHeight
checked:!!comboBox&&comboBox.currentIndex==modelIndex
automaticCheck:false
leftMargin:Theme.horizontalPageMargin+Theme.paddingMedium
Binding on highlighted{when:!allowChanges
value:true
}text:modelData.title
onClicked:{if(!allowChanges||!comboBox||comboBox.currentIndex==modelIndex){return
}comboBox.currentIndex=modelIndex
}}Label{id:descriptionLabel
x:Theme.horizontalPageMargin
width:parent.width-2*x
height:text.length>0?(implicitHeight+Theme.paddingMedium):0
opacity:root.enabled?1.0:Theme.opacityLow
wrapMode:Text.Wrap
font.pixelSize:Theme.fontSizeSmall
color:root.palette.secondaryHighlightColor
linkColor:highlighted?root.palette.highlightColor:root.palette.secondaryColor
onLinkActivated:root.linkActivated(link)
text:modelData.text
}}}