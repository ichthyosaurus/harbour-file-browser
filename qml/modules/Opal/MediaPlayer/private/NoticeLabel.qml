//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
SilicaItem{id:root
property bool shown:false
property alias text:label.text
property int fontSize:Theme.fontSizeMedium
property alias label:label
property int padding:Theme.paddingMedium
function show(){shown=true
}function hide(){shown=false
}palette.colorScheme:Theme.LightOnDark
width:label.width+2*padding
height:label.height+2*padding
visible:opacity>0.0
Rectangle{color:"black"
opacity:0.4
anchors.centerIn:parent
radius:5
anchors.fill:parent
}Label{id:label
width:implicitWidth
height:implicitHeight
anchors.centerIn:parent
font.pixelSize:root.fontSize
color:Theme.lightPrimaryColor
}states:[State{name:"shown"
when:shown
PropertyChanges{target:root
opacity:1.0
}},State{name:"hidden"
when:!shown
PropertyChanges{target:root
opacity:0.0
}}]transitions:[Transition{from:"hidden"
to:"shown"
animations:SequentialAnimation{PauseAnimation{duration:1000
}ScriptAction{script:root.hide()
}}},Transition{from:"shown"
to:"hidden"
animations:NumberAnimation{property:"opacity"
easing.type:Easing.InOutQuad
}}]}