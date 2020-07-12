#!/bin/bash

echo "rendering app icon..."

postfix="-beta"

default_src=harbour-file-browser
default_dir="../src/icons"
root_src=harbour-file-browser-root
root_dir="../root/icons"

for i in 86 108 128 172; do
    mkdir -p "$default_dir/${i}x$i"
    mkdir -p "$root_dir/${i}x$i"

    for a in "$default_src" "$root_src"; do
        [[ "$a" == "$default_src" ]] && root="$default_dir" || root="$root_dir"

        if [[ ! "$a.svg" -nt "$root/${i}x$i/$a$postfix.png" ]]; then
            echo "nothing to be done for $a at ${i}x$i"
            continue
        fi

        inkscape -z -e "$root/${i}x$i/$a$postfix.png" -w "$i" -h "$i" "$a.svg"
    done
done


echo "rendering toolbar icons..."

root="../src/qml/images"
files=(toolbar-rename@64 harbour-file-browser@86 harbour-file-browser-root@86 icon-btn-search@112)
mkdir -p "$root"

for img in "${files[@]}"; do
    if [[ ! "${img%@*}.svg" -nt "$root/${img%@*}.png" ]]; then
        echo "nothing to be done for '${img%@*}.svg'"
        continue
    fi

    inkscape -z -e "$root/${img%@*}.png" -w "${img#*@}" -h "${img#*@}" "${img%@*}.svg"
done


echo "rendering file icons..."

files=(file-stack file-audio file-compressed file-pdf)
mkdir -p "$root"

for img in "${files[@]}"; do
    skip=

    if [[ "${img%@*}.svg" -nt "$root/large-${img%@*}.png" ]]; then
        inkscape -z -e "$root/large-${img}.png" -w "128" -h "128" "${img}.svg"
    else
        skip+="large "
    fi

    if [[ "${img%@*}.svg" -nt "$root/small-${img%@*}.png" ]]; then
        inkscape -z -e "$root/small-${img}.png" -w "32" -h "32" "${img}.svg"
    else
        skip+="small"
    fi

    if [[ -n "$skip" ]]; then
        echo "nothing to be done for '${img}.svg': $skip"
    fi
done
