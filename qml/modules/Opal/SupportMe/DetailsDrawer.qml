//@ This file is part of opal-supportme.
//@ https://github.com/Pretty-SFOS/opal-supportme
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
BackgroundItem{id:root
width:parent.width
height:(isOpen||!_canOpen?openHeight:_actualClosedHeight)+extraHeight
property alias title:titleField.text
default property alias content:contentBody.data
property bool isOpen:false
property int closedHeight:1.5*Theme.itemSizeHuge
readonly property int _actualClosedHeight:Math.min(closedHeight,openHeight)
readonly property bool _canOpen:_actualClosedHeight>=closedHeight
readonly property int openHeight:contentColumn.height
readonly property int extraHeight:footer.height
highlightedColor:"transparent"
palette.highlightColor:down&&_canOpen?Theme.secondaryHighlightColor:Theme.highlightColor
onClicked:{isOpen=!isOpen
}OpacityRampEffect{enabled:_canOpen&&!root.isOpen
sourceItem:contentItem
direction:OpacityRamp.TopToBottom
}Item{id:contentItem
clip:true
width:parent.width
height:root.isOpen||!_canOpen?root.openHeight:root._actualClosedHeight
Behavior on height{animation:NumberAnimation{duration:80
}}Column{id:contentColumn
x:Theme.horizontalPageMargin
width:parent.width-2*x
spacing:Theme.paddingMedium
SectionHeader{id:titleField
x:0
Binding on height{when:titleField.text===""
value:0
}}Column{id:contentBody
width:parent.width
spacing:Theme.paddingMedium
}Item{width:1
height:1
}}}Item{id:footer
visible:_canOpen
x:Theme.horizontalPageMargin
width:parent.width-2*x
anchors.top:contentItem.bottom
height:visible?Theme.itemSizeExtraSmall:0
Row{spacing:Theme.paddingMedium
anchors{verticalCenter:parent.verticalCenter
right:parent.right
}Label{id:showMoreLabel
font.pixelSize:Theme.fontSizeExtraSmall
font.italic:true
text:root.isOpen?qsTr("show less"):qsTr("show more")
}Label{anchors.verticalCenter:showMoreLabel.verticalCenter
text:"• • •"
}}}}