//@ This file is part of opal-delegates.
//@ https://github.com/Pretty-SFOS/opal-delegates
//@ SPDX-FileCopyrightText: 2023 Peter G. (nephros)
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
PaddedDelegate{id:root
minContentHeight:Theme.itemSizeMedium-padding.effectiveTop-padding.effectiveBottom
centeredContainer:contentColumn
property string text
property string description
readonly property alias textLabel:_line1
readonly property alias descriptionLabel:_line2
Column{id:contentColumn
width:parent.width
OptionalLabel{id:_line1
width:parent.width
text:root.text
font.pixelSize:Theme.fontSizeMedium
palette{primaryColor:Theme.primaryColor
highlightColor:Theme.highlightColor
}}OptionalLabel{id:_line2
width:parent.width
text:root.description
font.pixelSize:Theme.fontSizeSmall
palette{primaryColor:Theme.secondaryColor
highlightColor:Theme.secondaryHighlightColor
}}}}