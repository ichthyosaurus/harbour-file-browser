#!/bin/bash
#
# This file is part of File Browser.
# SPDX-FileCopyrightText: 2021 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This script uses the converted RPM changelog (generated from CHANGELOG.md by
# rpm/harbour-file-browser.run) and converts it to be used on OpenRepos.
#

converter="./rpm/harbour-file-browser.changes.run"

if [[ "$(basename "$(pwd)")" == "rpm" ]]; then
    cd ..  # run from base directory
fi

if [[ ! -f "$converter" ]]; then
    echo "error: main conversion script not found"
    exit 2
fi

bash "$converter" |\
    sed -Ee 's@\* ... (... .. ....) .*?> (.*)$@</ul><p><strong>version \2: \1</strong></p><ul>@g;
             s/^- (.*)$/<li>\1<\/li>/g;
             /^$/d;' |\
        sed -Ee '1s@</ul>@@g;
                 $s@$@</ul>@g'
