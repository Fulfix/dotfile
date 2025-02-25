#!/bin/bash
echo "$HOME/.config/mpd/cover/$(basename "$(mpc current -f "%file%")" .mp3).jpg"
