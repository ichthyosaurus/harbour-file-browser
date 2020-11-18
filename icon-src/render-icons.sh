#!/bin/bash

function render() { # 1: input, 2: width, 3: height, 4: output
    # replace '-o' by '-z -e' for inkscape < 1.0
    inkscape -o "$4" -w "$2" -h "$3" "$1"
    pngcrush -ow "$4"
}

echo "rendering app icon..."

app_icons=(
    harbour-file-browser-beta@../icons
    harbour-file-browser-root-beta@../root/icons
)
# app_icons+=(
#     harbour-file-browser@../icons
#     harbour-file-browser-root@../root/icons
# )

for s in 86 108 128 172; do
    for item in "${app_icons[@]}"; do
        dir="${item##*@}/${s}x$s"
        img="${item%@*}"
        mkdir -p "$dir"

        if [[ ! "$img.svg" -nt "$dir/$img.png" ]]; then
            echo "nothing to be done for '$item' at ${s}x$s"
            continue
        else
            render "$img.svg" "$s" "$s" "$dir/$img.png"
        fi
    done
done


echo "rendering toolbar icons..."

files=(
    toolbar-rename@64
    toolbar-copy@64
    toolbar-cut@64
    toolbar-properties@64
    toolbar-select-all@64
    harbour-file-browser@86
    harbour-file-browser-root@86
    icon-btn-search@112
)
root="../qml/images"
mkdir -p "$root"

for img in "${files[@]}"; do
    if [[ ! "${img%@*}.svg" -nt "$root/${img%@*}.png" ]]; then
        echo "nothing to be done for '${img%@*}.svg'"
        continue
    fi

    render "${img%@*}.svg" "${img#*@}" "${img#*@}" "$root/${img%@*}.png"
done


echo "rendering file icons..."

files=(
    file-stack
    file-audio
    file-compressed
    file-pdf
    file-image
    file-txt
    file-video
    file-apk
    file-rpm
    folder
    folder-link
    "link"
    "file"
)
root="../qml/images"
mkdir -p "$root"

for img in "${files[@]}"; do
    skip=

    if [[ "${img}.svg" -nt "$root/large-${img}.png" ]]; then
        render "${img}.svg" 128 128 "$root/large-${img}.png"
    else
        skip+="large "
    fi

    if [[ "${img}.svg" -nt "$root/small-${img}.png" ]]; then
        render "${img}.svg" 32 32 "$root/small-${img}.png"
    else
        skip+="small"
    fi

    if [[ -n "$skip" ]]; then
        echo "nothing to be done for '${img}.svg': $skip"
    fi
done

for img in ./file-icons-raster/*.png; do
    out="$root/$(basename "$img")"
    if [[ "$img" -nt "$out" ]]; then
        pngcrush "$img" "$out"
    else
        echo "nothing to be done for '$img'"
    fi
done
