#!/bin/bash
set -e
if [ "$(whoami)" = 'root' ]; then
    echo "run this script as an user"
    exit 1
fi
user=$(echo $USER)
ls /home/$user/theme/my_themes
read -e -p "choose your theme: " new_theme

# Input colors
old_font_color=$(jq -r ".font" /home/$user/theme/current_colors.json)
old_accent_color=$(jq -r ".accent" /home/$user/theme/current_colors.json)
old_bg_color=$(jq -r ".bg" /home/$user/theme/current_colors.json)
old_term_accent_color=$(jq -r ".term_accent" /home/$user/theme/current_colors.json)
old_term_font_color=$(jq -r ".term_font" /home/$user/theme/current_colors.json)
old_wallpaper=$(jq -r ".wallpaper" /home/$user/theme/current_colors.json)

new_font_color=$(jq -r ".font" /home/$user/theme/my_themes/"$new_theme")
new_accent_color=$(jq -r ".accent" /home/$user/theme/my_themes/"$new_theme")
new_bg_color=$(jq -r ".bg" /home/$user/theme/my_themes/"$new_theme")
new_term_accent_color=$(jq -r ".term_accent" /home/$user/theme/my_themes/"$new_theme")
new_term_font_color=$(jq -r ".term_font" /home/$user/theme/my_themes/"$new_theme")
new_wallpaper=$(jq -r ".wallpaper" /home/$user/theme/my_themes/"$new_theme")

# Use double quotes to prevent issues with variables
echo "{
  \"accent\": \"$new_accent_color\",
  \"font\": \"$new_font_color\",
  \"bg\": \"$new_bg_color\",
  \"term_accent\": \"$new_term_accent_color\",
  \"term_font\": \"$new_term_font_color\",
  \"wallpaper\": \"$new_wallpaper\"
}" > /home/$user/theme/current_colors.json

# Backup configuration
backup_dir="/home/$user/theme/config_backup"
mkdir -p "$backup_dir"
for dir in ".config" ".vim" ".mozilla"; do
    sudo cp -r "/home/$user/$dir" "$backup_dir"
done
sudo cp -r /usr/share/sddm/themes/simple-sddm-2/ "$backup_dir"

# Change wallpaper
swww img --resize crop -t random $new_wallpaper
magick $new_wallpaper  -blur 0x30 /home/$user/.config/wlogout/icons/blur.jpg
sudo rm -f  /usr/share/sddm/themes/simple-sddm-2/Backgrounds/wallpaper.jpg
sudo cp $new_wallpaper /usr/share/sddm/themes/simple-sddm-2/Backgrounds/wallpaper.jpg
# Replace colors in specified directories
target_dirs=(
"/home/$user/.config/hypr/hyprland.conf"
"/home/$user/.config/kitty/themes/gruvbox_dark.conf"
"/home/$user/.config/waybar/style.css"
"/home/$user/.config/eww/eww.scss"
"/home/$user/.config/oh-my-posh/custom.json"
"/home/$user/.config/wlogout/style.css"
"/home/$user/.config/rofi/config.rasi"
"/home/$user/.config/ranger/colorschemes/custom.py"
"/home/$user/.config/inori/config.toml"
"/home/$user/.config/swaync/style.css"
"/home/$user/.config/system24/theme/flavors/rosepine.theme.css"
"/home/$user/.config/system24/theme/system24.theme.css"
"/home/$user/.vim/colors/custom_theme.vim"
"/usr/share/sddm/themes/simple-sddm-2/theme.conf"
"/home/$user/.mozilla/firefox/"
)

for dir in "${target_dirs[@]}"; do
    sudo find "$dir" -type f -exec sed -i \
    -e "s/$old_font_color/$new_font_color/g" \
    -e "s/$old_bg_color/$new_bg_color/g" \
    -e "s/$old_accent_color/$new_accent_color/g" {} +
done

echo "DIR 38;2;$(dye -x rgb "$new_accent_color" | tr -d "rgb()," | sed "s/ /;/g")" | sudo tee /home/$user/.config/dircolor > /dev/null

sudo sed -i "s/$old_term_accent_color/$new_term_accent_color/g" /home/$user/.config/ranger/colorschemes/custom.py
sudo sed -i "s/$old_term_font_color/$new_term_font_color/g" /home/$user/.config/ranger/colorschemes/custom.py

# Fix permissions
for dir in ".mozilla" ".config" "theme/config_backup/.mozilla" "theme/config_backup/.config" "theme/config_backup/.vim"; do
    sudo chown -R $user:$user "/home/$user/$dir"
done

# Restart Waybar & SwayNC
pkill waybar && hyprctl dispatch exec waybar & >/dev/null
pkill swaync && hyprctl dispatch exec swaync & >/dev/null
eval "$(dircolors  /home/$user/.config/dircolor)"
kill -SIGUSR1 $(pgrep kitty)
