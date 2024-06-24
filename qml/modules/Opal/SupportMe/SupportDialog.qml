//@ This file is part of opal-supportme.
//@ https://github.com/Pretty-SFOS/opal-supportme
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
Dialog{id:root
allowedOrientations:Orientation.All
property string greeting:qsTr("Hi there!")
property string hook:qsTr("Thank you for using my little app! "+"Maybe you can contribute back?")
property string goodbye:qsTr("Thank you for your support!")
default property alias contents:contentColumn.data
signal dontAskAgain
SilicaFlickable{id:flick
anchors.fill:parent
contentHeight:column.height
VerticalScrollDecorator{flickable:flick
}Column{id:column
width:parent.width
spacing:Theme.paddingMedium
PageHeader{}Label{x:Theme.horizontalPageMargin
width:parent.width-2*x
horizontalAlignment:Text.AlignHCenter
font.pixelSize:Theme.fontSizeHuge
font.family:Theme.fontFamilyHeading
wrapMode:Text.Wrap
color:palette.highlightColor
text:greeting
}Item{width:1
height:Theme.paddingMedium
}Label{x:Theme.horizontalPageMargin
width:parent.width-2*x
color:palette.highlightColor
font.pixelSize:Theme.fontSizeMedium
wrapMode:Text.Wrap
text:hook
}Column{id:contentColumn
width:parent.width
spacing:Theme.paddingMedium
Item{width:1
height:Theme.paddingSmall
}}Item{width:1
height:2*Theme.paddingLarge
}Label{x:4*Theme.horizontalPageMargin
width:parent.width-2*x
horizontalAlignment:Text.AlignHCenter
font.pixelSize:Theme.fontSizeExtraLarge
font.family:Theme.fontFamilyHeading
wrapMode:Text.Wrap
color:palette.highlightColor
text:goodbye
}Item{width:1
height:2*Theme.paddingLarge
}ButtonLayout{preferredWidth:Theme.buttonWidthLarge
Button{text:qsTr("Remind me later")
onClicked:root.accept()
}Button{text:qsTr("Don't ask me again")
onClicked:{root.dontAskAgain()
root.accept()
}}}Item{width:1
height:2*Theme.paddingLarge
}}}}