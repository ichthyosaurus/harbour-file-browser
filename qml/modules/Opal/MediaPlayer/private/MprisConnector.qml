//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-FileCopyrightText: 2013-2020 Leszek Lesner
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Amber.Mpris 1.0
MprisPlayer{id:mprisPlayer
property string title
function hide(){canControl=false
title=""
}function show(){canControl=true
}onTitleChanged:{if(title!=""){console.debug("Title changed to: "+title)
mprisPlayer.metaData.title=title
}}serviceName:"OpalMediaPlayer"
identity:"Opal Video Player"
canControl:true
canGoNext:false
canGoPrevious:false
canPause:true
canPlay:true
canSeek:true
onPlaybackStatusChanged:{}loopStatus:Mpris.LoopNone
shuffle:false
volume:1
}