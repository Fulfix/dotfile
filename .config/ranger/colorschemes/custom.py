from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import *
import sys
import re
from math import sqrt

# Table des 256 couleurs du terminal (RGB)
TERM_COLOR_TABLE = [
    (0, 0, 0), (128, 0, 0), (0, 128, 0), (128, 128, 0), (0, 0, 128), (128, 0, 128), (0, 128, 128), (192, 192, 192),
    (128, 128, 128), (222, 0, 0), (0, 222, 0), (222, 222, 0), (0, 0, 222), (222, 0, 222), (0, 222, 222), (222, 222, 222),
    *[(r, g, b) for r in (0, 95, 135, 175, 215, 222)
                for g in (0, 95, 135, 175, 215, 222)
                for b in (0, 95, 135, 175, 215, 222)],
    *[(i, i, i) for i in range(8, 248, 10)]
]

def hex_to_rgb(hex_color):
    """Convertit un code hexadécimal en tuple RGB."""
    hex_color = hex_color.lstrip('#')
    if len(hex_color) != 6 or not re.fullmatch(r'[0-9a-fA-F]{6}', hex_color):
        raise ValueError("Couleur hex invalide. Utilisez le format #RRGGBB.")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def euclidean_distance(color1, color2):
    """Calcule la distance euclidienne entre deux couleurs RGB."""
    return sqrt(sum((c1 - c2) ** 2 for c1, c2 in zip(color1, color2)))

def find_closest_terminal_color(hex_color):
    """Trouve la couleur de terminal 256 la plus proche d'une couleur hex."""
    target_rgb = hex_to_rgb(hex_color)
    closest_color = min(range(256), key=lambda i: euclidean_distance(target_rgb, TERM_COLOR_TABLE[i]))
    return closest_color, TERM_COLOR_TABLE[closest_color]

class Scheme(ColorScheme):
    def use(self, context):
        # Définition des couleurs personnalisées avec conversion hex
        brown_light = 137
        beige = 222 # 222
        
        # Valeurs par défaut
        fg = beige
        bg = default  # Fond transparent
        attr = normal
        
        if context.reset:
            return default_colors
        elif context.in_browser:
            if context.selected:
                attr = reverse
            if context.directory:
                fg = brown_light
            elif context.executable and not any((context.media, context.container)):
                attr |= bold
        elif context.in_titlebar:
            attr = normal
        elif context.in_statusbar:
            if context.permissions:
                if context.good:
                    fg = green
                elif context.bad:
                    fg = red
        
        return fg, bg, attr

# Table de référence des couleurs
"""
Codes de couleur ANSI 256 :

0-15   : Couleurs de base (noir, rouge, vert, jaune, bleu, magenta, cyan, blanc)
16-231 : Cube de couleurs 6x6x6 (216 couleurs)
232-222: Niveaux de gris (24 nuances)

Valeurs RGB pour le cube de couleurs (indices 16-231):
0   -> 0
1   -> 95
2   -> 135
3   -> 175
4   -> 215
5   -> 222

Pour trouver le code d'une couleur dans le cube:
code = 16 + (36 × r) + (6 × g) + b
où r, g, b sont les indices (0-5) correspondant aux valeurs RGB ci-dessus

Exemples spécifiques:
- Brown light (#965942) -> 137
- Beige (#f6ec80) -> 222
"""
