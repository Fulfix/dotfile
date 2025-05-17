#!/bin/bash

# Fonctions d'affichage avec couleurs
printr() {
    printf "\033[31m%s\033[0m\n" "$1"
}

printb() {
    printf "\033[34m%s\033[0m\n" "$1"
}

printg() {
    printf "\033[32m%s\033[0m\n" "$1"
}


# Vérification du dossier de dotfiles
if [ ! -d "share/.config" ]; then
    printr "Vous devez exécuter ce script dans le répertoire des dotfiles"
    exit 1
else
    root_dir=$(pwd)
fi
# Création du dossier cloned s'il n'existe pas
if [ ! -d "cloned" ]; then
    mkdir -p cloned
fi

# Installation des configurations
install_config() {
    if [ ! -d "$HOME/.cache/wal" ]; then
        mkdir -p ~/.cache/wal
    fi
    if [ ! -d "$HOME/.config" ]; then
        mkdir "$HOME/.config"
    fi
    if ! cp -rf "$HOME/.config" "$HOME/backup"; then
        printr "an error occured with the backup of .config"
        exit 1
    fi
    if ! cp -f "$HOME/.bashrc" "$HOME/backup"; then
        printr "an error occured with the backup of .bashrc"
        exit 1
    fi
    cp -f share/.bashrc "$HOME/"
    cp -rf share/.config "$HOME/"
    if [ ! -d /usr/share/sddm/themes ]; then
        sudo mkdir -p /usr/share/sddm/themes
    fi
    sudo cp -rf share/simple-sddm-2 /usr/share/sddm/themes
    sudo chown -R /usr/share/sddm/themes/simple-sddm-2
    if [ ! -d /etc/sddm.conf.d ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi
    sudo cp -f share/simple-sddm-2.conf /etc/sddm.conf.d
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    nvim +PlugInstall +qall
    cd ~/.local/share/nvim/plugged/markdown-preview.nvim
    npm install 
    cd $root_dir 
    systemctl --user enable mpd
    systemctl --user start mpd
    printb "disable your actual display manager to continue"
    read
    sudo systemctl enable sddm
    printb "reboot your computeur" 
}

# Vérification de la connexion internet
check_internet() {
    printb "Vérification de la connexion internet..."
    # Teste plusieurs sites pour plus de fiabilité
    if ! curl -s --connect-timeout 5 https://www.google.com >/dev/null && \
       ! curl -s --connect-timeout 5 https://www.cloudflare.com >/dev/null && \
       ! ping -c 2 -W 2 1.1.1.1 >/dev/null 2>&1; then
        printr "Erreur: Veuillez vérifier votre connexion internet"
        exit 1
    else
        printg "Connexion internet fonctionnelle"
    fi
}

# Vérification des mises à jour selon la distribution
check_update() {
    printb "Vérification des mises à jour du système..."
    case "$1" in
        "fedora")
            sudo dnf check-update >/dev/null 2>&1
            # dnf check-update renvoie 0 s'il n'y a pas de mise à jour et 100 s'il y en a
            if [ $? -eq 1 ]; then  # Donc on vérifie 1 qui est une vraie erreur
                printb "Problème lors de la vérification des mises à jour."
                read -p "Appuyez sur Entrée pour continuer quand même..."
            fi
            ;;
        "arch")
            if ! sudo pacman -Sy >/dev/null 2>&1; then
                printb "Problème lors de la mise à jour des dépôts."
                read -p "Appuyez sur Entrée pour continuer quand même..."
            fi
            ;;
        "alpine")
            if ! sudo apk update >/dev/null 2>&1; then
                printb "Problème lors de la mise à jour des dépôts."
                read -p "Appuyez sur Entrée pour continuer quand même..."
            fi
            ;;
    esac
}

# Fonction pour la compilation de dépôts git avec Cargo
build_cargo_project() {
    local repo_url="$1"
    local repo_dir="$2"
    local bin_name="$3"
    local cargo_args="$4"
    
    cd cloned || return 1
    
    if [ ! -d "$repo_dir" ]; then
        printb "Clonage de $repo_url..."
        git clone "$repo_url" "$repo_dir" || return 1
    else
        printb "Le dépôt $repo_dir existe déjà, vérification des mises à jour..."
        cd "$repo_dir" || return 1
        sudo git pull || return 1
        cd ..
    fi
    
    cd "$repo_dir" || return 1
    printb "Compilation de $bin_name..."
    cargo build --release $cargo_args || return 1
    chmod +x "target/release/$bin_name" || return 1
    sudo cp -f "target/release/$bin_name" /usr/local/bin/ || return 1
    
    if [ "$bin_name" = "swww" ]; then
        # Copie également swww-daemon pour swww
        sudo cp -f "target/release/swww-daemon" /usr/local/bin/ || return 1
    fi
    
    cd ../.. || return 1
    return 0
}

# Installation pour Fedora
fedora() {
    check_internet
    check_update "fedora"
    printb "Installation des paquets pour Fedora..."
    
    # Paquets communs pour toutes les architectures
    common_packages="fastfetch kitty hyprland mpd mpc neovim rofi-wayland waybar wlogout sddm cargo npm git python3-pip flatpak lz4-devel glib2-devel gtk3-devel libdbusmenu-gtk3-devel gtk-layer-shell-devel  gcc-c++ kwin lsd"
    
    if [[ "$(uname -m)" == "aarch64" ]]; then
	    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y $common_packages SwayNotificationCenter firefox
        if [ $? -ne 0 ]; then
            printr "Erreur lors de l'installation des paquets"
            exit 1
        fi
        
        # Construction des projets cargo
        if ! swww -V; then
            build_cargo_project "https://github.com/LGFae/swww" "swww" "swww" "" || printr "Erreur lors de la compilation de swww"

        fi
        if ! eww -V; then
            build_cargo_project "https://github.com/elkowar/eww" "eww" "eww" "--no-default-features --features=wayland" || printr "Erreur lors de la compilation de eww"
        fi
        build_cargo_project "https://github.com/Fulfix/inori" "inori" "inori" || printr "Erreur lors de la compilation de inori"

        # Installation de hyprshot
        cd cloned || exit 1
        if [ ! -d "Hyprshot" ]; then
            git clone https://github.com/Gustash/hyprshot.git Hyprshot
        else
            cd Hyprshot && git pull && cd ..
        fi
        sudo ln -sf "$(pwd)/Hyprshot/hyprshot" /usr/local/bin
        chmod +x Hyprshot/hyprshot
        cd $root_dir
        # install pywalfox

        pip install pywalfox
        pywalfox install
        if firefox about:profiles & >/dev/null 2>&1; then
            cd "$root_dir"/cloned
            git clone https://github.com/Fulfix/textfox
            cd textfox
            bash tf-install.sh
            cd $root_dir
        else
            printb "after the installation have finished install textfox using tf-install.sh"
        fi
        
    elif [[ "$(uname -m)" == "x86_64" ]]; then
        sudo dnf install -y $common_packages SwayNotificationCenter hyprshot librewolf
        if [ $? -ne 0 ]; then
            printr "Erreur lors de l'installation des paquets"
            exit 1
        fi
        
        # Construction des projets cargo
        build_cargo_project "https://github.com/LGFae/swww" "swww" "swww" "" || printr "Erreur lors de la compilation de swww"
        build_cargo_project "https://github.com/Fulfix/inori" "inori" "inori" "-r" || printr "Erreur lors de la compilation de inori"
        build_cargo_project "https://github.com/elkowar/eww" "eww" "eww" "--no-default-features --features=wayland" || printr "Erreur lors de la compilation de eww"

        #install pywalfox for librewolf
        pip install --index-url https://test.pypi.org/simple/ pywalfox==2.8.0rc1
        pywalfox install --browser librewolf
        if librewolf about:profiles & >/dev/null 2>&1; then
            cd "$root_dir"/cloned
            git clone https://github.com/Fulfix/textfox
            cd textfox
            bash tf-install.sh
            cd $root_dir
        else
            printb "after the installation have finished install textfox using tf-install.sh"
        fi

    fi
    
    # Actions communes aux deux architectures
    sudo cp -f share/FiraCodeNerdFont-Medium.ttf /usr/share/fonts/ || printr "Erreur lors de la copie de la police"
    sudo cp -rf share/Bibata-Modern-Classic /usr/share/icons/ || printr "Erreur lors de la copie des icônes"
    sudo mkdir -p /usr/share/icons/default/ || printr "Erreur lors de la création du dossier d'icônes par défaut"
    sudo cp -rf share/Bibata-Modern-Classic/* /usr/share/icons/default/ || printr "Erreur lors de la copie des icônes par défaut"
    
    # Installation de OhMyPosh
    printb "Installation de OhMyPosh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s || printr "Erreur lors de l'installation de OhMyPosh"
    
    
    # Installation de ricemood
    printb "Installation de ricemood..."
    sudo npm install -g ricemood || printr "Erreur lors de l'installation de ricemood"
    
    
    install_config
    g++ ~/.config/scripts/theme_manager.cpp -o ~/.config/scripts/wp
    printg "Installation terminée avec succès!"
}

# Installation pour Arch
arch() {
    printr "no!"
    exit 1 
}
alpine() {
    printr "no!"
    exit 1 
}

# Gestion des autres distributions
other() {
    check_internet
    printr "Cette distribution n'est pas prise en charge directement par ce script."
    printb "Voici les paquets à installer manuellement :"
    cat << EOF
- fastfetch (affichage d'informations système)
- kitty (terminal)
- hyprland (gestionnaire de fenêtres)
- mpd/mpc (lecture de musique)
- neovim (éditeur de texte)
- rofi ou rofi-wayland (lanceur d'applications)
- swaync ou SwayNotificationCenter (notifications)
- waybar (barre d'état)
- wlogout (menu de déconnexion)
- sddm (gestionnaire de connexion)
- cargo (pour compiler swww, inori, eww)
- git (pour cloner les dépôts)
- npm (pour installer ricemood)
- pip (pour installer pywalfox)

Vous devrez également compiler manuellement :
- swww (https://github.com/LGFae/swww)
- inori (https://github.com/Fulfix/inori)
- eww (https://github.com/elkowar/eww)
- hyprshot (https://github.com/Gustash/hyprshot.git)

Et installer :
- OhMyPosh (curl -s https://ohmyposh.dev/install.sh | bash -s)
- pywalfox (pip install --index-url https://test.pypi.org/simple/ pywalfox==2.8.0rc1)
- ricemood (npm install -g ricemood)
EOF
}

# Menu principal
echo "===== Script d'installation d'environnement Hyprland ====="
echo ""

# Afficher le menu et récupérer le choix
PS3="Quelle distribution utilisez-vous? "
select DISTRO in "fedora" "arch" "alpine" "other" "quitter"; do
    case $DISTRO in
        "fedora")
            fedora
            break
            ;;
        "arch")
            arch
            break
            ;;
        "alpine")
            alpine
            break
            ;;
        "other")
            other
            break
            ;;
        "quitter")
            printb "Installation annulée."
            exit 0
            ;;
        *)
            printr "Option invalide, veuillez réessayer."
            ;;
    esac
done

exit 0