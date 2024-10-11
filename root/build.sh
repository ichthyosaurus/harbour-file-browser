#!/bin/bash
#
# This file is part of File Browser and has been released into the public domain.
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2020-2024 Mirian Margiani

SFDK=/opt/sfos/bin/sfdk
TARGETS=(
    # note: last field (/-.*?$/) has to be architecture
    "SailfishOS-4.6.0.13-i486"
    "SailfishOS-4.6.0.13-aarch64"
    "SailfishOS-4.6.0.13-armv7hl"
)

log-n() { echo -ne "\e[1m"; printf -- "%s " "$@" | sed 's/ $//g'; echo -ne "\e[0m"; }
log() { log-n "$@" && echo; }

showhelp() {
    log "** build harbour-file-browser-root **"
    log "usage: build.sh [-h|--help] [-n|--no-stop-engine]"
    echo
    echo "Modify this script to set the correct paths for your setup"
    echo "by changing the SFDK and TARGETS variables."
    echo
    echo "Use the --no-stop-engine option to keep the build engine"
    echo "running after the script has ended. By default, the build"
    echo "engine is started and stopped by this script automatically."
}

cCUSTOM_TARGETS=()
cSTOP_ENGINE=true
for i in "$@"; do
    if [[ "$i" =~ ^-?-h(elp)?$ ]]; then
        showhelp
        exit 0
    elif [[ "$i" == "-n" || "$i" == "--no-stop-engine" ]]; then
        cSTOP_ENGINE=false
        continue
    elif [[ "$i" == "-"* ]]; then
        log "error: unknown argument '$i'"
        showhelp
        exit 1
    fi

    cCUSTOM_TARGETS+=("$i")
done

if (( ${#cCUSTOM_TARGETS[@]} > 0 )); then
    TARGETS=("${cCUSTOM_TARGETS[@]}")
fi

if [[ ! -f "$SFDK" ]]; then
    log "error: could not find sfdk at '$SFDK'"
    exit 2
fi

log "selected targets:"
printf -- "- %s\n" "${TARGETS[@]}"
echo

echo "starting the build engine..."
"$SFDK" engine start

mv -T --backup=t RPMS RPMS~ || true

declare -A status

for t in "${TARGETS[@]}"; do
    status["$t"]="ok"

    "$SFDK" engine exec sb2 -t "$t" make BUILDARCH="${t##*-}" || {
        status["$t"]="failed"
    }
done

echo; echo
log "builds finished:"
for t in "${!status[@]}"; do
    echo -ne "- \e[1m${status[$t]}\t\e[0m"
    printf -- "%s\n" "$t"
done
echo

if [[ "$cSTOP_ENGINE" == true ]]; then
    echo "stopping the build engine..."
    "$SFDK" engine stop || {
        log "error: failed to stop the build engine"
        printf -- "%s\n" "Try running this manually: $SFDK engine stop"
    }
else
    printf -- "%s\n" "if you no longer need it, stop the build engine by running:"
    printf -- "\t%s\n" "$SFDK engine stop"
fi

exit 0
