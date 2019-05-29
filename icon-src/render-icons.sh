#!/bin/bash

root="../src/icons"
for i in 86 108 128 172; do
    mkdir -p "$root/${i}x$i"
    inkscape -z -e "$root/${i}x$i/harbour-file-browser.png" -w "$i" -h "$i" harbour-file-browser.svg
done

root="../src/qml/images"
files=(harbour-file-browser@86)
mkdir -p "$root"

for img in "${files[@]}"; do
    inkscape -z -e "$root/${img%@*}.png" -w "${img#*@}" -h "${img#*@}" "${img%@*}.svg"
done
