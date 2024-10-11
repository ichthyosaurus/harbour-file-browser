//@ This file is part of opal-delegates.
//@ https://github.com/Pretty-SFOS/opal-delegates
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.5
import Sailfish.Silica 1.0
Item{id:root
width:Math.max(column.width,minWidth)
height:Math.max(parent.height,column.height)
property int minWidth:Theme.itemSizeMedium
property int fixedWidth:0
property int alignment:Qt.AlignHCenter
property int __textAlignment:{if(alignment==Qt.AlignHCenter)Text.AlignHCenter
else if(alignment==Qt.AlignLeft)Text.AlignLeft
else if(alignment==Qt.AlignRight)Text.AlignRight
else Text.AlignHCenter
}property string title
property string text
property string description
readonly property alias titleLabel:_line0
readonly property alias textLabel:_line1
readonly property alias descriptionLabel:_line2
Column{id:column
width:Math.max(_line0.width,_line1.width,_line2.width)
height:Math.max(root.parent.height,_line0.height+_line1.height+_line2.height)
anchors{horizontalCenter:parent.horizontalCenter
verticalCenter:parent.verticalCenter
}OptionalLabel{id:_line0
anchors.horizontalCenter:parent.horizontalCenter
font.pixelSize:Theme.fontSizeExtraSmall
text:root.title
palette{primaryColor:Theme.secondaryColor
highlightColor:Theme.secondaryHighlightColor
}}OptionalLabel{id:_line1
anchors.horizontalCenter:parent.horizontalCenter
font.pixelSize:Theme.fontSizeLarge
text:root.text
palette{primaryColor:Theme.primaryColor
highlightColor:Theme.highlightColor
}}OptionalLabel{id:_line2
anchors.horizontalCenter:parent.horizontalCenter
font.pixelSize:Theme.fontSizeExtraSmall
text:root.description
palette{primaryColor:Theme.secondaryColor
highlightColor:Theme.secondaryHighlightColor
}}states:[State{name:"alignLeft"
when:alignment==Qt.AlignLeft
AnchorChanges{target:column
anchors.horizontalCenter:undefined
anchors.left:parent.left
anchors.right:undefined
}PropertyChanges{target:_line0
horizontalAlignment:Text.AlignLeft
}AnchorChanges{target:_line0
anchors.horizontalCenter:undefined
anchors.left:parent.left
anchors.right:undefined
}PropertyChanges{target:_line1
horizontalAlignment:Text.AlignLeft
}AnchorChanges{target:_line1
anchors.horizontalCenter:undefined
anchors.left:parent.left
anchors.right:undefined
}PropertyChanges{target:_line2
horizontalAlignment:Text.AlignLeft
}AnchorChanges{target:_line2
anchors.horizontalCenter:undefined
anchors.left:parent.left
anchors.right:undefined
}},State{name:"alignRight"
when:alignment==Qt.AlignRight
AnchorChanges{target:column
anchors.horizontalCenter:undefined
anchors.left:undefined
anchors.right:parent.right
}PropertyChanges{target:_line0
horizontalAlignment:Text.AlignRight
}AnchorChanges{target:_line0
anchors.horizontalCenter:undefined
anchors.left:undefined
anchors.right:parent.right
}PropertyChanges{target:_line1
horizontalAlignment:Text.AlignRight
}AnchorChanges{target:_line1
anchors.horizontalCenter:undefined
anchors.left:undefined
anchors.right:parent.right
}PropertyChanges{target:_line2
horizontalAlignment:Text.AlignRight
}AnchorChanges{target:_line2
anchors.horizontalCenter:undefined
anchors.left:undefined
anchors.right:parent.right
}}]}states:[State{name:"fixedWidth"
when:fixedWidth>0
PropertyChanges{target:root
width:fixedWidth
}PropertyChanges{target:column
width:fixedWidth
}PropertyChanges{target:_line0
width:fixedWidth
wrapped:false
horizontalAlignment:_line0.metrics.width>fixedWidth?Text.AlignLeft:__textAlignment
}AnchorChanges{target:_line0
anchors.horizontalCenter:undefined
anchors.left:parent.left
}PropertyChanges{target:_line1
width:fixedWidth
wrapped:false
horizontalAlignment:_line1.metrics.width>fixedWidth?Text.AlignLeft:__textAlignment
}AnchorChanges{target:_line1
anchors.horizontalCenter:undefined
anchors.left:parent.left
}PropertyChanges{target:_line2
width:fixedWidth
wrapped:false
horizontalAlignment:_line2.metrics.width>fixedWidth?Text.AlignLeft:__textAlignment
}AnchorChanges{target:_line2
anchors.horizontalCenter:undefined
anchors.left:parent.left
}}]}