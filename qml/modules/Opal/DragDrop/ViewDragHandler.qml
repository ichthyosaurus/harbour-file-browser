//@ This file is part of opal-dragdrop.
//@ https://github.com/Pretty-SFOS/opal-dragdrop
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
Item{id:root
property Item listView
property Flickable flickable:!!listView?listView:null
property QtObject smartScrollbar
property bool active:!!listView
property bool handleMove:true
property int listViewCacheBuffer:20*Screen.height
signal itemMoved(var fromIndex,var toIndex)
signal itemDropped(var originalIndex,var currentIndex,var finalIndex)
property Item _draggedItem
property int _originalIndex:-1
readonly property bool _scrolling:scrollUpTimer.running||scrollDownTimer.running
readonly property int _minimumFlickableY:{if(!flickable||!listView||!_draggedItem)return 0
if(flickable===listView){return!!listView.headerItem?-listView.headerItem.height:0
}else{var base=flickable.contentY+listView.mapToItem(flickable,0,0).y
return base-_draggedItem.height*3/2
}}readonly property int _maximumFlickableY:{if(!flickable||!listView||!_draggedItem)return 0
if(flickable===listView){return listView.contentHeight-listView.height-(!!listView.headerItem?listView.headerItem.height:0)
}else{var base=flickable.contentY+listView.mapToItem(flickable,0,0).y+listView.height-flickable.height
return Math.min(base+_draggedItem.height,flickable.contentHeight)
}}readonly property bool __opal_view_drag_handler:true
function _scrollUp(){scrollUpTimer.start()
scrollDownTimer.stop()
}function _scrollDown(){scrollUpTimer.stop()
scrollDownTimer.start()
}function _stopScrolling(){scrollUpTimer.stop()
scrollDownTimer.stop()
}function _setListViewProperties(){if(!listView)return
listView.moveDisplaced=moveDisplaced
}onItemMoved:{if(!handleMove)return
listView.model.move(fromIndex,toIndex,1)
}onListViewChanged:{_setListViewProperties()
}onListViewCacheBufferChanged:{if(!!listView&&listView.hasOwnProperty("cacheBuffer")&&listViewCacheBuffer>0){listView.cacheBuffer=listViewCacheBuffer
}}implicitWidth:0
implicitHeight:0
Binding{target:smartScrollbar
property:"smartWhen"
value:false
when:!!flickable&&root.active
}Transition{id:moveDisplaced
NumberAnimation{properties:"x,y"
duration:200
easing.type:Easing.InOutQuad
}}Timer{id:scrollUpTimer
repeat:true
interval:10
onTriggered:{if(!_draggedItem){stop()
return
}if(flickable.contentY>_minimumFlickableY){flickable.contentY-=15
if(flickable!==listView){_draggedItem.y-=15
}}else{stop()
}}}Timer{id:scrollDownTimer
repeat:true
interval:10
onTriggered:{if(!_draggedItem){stop()
return
}if(flickable.contentY<_maximumFlickableY){flickable.contentY+=15
if(flickable!==listView){_draggedItem.y+=15
}}else{stop()
}}}Component.onCompleted:{_setListViewProperties()
}}