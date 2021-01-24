/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: Matthias Wandel
 * SPDX-FileCopyrightText: 2014 Kari Pihkala
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * File Browser is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * File Browser is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

//
// This is a modified version of jhead 2.97, which is a
// public domain Exif manipulation tool.
//
// The original files can be found at http://www.sentex.net/~mwandel/jhead/
//


//--------------------------------------------------------------------------
// Include file for jhead program.
//
// This include file only defines stuff that goes across modules.  
// I like to keep the definitions for macros and structures as close to 
// where they get used as possible, so include files only get stuff that 
// gets used in more than one file.
//--------------------------------------------------------------------------
#include <QStringList>

#ifdef __cplusplus
extern "C" {
#endif

#include "jhead.h"

#ifdef __cplusplus
}
#endif

void showImageInfo(QStringList &metadata);

// we use a random character from Unicode's private range
// as string separator
static const QString METADATA_SEPARATOR = QStringLiteral("\uF83F");

QStringList jhead_readJpegFile(const char *FileName, bool *error);
