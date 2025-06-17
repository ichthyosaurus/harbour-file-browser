//@ This file is part of opal-supportme.
//@ https://github.com/Pretty-SFOS/opal-supportme
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
Item{id:root
property bool enabled:true
property bool showOnInitialStart:false
property int interval:15
property int longInterval:150
property Component contents:Component{SupportDialog{DetailsDrawer{DetailsParagraph{text:qsTr("Please take a moment to consider "+"if you can contribute to this project "+"in one way or another.")
}}}}
property string customConfigPath:""
property string _applicationName:Qt.application.name
property string _organizationName:Qt.application.organization
readonly property bool __askAgain:!!configLoader.item?configLoader.item.askAgain:true
readonly property int __lastAskedAt:!!configLoader.item?configLoader.item.lastAskedAt:-1
readonly property int __startCount:!!configLoader.item?configLoader.item.startCount:(showOnInitialStart?interval:-1)
readonly property string __configPath:"/settings/opal/opal-supportme/"+"support-overlay/%1/%2".arg(_organizationName).arg(_applicationName)
readonly property string __effectiveConfigPath:customConfigPath||__configPath
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
}Component.onCompleted:{if(!enabled)return
if(!customConfigPath&&(!_applicationName||!_organizationName)){var prefix=!!objectName?objectName+": ":""
console.warn("[Opal.SupportMe] %1both application name and organisation name ".arg(prefix)+"must be set in order to use the support overlay")
console.warn("[Opal.SupportMe] %1note that these properties are also required ".arg(prefix)+"for Sailjail sandboxing")
console.warn("[Opal.SupportMe] %1see: https://github.com/sailfishos/".arg(prefix)+"sailjail-permissions#desktop-file-changes")
}}on__ReadyChanged:{if(!enabled||__ready<__maxReady)return
configLoader.item.startCount+=1
if((__askAgain&&__startCount>=__lastAskedAt+interval)||(!__askAgain&&__startCount>=__lastAskedAt+longInterval)){var prefix=!!objectName?objectName+": ":""
console.log("[Opal.SupportMe] %1showing support popup now".arg(prefix))
console.log("[Opal.SupportMe] %3starts: %1 | last asked: %2".arg(__startCount).arg(__lastAskedAt).arg(prefix))
showTimer.start()
}}Loader{id:configLoader
sourceComponent:enabled&&!!__effectiveConfigPath?configComponent:null
asynchronous:true
}Timer{id:showTimer
interval:8
repeat:true
running:false
onTriggered:{if(pageStack.busy||pageStack.depth===0)return
show()
}}Component{id:configComponent
ConfigurationGroup{path:root.__effectiveConfigPath
property bool askAgain:true
property int lastAskedAt:0
property int startCount:0
}}}