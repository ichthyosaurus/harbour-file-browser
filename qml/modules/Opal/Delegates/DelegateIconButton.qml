//@ This file is part of opal-delegates.
//@ https://github.com/Pretty-SFOS/opal-delegates
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
SilicaItem{id:root
property url iconSource
property alias iconSize:button.width
property alias text:label.text
property alias icon:button.icon
property alias iconButton:button
property alias textLabel:label
property Item _delegate:!!parent&&parent._delegate?parent._delegate:(__padded_delegate||null)
signal clicked(var mouse)
signal pressAndHold(var mouse)
width:Math.max(label.implicitWidth,button.width)
height:Math.max(button.height+label.effectiveHeight,(!!_delegate&&_delegate.minContentHeight?_delegate.minContentHeight:0))
highlighted:area.pressed||button.down||(!!_delegate&&_delegate.interactive&&_delegate.down)||(!!_delegate&&_delegate.menuOpen)
enabled:!!_delegate?_delegate.enabled:true
MouseArea{id:area
z:-100
anchors.fill:parent
enabled:root.enabled
onClicked:{root.clicked(mouse)
}onPressAndHold:{root.clicked(mouse)
}}SilicaItem{id:body
width:parent.width
height:button.height+label.effectiveHeight
anchors.verticalCenter:parent.verticalCenter
IconButton{id:button
width:!!iconSource.toString()?Theme.iconSizeMedium:0
height:width
anchors.horizontalCenter:parent.horizontalCenter
icon.fillMode:Image.PreserveAspectFit
icon.source:iconSource
enabled:root.enabled
onClicked:{root.clicked(mouse)
}onPressAndHold:{root.clicked(mouse)
}Binding on highlighted{when:area.pressed||root.highlighted
value:true
}}OptionalLabel{id:label
property int effectiveHeight:0
width:parent.width
font.pixelSize:Theme.fontSizeExtraSmall
fontSizeMode:Text.HorizontalFit
minimumPixelSize:0.8*Theme.fontSizeTiny
wrapped:true
highlighted:root.highlighted
horizontalAlignment:Text.AlignHCenter
anchors{top:button.bottom
topMargin:!!text?Theme.paddingSmall:0
horizontalCenter:parent.horizontalCenter
}onLineLaidOut:{if(line.isLast&&!!text){effectiveHeight=line.y+line.height+anchors.topMargin
}}Binding on effectiveHeight{when:text==""
value:0
}}}}