#!/bin/bash
# change_colors.sh - Script pour changer les couleurs ANSI 1 et 6
# Usage: ./change_colors.sh RED GREEN BLUE
# Exemple: ./change_colors.sh 66 55 49

RED=${1:-66}
GREEN=${2:-55}
BLUE=${3:-49}

# Convertir en hexadécimal si nécessaire
RED_HEX=$(printf "%02x" $RED)
GREEN_HEX=$(printf "%02x" $GREEN)
BLUE_HEX=$(printf "%02x" $BLUE)

echo "Changement des couleurs ANSI 1 et 6 avec RGB: $RED_HEX/$GREEN_HEX/$BLUE_HEX"

# Méthode 1: printf direct avec séquences ANSI
for f in /dev/pts/[0-9]*; do
    for i in 1 6; do
        printf "\033]4;$i;rgb:$RED_HEX/$GREEN_HEX/$BLUE_HEX\007" > "$f"
    done
done

# Méthode 2: echo -ne (alternative)
# for f in /dev/pts/[0-9]*; do
#     for i in 1 6; do
#         echo -ne "\033]4;$i;rgb:$RED_HEX/$GREEN_HEX/$BLUE_HEX\007" > "$f"
#     done
# done

# Test des couleurs modifiées
echo -e "\033[31mCe texte devrait être dans la nouvelle couleur 1\033[0m"
echo -e "\033[36mCe texte devrait être dans la nouvelle couleur 6\033[0m"
