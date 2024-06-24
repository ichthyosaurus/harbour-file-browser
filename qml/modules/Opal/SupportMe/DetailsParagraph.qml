//@ This file is part of opal-supportme.
//@ https://github.com/Pretty-SFOS/opal-supportme
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import"private/LinkHandler"
Label{width:parent.width
color:palette.highlightColor
wrapMode:Text.Wrap
linkColor:Theme.secondaryColor
onLinkActivated:LinkHandler.openOrCopyUrl(link)
text:""
}