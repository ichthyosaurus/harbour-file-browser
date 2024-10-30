#!/bin/bash
#
# This file is part of File Browser.
# SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#
# See https://github.com/Pretty-SFOS/opal/blob/main/snippets/opal-render-icons.md
# for documentation.
#
# @@@ keep this line: based on template v0.3.0
#
c__FOR_RENDER_LIB__="1.0.0"

# Run this script from the same directory where your icon sources are located,
# e.g. <app>/icon-src.
source ../libs/opal-render-icons.sh
cFORCE=false

echo "scrubbing svg sources..."
for dir in . file toolbar clipboard; do
    pushd "$dir"
    for i in raw/*.svg; do
        if [[ "$i" -nt "${i#raw/}" ]]; then
            scour "$i" > "${i#raw/}"
        fi
    done
    popd
done

cMY_APP=harbour-file-browser

cNAME="app icons"
cITEMS=(
    "$cMY_APP@../icons/RESXxRESY"
    "$cMY_APP-root@../root/icons/RESXxRESY"
)
cRESOLUTIONS=(86 108 128 172)
cTARGETS=(F1)
render_batch

cNAME="toolbar icons"
cITEMS=(
    toolbar/toolbar-{rename,copy,cut,select-all}@112
    toolbar/icon-btn-search@112
    toolbar/places-warning@112
)
cRESOLUTIONS=(F1)
cTARGETS=(../qml/images)
render_batch

cNAME="clipboard action icons"
cITEMS=(
    clipboard/clipboard-{copy,link,move,compress}@112
)
cRESOLUTIONS=(F1)
cTARGETS=(../qml/images)
render_batch

cNAME="cover background"
cITEMS=($cMY_APP{,-root})
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

cNAME="banner image"
cITEMS=(../dist/banner)
cRESOLUTIONS=(
    1080x540++-large
    540x270++-small
)
cTARGETS=(../dist)
render_batch

cNAME="store icon"
cITEMS=("$cMY_APP")
cRESOLUTIONS=(172)
cTARGETS=(../dist)
render_batch
