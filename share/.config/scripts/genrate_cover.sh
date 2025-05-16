#!/bin/bash
set -e

SRC="$HOME/.config/mpd/music"
DST="$HOME/.config/mpd/cover"

mkdir -p "$DST"
rm -rf "$DST"/*

# Remplace les espaces dans les noms de fichiers (dans SRC, non récursif ici)
for fichier in "$SRC"/*; do
  # Vérifie que c'est un fichier
  [ -f "$fichier" ] || continue
  
  nom_fichier="$(basename "$fichier")"
  chemin_dossier="$(dirname "$fichier")"
  nouveau_nom=$(basename "$fichier" | tr ' ' '_' | iconv -f utf-8 -t ascii//TRANSLIT | sed 's/[^A-Za-z0-9._-]//g')
  nouveau_chemin="$chemin_dossier/$nouveau_nom"
  
  if [ "$fichier" != "$nouveau_chemin" ]; then
    if [ -e "$nouveau_chemin" ]; then
      echo "Le fichier '$nouveau_chemin' existe déjà, saut de '$fichier'."
    else
      echo "Renommage : '$fichier' -> '$nouveau_chemin'"
      mv "$fichier" "$nouveau_chemin"
    fi
  fi
done

# Extraction des pochettes dans DST, récursif pour tous les mp3
find "$SRC" -type f -name "*.mp3" -print0 | while IFS= read -r -d '' file; do
    out="$DST/${file#$SRC/}.jpg"
    mkdir -p "$(dirname "$out")"
    ffmpeg -i "$file" -y -vf "select=eq(n\,0)" -update 1 "$out" 2>/dev/null
    
    if [ -s "$out" ]; then
        magick "$out" -resize 130x130! "$out"
    else
        rm -f "$out"
    fi
done

echo "Traitement terminé !"

