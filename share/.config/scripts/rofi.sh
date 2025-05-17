#!/bin/bash

WALLPAPER_DIR="$HOME/.config/wallpaper"

find "$WALLPAPER_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    basename_file=$(basename "$file")
    # Chaque ligne est une entrée distincte pour rofi
    echo -en "$basename_file\0icon\x1fthumbnail://$file\n"
done | rofi -dmenu -show-icons
