#!/bin/bash

# Display functions with colors
printr() {
    printf "\033[31m%s\033[0m\n" "$1"
}

printb() {
    printf "\033[34m%s\033[0m\n" "$1"
}

printg() {
    printf "\033[32m%s\033[0m\n" "$1"
}


# Checking the dotfiles directory
if [ ! -d "share/.config" ]; then
    printr "You must run this script in the dotfiles directory"
    exit 1
else
    root_dir=$(pwd)
fi
# Creating the cloned directory if it doesn't exist
if [ ! -d "cloned" ]; then
    mkdir -p cloned
fi

# Installing configurations

install_config() {
    # Creating the cache/wal directory if it doesn't exist
    if [ ! -d "$HOME/.cache/wal" ]; then
        mkdir -p ~/.cache/wal
    fi

    # Creating the config directory if it doesn't exist
    if [ ! -d "$HOME/.config" ]; then
        mkdir "$HOME/.config"
    fi

    # Backing up existing configurations
    if ! cp -rf "$HOME/.config" "$HOME/backup"; then
        printr "An error occurred while backing up .config"
        exit 1
    fi

    if ! cp -f "$HOME/.bashrc" "$HOME/backup"; then
        printr "An error occurred while backing up .bashrc"
        exit 1
    fi

    # Copying new configurations
    cp -f share/.bashrc "$HOME/"
    cp -rf share/.config "$HOME/"

    # Asking for and inserting the password
    password=""
    read -p "Enter your password: " password
    sed -i "s/your_password/$password/g" ~/.config/hypr/hyprland.conf
    sed -i "s/your_password/$password/g" ~/.config/waybar/config.jsonc

    # Installing the SDDM theme
    if [ ! -d /usr/share/sddm/themes ]; then
        sudo mkdir -p /usr/share/sddm/themes
    fi

    # Cloning the simple-sddm-2 theme
    cd share
    git clone https://github.com/Fulfix/simple-sddm-2
    cd $root_dir

    # Copying the theme and configuring permissions
    sudo cp -rf share/simple-sddm-2 /usr/share/sddm/themes
    sudo chown -R root:root /usr/share/sddm/themes/simple-sddm-2

    # Creating the Backgrounds directory if it doesn't exist
    sudo mkdir -p /usr/share/sddm/themes/simple-sddm-2/Backgrounds

    # Checking and copying wallpapers
    if [ -d "$HOME/.config/wallpaper" ] && [ "$(ls -A $HOME/.config/wallpaper 2>/dev/null)" ]; then
        sudo cp -rf $HOME/.config/wallpaper/* /usr/share/sddm/themes/simple-sddm-2/Backgrounds/
    else
        printb "Warning: The wallpaper directory is empty or doesn't exist."
        mkdir -p $HOME/.config/wallpaper
    fi

    # Configuring SDDM
    if [ ! -d /etc/sddm.conf.d ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi
    sudo cp -f share/simple-sddm-2.conf /etc/sddm.conf.d

    # Installing vim-plug for Neovim
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    nvim +PlugInstall +qall

    # Installing markdown-preview for Neovim
    cd ~/.local/share/nvim/plugged/markdown-preview.nvim
    npm install
    cd $root_dir

    # Activating the MPD service
    systemctl --user enable mpd
    systemctl --user start mpd
    printf "Lanczos3\n$HOME/.config/wallpaper/clannad.jpg" > $HOME/.cache/swww/Virtual-1

    # Activating SDDM
    printb "Disable your current display manager to continue"
    read
    sudo systemctl enable sddm

    printb "Restart your computer to finalize the installation"
}

# Checking internet connection
check_internet() {
    printb "Checking internet connection..."
    # Testing multiple sites for reliability
    if ! curl -s --connect-timeout 5 https://www.google.com >/dev/null && \
       ! curl -s --connect-timeout 5 https://www.cloudflare.com >/dev/null && \
       ! ping -c 2 -W 2 1.1.1.1 >/dev/null 2>&1; then
        printr "Error: Please check your internet connection"
        exit 1
    else
        printg "Internet connection is working"
    fi
}

# Checking for updates based on distribution
check_update() {
    printb "Checking for system updates..."
    case "$1" in
        "fedora")
            sudo dnf check-update >/dev/null 2>&1
            # dnf check-update returns 0 if there are no updates and 100 if there are
            if [ $? -eq 1 ]; then  # So we check for 1 which is a real error
                printb "Problem while checking for updates."
                read -p "Press Enter to continue anyway..."
            fi
            ;;
        "arch")
            if ! sudo pacman -Sy >/dev/null 2>&1; then
                printb "Problem while updating repositories."
                read -p "Press Enter to continue anyway..."
            fi
            ;;
        "alpine")
            if ! sudo apk update >/dev/null 2>&1; then
                printb "Problem while updating repositories."
                read -p "Press Enter to continue anyway..."
            fi
            ;;
    esac
}

# Function for compiling git repositories with Cargo
build_cargo_project() {
    local repo_url="$1"
    local repo_dir="$2"
    local bin_name="$3"
    local cargo_args="$4"

    cd cloned || return 1

    if [ ! -d "$repo_dir" ]; then
        printb "Cloning $repo_url..."
        git clone "$repo_url" "$repo_dir" || return 1
    else
        printb "The repository $repo_dir already exists, checking for updates..."
        cd "$repo_dir" || return 1
        sudo git pull || return 1
        cd ..
    fi

    cd "$repo_dir" || return 1
    printb "Compiling $bin_name..."
    cargo build --release $cargo_args || return 1
    chmod +x "target/release/$bin_name" || return 1
    sudo cp -f "target/release/$bin_name" /usr/local/bin/ || return 1

    if [ "$bin_name" = "swww" ]; then
        # Also copying swww-daemon for swww
        sudo cp -f "target/release/swww-daemon" /usr/local/bin/ || return 1
    fi

    cd ../.. || return 1
    return 0
}

# Installation for Fedora
fedora() {
    check_internet
    check_update "fedora"
    printb "Installing packages for Fedora..."

    # Common packages for all architectures
    common_packages="fastfetch kitty hyprland mpd mpc neovim rofi-wayland waybar wlogout sddm cargo npm git python3-pip flatpak lz4-devel glib2-devel gtk3-devel libdbusmenu-gtk3-devel gtk-layer-shell-devel  gcc-c++ kwin lsd"

    if [[ "$(uname -m)" == "aarch64" ]]; then
	    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y $common_packages SwayNotificationCenter firefox
        if [ $? -ne 0 ]; then
            printr "Error while installing packages"
            exit 1
        fi

        # Building cargo projects
        if ! swww -V; then
            build_cargo_project "https://github.com/LGFae/swww" "swww" "swww" "" || printr "Error while compiling swww"

        fi
        if ! eww -V; then
            build_cargo_project "https://github.com/elkowar/eww" "eww" "eww" "--no-default-features --features=wayland" || printr "Error while compiling eww"
        fi
        build_cargo_project "https://github.com/Fulfix/inori" "inori" "inori" || printr "Error while compiling inori"

        # Installing hyprshot
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
            printb "After the installation has finished, install textfox using tf-install.sh"
        fi

    elif [[ "$(uname -m)" == "x86_64" ]]; then
        sudo dnf install -y $common_packages SwayNotificationCenter hyprshot librewolf
        if [ $? -ne 0 ]; then
            printr "Error while installing packages"
            exit 1
        fi

        # Building cargo projects
        build_cargo_project "https://github.com/LGFae/swww" "swww" "swww" "" || printr "Error while compiling swww"
        build_cargo_project "https://github.com/Fulfix/inori" "inori" "inori" "-r" || printr "Error while compiling inori"
        build_cargo_project "https://github.com/elkowar/eww" "eww" "eww" "--no-default-features --features=wayland" || printr "Error while compiling eww"

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
            printb "After the installation has finished, install textfox using tf-install.sh"
        fi

    fi

    # Actions common to both architectures
    sudo cp -f share/FiraCodeNerdFont-Medium.ttf /usr/share/fonts/ || printr "Error while copying the font"
    sudo cp -rf share/Bibata-Modern-Classic /usr/share/icons/ || printr "Error while copying the icons"
    sudo mkdir -p /usr/share/icons/default/ || printr "Error while creating the default icons directory"
    sudo cp -rf share/Bibata-Modern-Classic/* /usr/share/icons/default/ || printr "Error while copying the default icons"

    # Installing OhMyPosh
    printb "Installing OhMyPosh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s || printr "Error while installing OhMyPosh"


    # Installing ricemood
    printb "Installing ricemood..."
    sudo npm install -g ricemood || printr "Error while installing ricemood"


    install_config
    g++ ~/.config/scripts/theme_manager.cpp -o ~/.config/scripts/wp
    printg "Installation completed successfully!"
}

# Installation for Arch
arch() {
    printr "no!"
    exit 1
}
alpine() {
    printr "no!"
    exit 1
}

# Handling other distributions
other() {
    check_internet
    printr "This distribution is not directly supported by this script."
    printb "Here are the packages to install manually:"
    cat << EOF
- fastfetch (system information display)
- kitty (terminal)
- hyprland (window manager)
- mpd/mpc (music playback)
- neovim (text editor)
- rofi or rofi-wayland (application launcher)
- swaync or SwayNotificationCenter (notifications)
- waybar (status bar)
- wlogout (logout menu)
- sddm (display manager)
- cargo (to compile swww, inori, eww)
- git (to clone repositories)
- npm (to install ricemood)
- pip (to install pywalfox)

You will also need to manually compile:
- swww (https://github.com/LGFae/swww)
- inori (https://github.com/Fulfix/inori)
- eww (https://github.com/elkowar/eww)
- hyprshot (https://github.com/Gustash/hyprshot.git)

And install:
- OhMyPosh (curl -s https://ohmyposh.dev/install.sh | bash -s)
- pywalfox (pip install --index-url https://test.pypi.org/simple/ pywalfox==2.8.0rc1)
- ricemood (npm install -g ricemood)
EOF
}

# Main menu
echo "===== Hyprland Environment Installation Script ====="
echo ""

# Display the menu and get the choice
PS3="Which distribution are you using? "
select DISTRO in "fedora" "arch" "alpine" "other" "quit"; do
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
        "quit")
            printb "Installation cancelled."
            exit 0
            ;;
        *)
            printr "Invalid option, please try again."
            ;;
    esac
done

exit 0
