//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-FileCopyrightText: 2013-2020 Leszek Lesner
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Nemo.DBus 2.0

Item {
    property bool found: false

    onVisibleChanged: ping()

    function ping() {
        found = (jupiiPlayer.getProperty('canControl') === true)
    }

    function addUrlOnceAndPlay(url, title, author, type, app, icon) {
        jupiiPlayer.call('add', [url, title, author, "", type, app, icon, true, true, true])
    }

    DBusInterface {
        id: jupiiPlayer

        service: 'org.jupii'
        iface: 'org.jupii.Player'
        path: '/'
    }
}
