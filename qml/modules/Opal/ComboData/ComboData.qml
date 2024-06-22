//@ This file is part of opal-combodata.
//@ https://github.com/Pretty-SFOS/opal-combodata
//@ SPDX-FileCopyrightText: 2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
Item{property var comboBox:!!parent&&!!parent.parent?parent.parent:null
property string dataRole:"text"
readonly property var currentData:!!_currentItem?_currentItem[dataRole]:null
function indexOfData(data){if(!_menu){return-1
}var children=_menu._contentColumn.children
var menuIndex=-1
for(var i in children){var child=children[i]
if(!!child&&child.hasOwnProperty("__silica_menuitem")){menuIndex+=1
if(child[dataRole]===data){return menuIndex
}}}return-1
}function reset(data){if(!_menu||!comboBox){console.error("[Opal.ComboData] Cannot reset current index because "+"no menu or ComboBox is available.")
return
}comboBox.currentIndex=indexOfData(data)
}readonly property var _menu:!!comboBox?comboBox.menu:null
readonly property var _currentItem:!!comboBox&&!!comboBox.currentItem?comboBox.currentItem:null
function _checkCombo(){if(!comboBox||!comboBox.hasOwnProperty("menu")||!comboBox.hasOwnProperty("currentItem")){console.error("[Opal.ComboData] ComboData must be a direct child "+"of a ComboBox (or derived type), or you must set the "+"“comboBox” property to a valid value.")
console.log(comboBox,comboBox.parent.parent)
return
}if(comboBox.hasOwnProperty("currentData")){comboBox.currentData=Qt.binding(function(){return currentData
})
}if(comboBox.hasOwnProperty("indexOfData")){comboBox.indexOfData=Qt.binding(function(){return indexOfData
})
}}onComboBoxChanged:_checkCombo()
onParentChanged:_checkCombo()
Component.onCompleted:_checkCombo()
}