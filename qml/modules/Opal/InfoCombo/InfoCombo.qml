//@ This file is part of opal-infocombo.
//@ https://github.com/Pretty-SFOS/opal-infocombo
//@ SPDX-FileCopyrightText: 2023-2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
ComboBox{id:root
property bool allowChanges:true
readonly property bool _proxyChangesAllowed:allowChanges&&enabled
property var linkHandler:function(link){Qt.openUrlExternally(link)
}
readonly property IconButton infoButton:button
signal linkActivated(var link)
rightMargin:Theme.horizontalPageMargin+Theme.iconSizeMedium
onLinkActivated:!!linkHandler&&linkHandler(link)
IconButton{id:button
enabled:root.enabled
anchors.right:parent.right
icon.source:"image://theme/icon-m-about"
Binding on highlighted{when:root.highlighted
value:true
}onClicked:{var top=[]
var bottom=[]
var items=[]
for(var i in root.children){var sec=root.children[i]
if(sec.hasOwnProperty("__is_info_combo_section")){if(sec.placeAtTop){top.push(sec)
}else{bottom.push(sec)
}}}if(root.menu){for(var j in menu._contentColumn.children){var item=menu._contentColumn.children[j]
if(item&&item.visible&&item.hasOwnProperty("__silica_menuitem")&&item.hasOwnProperty("info")){items.push({title:item.text,text:item.info,isOption:true})
}}}var page=pageStack.push(Qt.resolvedUrl("private/InfoComboPage.qml"),{title:root.label,topNotes:top,bottomNotes:bottom,items:items,allowChanges:_proxyChangesAllowed,comboBox:root})
page.linkActivated.connect(linkActivated)
}}}