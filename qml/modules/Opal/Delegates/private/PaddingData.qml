//@ This file is part of opal-delegates.
//@ https://github.com/Pretty-SFOS/opal-delegates
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
QtObject{property int _undefinedValue:Number(-Infinity)
property int all:_undefinedValue
property int leftRight:_undefinedValue
property int topBottom:_undefinedValue
property int top:_undefinedValue
property int bottom:_undefinedValue
property int left:_undefinedValue
property int right:_undefinedValue
readonly property int effectiveTop:_isDefined(top)?top:_topBottom
readonly property int effectiveBottom:_isDefined(bottom)?bottom:_topBottom
readonly property int effectiveLeft:_isDefined(left)?left:_leftRight
readonly property int effectiveRight:_isDefined(right)?right:_leftRight
readonly property int _all:_isDefined(all)?all:0
readonly property int _topBottom:_isDefined(topBottom)?topBottom:_all
readonly property int _leftRight:_isDefined(leftRight)?leftRight:_all
function _isDefined(value){return value>_undefinedValue
}}