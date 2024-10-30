//@ This file is part of opal-menuswitch.
//@ https://github.com/Pretty-SFOS/opal-menuswitch
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0 as S
S.MenuItem{id:root
property alias automaticCheck:toggle.automaticCheck
property alias checked:toggle.checked
property alias busy:toggle.busy
readonly property alias switchItem:toggle
Binding on enabled{when:busy
value:false
}Binding on color{when:busy
value:_enabledColor
}S.TextSwitch{id:toggle
checked:false
automaticCheck:true
text:""
highlighted:parent.highlighted
height:S.Theme.itemSizeSmall
width:S.Theme.iconSizeMedium+S.Theme.paddingSmall
anchors.verticalCenter:parent.verticalCenter
onClicked:{if(!!mouse&&!automaticCheck){root.clicked()
}}}TextMetrics{id:metrics
font:root.font
text:root.text
}text:""
property int __marginsWidth:(root.width-metrics.width)/2
leftPadding:__marginsWidth>=toggle.width?0:toggle.width+S.Theme.paddingLarge-(Math.max(root.width-metrics.width,1.5*S.Theme.paddingLarge)/2)
onClicked:{toggle.clicked(null)
}}