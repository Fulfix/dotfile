#!/bin/bash

SRC="$HOME/.config/mpd/music"
DST="$HOME/.config/mpd/cover"
mkdir -p "$DST"
rm -rf $HOME/.config/mpd/cover/*

find "$SRC" -type f -name "*.mp3" | while read -r file; do
    out="$DST/${file#$SRC/}.jpg"
    mkdir -p "$(dirname "$out")"
    ffmpeg -i "$file" -y -vf "select=eq(n\,0)" -update 1 "$out" 2>/dev/null &&
    [ -s "$out" ] || rm -f "$out"
    
    # Redimensionne l'image extraite à 500x500 pixels
    if [ -s "$out" ]; then
        magick "$out" -resize 130x130! "$out"
    fi
done

echo "Traitement terminé !"

