//@ This file is part of opal-delegates.
//@ https://github.com/Pretty-SFOS/opal-delegates
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
PaddedDelegate{id:root
minContentHeight:Theme.itemSizeSmall-padding.effectiveTop-padding.effectiveBottom
centeredContainer:contentContainer
property string text
readonly property alias textLabel:_line1
Column{id:contentContainer
width:parent.width
OptionalLabel{id:_line1
width:parent.width
text:root.text
font.pixelSize:Theme.fontSizeMedium
palette{primaryColor:Theme.primaryColor
highlightColor:Theme.highlightColor
}}}}