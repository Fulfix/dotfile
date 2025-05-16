#!/bin/bash
sanitize_name() {
  echo "$1" | tr ' ' '_' | iconv -f utf-8 -t ascii//TRANSLIT | sed 's/[^A-Za-z0-9._-]//g'
}

music_dir="$HOME/.config/mpd/music"
file="$(mpc current -f "%file%")"
file_sanitized=$(sanitize_name "$file")
echo "$HOME/.config/mpd/cover/$file_sanitized.jpg"

