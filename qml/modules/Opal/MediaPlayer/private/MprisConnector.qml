//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-FileCopyrightText: 2013-2020 Leszek Lesner
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
//import org.nemomobile.mpris 1.0
import Amber.Mpris 1.0

MprisPlayer {
    id: mprisPlayer

    // serviceName: "llsVplayer"
    serviceName: "FileBrowser"

    property string title

    function hide() {
        canControl = false;
        title = "";
    }

    function show() {
        canControl = true;
    }

    onTitleChanged: {
        if (title != "") {
            console.debug("Title changed to: " + title)
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.Title)] = title
            mprisPlayer.metadata = metadata
        }
    }

    // Mpris2 Root Interface
    identity: "Video Player"

    // Mpris2 Player Interface
    canControl: true

    // canGoNext: true
    canGoNext: false
    // canGoPrevious: true
    canGoPrevious: false

    canPause: true
    canPlay: true
    canSeek: true

    onPlaybackStatusChanged: {
        // mprisPlayer.canGoNext = mainWindow.modelPlaylist.isNext() && mainWindow.firstPage.isPlaylist
        // mprisPlayer.canGoPrevious = mainWindow.modelPlaylist.isPrev() && mainWindow.firstPage.isPlaylist
    }

    loopStatus: Mpris.None
    shuffle: false
    volume: 1
}
