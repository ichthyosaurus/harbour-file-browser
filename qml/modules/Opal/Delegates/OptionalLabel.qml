//@ This file is part of opal-delegates.
//@ https://github.com/Pretty-SFOS/opal-delegates
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.5
import Sailfish.Silica 1.0
Label{id:root
property bool wrapped:false
property alias metrics:metricsItem
TextMetrics{id:metricsItem
font:root.font
text:root.text
}Binding on height{when:text==""
value:0
}height:implicitHeight
wrapMode:Text.NoWrap
truncationMode:TruncationMode.Fade
states:[State{name:"wrapped"
when:root.wrapped||text.indexOf("\n")>-1
PropertyChanges{target:root
wrapMode:Text.Wrap
elide:Text.ElideNone
truncationMode:TruncationMode.None
}}]}