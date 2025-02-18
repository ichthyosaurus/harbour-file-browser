//@ This file is part of opal-delegates.
//@ https://github.com/Pretty-SFOS/opal-delegates
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
QtObject{property int _undefinedValue:-9999
property int all:_undefinedValue
property int leftRight:_undefinedValue
property int topBottom:_undefinedValue
property int top:_undefinedValue
property int bottom:_undefinedValue
property int left:_undefinedValue
property int right:_undefinedValue
readonly property int effectiveTop:top!==_undefinedValue?top:_topBottom
readonly property int effectiveBottom:bottom!==_undefinedValue?bottom:_topBottom
readonly property int effectiveLeft:left!==_undefinedValue?left:_leftRight
readonly property int effectiveRight:right!==_undefinedValue?right:_leftRight
readonly property int _all:all!==_undefinedValue?all:0
readonly property int _topBottom:topBottom!==_undefinedValue?topBottom:_all
readonly property int _leftRight:leftRight!==_undefinedValue?leftRight:_all
}