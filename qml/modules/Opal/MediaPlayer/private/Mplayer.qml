//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-FileCopyrightText: 2013-2020 Leszek Lesner
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
MediaPlayer{id:mediaPlayer
property QtObject dataContainer
property string streamTitle
property string streamUrl
property bool isPlaying:playbackState===MediaPlayer.PlayingState?true:false
function loadPlaylistPage(){}function loadMetaDataPage(inBackground){var mDataTitle
if(streamTitle!="")mDataTitle=streamTitle
else mDataTitle=mainWindow.findBaseName(streamUrl)
if(typeof(dPage)!=="undefined"){if(inBackground==="inBackground"){}else{dPage=pageStack.push(Qt.resolvedUrl("FileDetails.qml"),{filename:streamUrl,title:mDataTitle,artist:metaData.albumArtist,videocodec:metaData.videoCodec,resolution:metaData.resolution,videobitrate:metaData.videoBitRate,framerate:metaData.videoFrameRate,audiocodec:metaData.audioCodec,audiobitrate:metaData.audioBitRate,samplerate:metaData.sampleRate,copyright:metaData.copyright,date:metaData.date,size:mainWindow.humanSize(_fm.getSize(streamUrl))})
}}}}