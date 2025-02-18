//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-FileCopyrightText: 2013-2020 Leszek Lesner
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Nemo.KeepAlive 1.2
import Amber.Mpris 1.0
import"private"
Page{id:root
allowedOrientations:Orientation.All
property string path
property alias title:titleOverlayItem.title
property bool autoplay:false
property bool repeat:false
property bool continueInBackground:false
property bool enableDarkBackground:true
property alias mprisAppId:mprisPlayer.identity
readonly property alias _titleOverlay:titleOverlayItem
readonly property bool _isPlaying:mediaPlayer.playbackState==MediaPlayer.PlayingState
readonly property bool _pageIsActive:status===PageStatus.Active||status===PageStatus.Activating
function play(){videoPoster.play()
}function pause(){videoPoster.pause()
}function togglePlay(){if(_isPlaying)pause()
else play()
}onOrientationChanged:video.checkScaleStatus()
onHeightChanged:video.checkScaleStatus()
onWidthChanged:video.checkScaleStatus()
onStatusChanged:{if(!continueInBackground&&(status===PageStatus.Deactivating||status===PageStatus.Inactive)){pause()
}else if(autoplay&&_pageIsActive){play()
}}onAutoplayChanged:{if(autoplay&&_pageIsActive){play()
}}DisplayBlanking{preventBlanking:mediaPlayer.playbackState==MediaPlayer.PlayingState
}Loader{z:-1000
sourceComponent:enableDarkBackground?backgroundComponent:null
anchors.fill:parent
Component{id:backgroundComponent
Rectangle{visible:enableDarkBackground
color:Theme.colorScheme===Theme.LightOnDark?Qt.darker(Theme.highlightDimmerColor,4.0):Qt.darker(Theme.highlightDimmerColor,8.0)
opacity:0.98
}}}MediaTitleOverlay{id:titleOverlayItem
shown:!autoplay
title:videoPoster.player.metaData.title||""
Binding on opacity{when:flick.topMargin>0
value:0.0
}}property string streamUrl:path
property string streamTitle:title
property string videoDuration:{if(videoPoster.duration>3599)return Format.formatDuration(videoPoster.duration,Formatter.DurationLong)
else return Format.formatDuration(videoPoster.duration,Formatter.DurationShort)
}property string videoPosition:{if(videoPoster.position>3599)return Format.formatDuration(videoPoster.position,Formatter.DurationLong)
else return Format.formatDuration(videoPoster.position,Formatter.DurationShort)
}property int subtitlesSize:Theme.fontSizeMedium
property bool boldSubtitles:true
property string subtitlesColor:"white"
property bool enableSubtitles:!!subtitleUrl.toString()
property variant currentVideoSub:[]
property Page dPage
property string subtitleUrl
property bool subtitleSolid:true
property bool allowScaling:false
property alias videoPoster:videoPoster
property bool isLightTheme:Theme.colorScheme===Theme.DarkOnLight
Component.onCompleted:{if(autoplay&&_pageIsActive){play()
}else{mprisPlayer.title=streamTitle
}console.log("PLAYING",streamUrl,"AUTO",autoplay,"ACTIVE",_pageIsActive)
}onStreamUrlChanged:{console.log("NEW STREAM URL:",streamUrl)
errorOverlay.reset()
if(autoplay&&status===PageStatus.Active){play()
}else if(!autoplay){videoPoster.showControls()
}}function videoPauseTrigger(){if(videoPoster.player.playbackState==MediaPlayer.PlayingState)videoPoster.pause()
else if(videoPoster.source.toString().length!==0)videoPoster.play()
if(videoPoster.controls.opacity===0.0)videoPoster.toggleControls()
}function toggleRepeat(){repeat=!repeat
repeatIndicator.show()
}function toggleAspectRatio(){if(video.fillMode==VideoOutput.PreserveAspectFit){video.fillMode=VideoOutput.PreserveAspectCrop
}else{video.fillMode=VideoOutput.PreserveAspectFit
}scaleIndicator.show()
}SilicaFlickable{id:flick
anchors.fill:parent
PullDownMenu{id:pulley
enabled:titleOverlayItem.shown
visible:opacity>0.0
opacity:enabled?1.0:0.0
Behavior on opacity{FadeAnimator{duration:80
}}MenuItem{visible:!!root.subtitleUrl.toString()
text:qsTranslate("Opal.MediaPlayer","Clear subtitles")
onClicked:root.subtitleUrl=""
}MenuItem{text:qsTranslate("Opal.MediaPlayer","Load subtitles")
onClicked:{var dialog=pageStack.push(Qt.resolvedUrl("private/LoadSubtitlesDialog.qml"),{inFolder:path.slice(0,path.lastIndexOf("/")),forFile:path,})
dialog.accepted.connect(function(){root.subtitleUrl=dialog.selected
})
}}}AnimatedImage{id:onlyMusic
enabled:false
anchors.centerIn:parent
source:Qt.resolvedUrl("private/images/audio.gif")
opacity:enabled?0.75:0.0
width:Screen.width/1.25
height:width
playing:true
visible:opacity>0
Behavior on opacity{FadeAnimator{}}}ProgressCircle{id:progressCircle
enabled:mediaPlayer.status===MediaPlayer.Loading||mediaPlayer.status===MediaPlayer.Buffering||mediaPlayer.status===MediaPlayer.Stalled
anchors.centerIn:parent
visible:opacity>0
opacity:enabled?1.0:0.0
Behavior on opacity{FadeAnimator{}}Timer{interval:32
repeat:true
running:progressCircle.visible
onTriggered:{progressCircle.value=(progressCircle.value+0.005)%1.0
}}}Loader{id:subTitleLoader
active:enableSubtitles
sourceComponent:subItem
anchors.fill:parent
}Component{id:subItem
SubtitlesItem{id:subtitlesText
anchors{fill:parent
margins:root.inPortrait?10:50
}wrapMode:Text.WordWrap
horizontalAlignment:Text.AlignHCenter
verticalAlignment:Text.AlignBottom
pixelSize:subtitlesSize
bold:boldSubtitles
color:subtitlesColor
visible:enableSubtitles&&currentVideoSub
isSolid:subtitleSolid
}}Rectangle{color:Theme.overlayBackgroundColor
anchors.fill:parent
opacity:errorOverlay.visible?Theme.opacityOverlay:0.0
z:1000
MouseArea{anchors.fill:parent
enabled:errorOverlay.visible
}ErrorOverlay{id:errorOverlay
onVisibleChanged:{if(visible)videoPoster.hideControls()
}}}Item{id:mediaItem
property bool active:true
visible:active
parent:pincher.enabled?pincher:flick
anchors.fill:parent
VideoPoster{id:videoPoster
anchors.fill:parent
player:mediaPlayer
autoplay:root.autoplay
property int mouseX
property int mouseY
active:mediaItem.active
source:streamUrl
onSourceChanged:{position=0
player.seek(0)
}function play(){playClicked()
}onPlayClicked:{console.debug("Loading source into player")
player.source=source
console.debug("Starting playback")
player.play()
hideControls()
showNavigationIndicator=false
mprisPlayer.title=streamTitle
if(enableSubtitles){subTitleLoader.item.getSubtitles(subtitleUrl)
}if(mediaPlayer.hasAudio===true&&mediaPlayer.hasVideo===false){onlyMusic.playing=true
}}function toggleControls(){if(controls.opacity===0.0){showControls()
}else{hideControls()
}}function hideControls(){titleOverlayItem.hide()
controls.opacity=0.0
root.showNavigationIndicator=false
}function showControls(){titleOverlayItem.show()
controls.opacity=1.0
root.showNavigationIndicator=true
}function pause(){mediaPlayer.pause()
if(controls.opacity===0.0)toggleControls()
if(!mediaPlayer.seekable)mediaPlayer.stop()
onlyMusic.playing=false
}readonly property int _centerControlHalf:0.5*(Theme.iconSizeMedium+2*1.5*Theme.paddingLarge)
readonly property int _outerControlSize:Theme.iconSizeMedium+2*0.8*Theme.paddingLarge
readonly property int _controlPadding:Theme.paddingLarge
readonly property int _outerControlThreshold:_centerControlHalf+_controlPadding+_outerControlSize
function isPlayPauseClick(mouse){var middleX=width/2
var middleY=height/2
return((mouse.x>=middleX-_centerControlHalf&&mouse.x<=middleX+_centerControlHalf)&&(mouse.y>=middleY-_centerControlHalf&&mouse.y<=middleY+_centerControlHalf))
}function isForwardClick(mouse){var middleX=width/2
var middleY=height/2
return((mouse.x>middleX+_centerControlHalf&&mouse.x<middleX+_outerControlThreshold)&&(mouse.y>=middleY-_centerControlHalf&&mouse.y<=middleY+_centerControlHalf))
}function isRewindClick(mouse){var middleX=width/2
var middleY=height/2
return((mouse.x<middleX-_centerControlHalf&&mouse.x>middleX-_outerControlThreshold)&&(mouse.y>=middleY-_centerControlHalf&&mouse.y<=middleY+_centerControlHalf))
}onClicked:{if(isPlayPauseClick(mouse)){togglePlay()
}else if(isForwardClick(mouse)){ffwd(10)
}else if(isRewindClick(mouse)){rew(5)
}else{toggleControls()
}}onPositionChanged:{if(enableSubtitles&&currentVideoSub){subTitleLoader.item.checkSubtitles()
}}}}}PinchArea{id:pincher
enabled:allowScaling&&!errorOverlay.visible
visible:enabled
anchors.fill:parent
pinch.target:video
pinch.minimumScale:1
pinch.maximumScale:1+(((root.width/root.height)-(video.sourceRect.width/video.sourceRect.height))/(video.sourceRect.width/video.sourceRect.height))
pinch.dragAxis:Pinch.XAndYAxis
property bool pinchIn:false
onPinchUpdated:{if(pinch.previousScale<pinch.scale){pinchIn=true
}else if(pinch.previousScale>pinch.scale){pinchIn=false
}}onPinchFinished:{if(pinchIn){video.fillMode=VideoOutput.PreserveAspectCrop
}else{video.fillMode=VideoOutput.PreserveAspectFit
}scaleIndicator.show()
}}Jupii{id:jupii
}VideoOutput{id:video
z:-1000
anchors.fill:parent
transformOrigin:Item.Center
function checkScaleStatus(){if((root.width/root.height)>sourceRect.width/sourceRect.height)allowScaling=true
console.log(root.width/root.height+" - "+sourceRect.width/sourceRect.height)
}onFillModeChanged:{if(fillMode===VideoOutput.PreserveAspectCrop)scale=1+(((root.width/root.height)-(sourceRect.width/sourceRect.height))/(sourceRect.width/sourceRect.height))
else scale=1
}source:Mplayer{id:mediaPlayer
autoLoad:true
autoPlay:root.autoplay
dataContainer:root
streamTitle:root.streamTitle
streamUrl:root.streamUrl
onPlaybackStateChanged:{if(playbackState==MediaPlayer.PlayingState){if(onlyMusic.enabled)onlyMusic.playing=true
mprisPlayer.playbackStatus=Mpris.Playing
video.checkScaleStatus()
}else{if(onlyMusic.enabled)onlyMusic.playing=false
mprisPlayer.playbackStatus=Mpris.Paused
}}onDurationChanged:{videoPoster.duration=(duration/1000)
if(hasAudio===true&&hasVideo===false){onlyMusic.enabled=true
}else{onlyMusic.enabled=false
}}onStatusChanged:{if(mediaPlayer.status===MediaPlayer.Loaded){if(autoPlay){root.play()
}else{videoPoster.showControls()
}}else if(!repeat&&mediaPlayer.status===MediaPlayer.EndOfMedia){videoPoster.showControls()
}else{loadMetaDataPage("inBackground")
}if(metaData.title){mprisPlayer.title=metaData.title
}}onHasVideoChanged:{}onError:{if(error===MediaPlayer.NoError){return
}console.error("[Opal.MediaPlayer] video playback failed:",error,errorString)
stop()
errorOverlay.show(error,errorString)
}onStopped:{if(repeat){play()
}}}visible:mediaPlayer.status>=MediaPlayer.Loaded&&mediaPlayer.status<=MediaPlayer.EndOfMedia
width:parent.width
height:parent.height
anchors.centerIn:root
}NoticeLabel{id:scaleIndicator
anchors{horizontalCenter:parent.horizontalCenter
top:parent.top
topMargin:4*Theme.paddingLarge
}fontSize:Theme.fontSizeSmall
text:(video.fillMode===VideoOutput.PreserveAspectCrop)?qsTranslate("Opal.MediaPlayer","Zoomed to fit screen"):qsTranslate("Opal.MediaPlayer","Original")
}NoticeLabel{id:repeatIndicator
anchors.centerIn:scaleIndicator
fontSize:Theme.fontSizeSmall
text:repeat?qsTranslate("Opal.MediaPlayer","Play on repeat"):qsTranslate("Opal.MediaPlayer","Play once")
}Keys.onPressed:{if(event.key===Qt.Key_Space)videoPauseTrigger()
if(event.key===Qt.Key_Left&&mediaPlayer.seekable){mediaPlayer.seek(mediaPlayer.position-5000)
}if(event.key===Qt.Key_Right&&mediaPlayer.seekable){mediaPlayer.seek(mediaPlayer.position+10000)
}}MprisConnector{id:mprisPlayer
onPauseRequested:{videoPoster.pause()
}onPlayRequested:{videoPoster.play()
}onPlayPauseRequested:{root.videoPauseTrigger()
}onStopRequested:{videoPoster.player.stop()
}onSeekRequested:{mediaPlayer.seek(offset)
}}}