#!/bin/bash
#
# This file is part of File Browser.
# SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Run this script from the same directory where icon sources are located.
# See https://github.com/Pretty-SFOS/opal/blob/master/snippets/opal-render-icons.md
# for documentation.

source ../libs/opal-render-icons.sh
cFORCE=false

cNAME="app icons"
cITEMS=(
    harbour-file-browser-beta@../icons/RESXxRESY
    harbour-file-browser-root-beta@../root/icons/RESXxRESY
)
cRESOLUTIONS=(86 108 128 172)
cTARGETS=(F1)
render_batch

cNAME="toolbar icons"
cITEMS=(
    toolbar/toolbar-{rename,copy,cut,select-all}@112
    toolbar/icon-btn-search@112
)
cRESOLUTIONS=(F1)
cTARGETS=(../qml/images)
render_batch

cNAME="cover art"
cITEMS=(harbour-file-browser{,-root})
cRESOLUTIONS=(86)
cTARGETS=(../qml/images)
render_batch

cNAME="file icons"
cITEMS=(
    file/file-{stack,audio,compressed,pdf,image,txt,video,apk,rpm}
    file/folder{,-link}
    file/link
    file/file
)
cRESOLUTIONS=(128+large- 32+small-)
cTARGETS=(../qml/images)
render_batch

echo "crushing raster icons..."
for img in ./file-icons-raster/*.png; do
    out="../qml/images/$(basename "$img")"
    if [[ "$img" -nt "$out" ]]; then
        pngcrush "$img" "$out"
    else
        echo "nothing to be done for '$img'"
    fi
done
