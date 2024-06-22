//@ This file is part of opal-infocombo.
//@ https://github.com/Pretty-SFOS/opal-infocombo
//@ SPDX-FileCopyrightText: 2023-2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
Page{id:root
allowedOrientations:Orientation.All
property ComboBox comboBox
property string title
property var topNotes:[]
property var items:[]
property var bottomNotes:[]
property bool allowChanges
readonly property bool hasExtraSections:top.length>0||bottom.length>0
signal linkActivated(var link)
SilicaFlickable{id:flick
anchors.fill:parent
contentHeight:column.height+2*Theme.horizontalPageMargin
VerticalScrollDecorator{flickable:flick
}Column{id:column
spacing:Theme.paddingLarge
width:parent.width
height:childrenRect.height
PageHeader{title:root.title
description:qsTranslate("Opal.InfoCombo","Details")
}Repeater{model:topNotes
delegate:NoteDelegate{onLinkActivated:root.linkActivated(link)
}}Repeater{model:items
delegate:OptionDelegate{allowChanges:root.allowChanges
comboBox:root.comboBox
modelIndex:index
}}Repeater{model:bottomNotes
delegate:NoteDelegate{onLinkActivated:root.linkActivated(link)
}}}}}