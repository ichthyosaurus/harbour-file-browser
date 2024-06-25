//@ This file is part of opal-supportme.
//@ https://github.com/Pretty-SFOS/opal-supportme
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
Item{id:root
property int interval:15
property int longInterval:150
property Component contents:Component{SupportDialog{DetailsDrawer{DetailsParagraph{text:qsTr("Please take a moment to consider "+"if you can contribute to this project "+"in one way or another.")
}}}}
property string _applicationName:Qt.application.name
property string _organizationName:Qt.application.organization
readonly property bool __askAgain:!!configLoader.item?configLoader.item.askAgain:true
readonly property int __lastAskedAt:!!configLoader.item?configLoader.item.lastAskedAt:-1
readonly property int __startCount:!!configLoader.item?configLoader.item.startCount:-1
readonly property string __configPath:"/settings/opal/opal-supportme/"+"support-overlay/%1/%2".arg(_organizationName).arg(_applicationName)
property int __ready:(configLoader.status===Loader.Ready?1:0)
property int __maxReady:1
function show(){showTimer.stop()
pageStack.completeAnimation()
var dialog=pageStack.push(contents)
if(!!dialog){dialog.done.connect(function(){_markAsSeen()
})
dialog.dontAskAgain.connect(function(){_dontAskAgain()
})
}}function _markAsSeen(){configLoader.item.lastAskedAt=__startCount
}function _dontAskAgain(){_markAsSeen()
configLoader.item.askAgain=false
}Component.onCompleted:{if(!_applicationName||!_organizationName){console.warn("[Opal.SupportMe] both application name and organisation name "+"must be set in order to use the support overlay")
console.warn("[Opal.SupportMe] note that these properties are also required "+"for Sailjail sandboxing")
console.warn("[Opal.SupportMe] see: https://github.com/sailfishos/"+"sailjail-permissions#desktop-file-changes")
}}on__ReadyChanged:{if(__ready<__maxReady)return
configLoader.item.startCount+=1
if((__askAgain&&__startCount>=__lastAskedAt+interval)||(!__askAgain&&__startCount>=__lastAskedAt+longInterval)){console.log("[Opal.SupportMe] showing support popup now")
console.log("[Opal.SupportMe] starts: %1 | last asked: %2".arg(__startCount).arg(__lastAskedAt))
showTimer.start()
}}Loader{id:configLoader
sourceComponent:!!_applicationName&&!!_organizationName?configComponent:null
asynchronous:true
}Timer{id:showTimer
interval:8
repeat:true
running:false
onTriggered:{if(pageStack.busy||pageStack.depth===0)return
show()
}}Component{id:configComponent
ConfigurationGroup{path:root.__configPath
property bool askAgain:true
property int lastAskedAt:0
property int startCount:0
}}}