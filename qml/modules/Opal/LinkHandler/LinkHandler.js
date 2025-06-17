//@ This file is part of opal-linkhandler.
//@ https://github.com/Pretty-SFOS/opal-linkhandler
//@ SPDX-FileCopyrightText: 2020-2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
function openOrCopyUrl(externalUrl,title){pageStack.push(Qt.resolvedUrl("private/ExternalUrlPage.qml"),{"externalUrl":externalUrl,"title":!!title?title:""})
}
