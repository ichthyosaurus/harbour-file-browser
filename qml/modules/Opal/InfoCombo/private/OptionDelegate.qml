//@ This file is part of opal-infocombo.
//@ https://github.com/Pretty-SFOS/opal-infocombo
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
TextSwitch{property bool allowChanges
property ComboBox comboBox
property int modelIndex
checked:!!comboBox&&comboBox.currentIndex==modelIndex
automaticCheck:false
Binding on highlighted{when:!allowChanges
value:true
}text:modelData.title
description:modelData.text
onClicked:{if(!allowChanges||!comboBox||comboBox.currentIndex==modelIndex){return
}comboBox.currentIndex=modelIndex
}}