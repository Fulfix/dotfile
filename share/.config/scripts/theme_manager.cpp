#include <iostream>
#include <fstream>
#include <cstring>
#include <cstdio>
#include <string>
#include <unordered_map>
#include <array>
#include <vector>
#include <filesystem>
#include <cstdlib>
#include <unistd.h>
#include <signal.h>
#include <sstream>
#include <algorithm>
#include <memory>
#include <exception>

namespace fs = std::filesystem;
using namespace std;


string exec(const char* cmd) {
    array<char, 128> buffer;
    string result;
    unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

// Fonction améliorée pour vider les terminaux Kitty inactifs

// Structure pour stocker les couleurs
struct ColorScheme {
    string foreground;
    string accent;
    string background;
};

struct RGB {
    int red;
    int green;
    int blue;
};

RGB hex_to_rgb(const string& hex_color){
    array<int, 6> jsp;
    int counter = 0;
    for (char i : hex_color){
        if (i == 'f'){
            jsp[counter] = 15;
        }
        else if (i == 'e'){
            jsp[counter] = 14;
        }
        else if (i == 'd'){
            jsp[counter] = 13;
        }
        else if (i == 'c'){
            jsp[counter] = 12;
        }
        else if (i == 'b'){
            jsp[counter] = 11;
        }
        else if (i == 'a'){
            jsp[counter] = 10;
        }
        else{
            jsp[counter] = i - '0';
        }
        counter++;
    }
    struct RGB output;
    output.red = (jsp[0] * 16) + jsp[1];  // Le premier caractère * 16 et le deuxième ajouté
    output.green = (jsp[2] * 16) + jsp[3];
    output.blue = (jsp[4] * 16) + jsp[5];
    return output;
}

// Fonction pour exécuter une commande et obtenir sa sortie

// Fonction pour exécuter une commande en arrière-plan
void exec_background(const string& cmd) {
    string full_cmd = cmd + " > /dev/null 2>&1 &";
    system(full_cmd.c_str());
}

// Fonction pour extraire les couleurs d'une image
ColorScheme extractColors(const string& imagePath) {
    ColorScheme colors;
    
    // Préparer la commande avec une taille sécurisée
    string home = string(getenv("HOME"));
    string command = "ricemood -i " + imagePath + " -f " + home + "/.config/ricemood 2>/dev/null";
    
    // Exécuter la commande et capturer la sortie
    FILE *fp = popen(command.c_str(), "r");
    if (fp == nullptr) {
        cerr << "Échec de l'exécution de la commande" << endl;
        exit(1);
    }
    
    // Lire les couleurs
    array<char, 7> buffer;
    int lineCount = 0;
    while (fgets(buffer.data(), buffer.size(), fp) != nullptr) {
        lineCount++;
        if (lineCount == 1) {
            colors.foreground = buffer.data();
        } else if (lineCount == 3) {
            colors.accent = buffer.data();
        } else if (lineCount == 5) {
            colors.background = buffer.data();
        }

    }
    
    // Fermer le pipe
    pclose(fp);
    
    // Cas spécial pour cette image
    if (imagePath ==  home + "/.config/wallpaper/clannad.jpg") {
        colors.accent = "965942";
    }
    if (colors.accent.length() != 6 ||colors.background.length() != 6 ||colors.foreground.length() != 6 ){
        cerr << "an error occurred with ricemood" << endl;
        exit(1);
    }
    return colors;
}

// Fonction pour écrire dans un fichier
bool writeToFile(const string& filePath, const string& content) {
    ofstream file(filePath);
    if (!file.is_open()) {
        cerr << "Erreur lors de la création du fichier " << filePath << endl;
        return false;
    }
    file << content;
    file.close();
    return true;
}

// Fonction principale pour générer les fichiers de configuration
bool generateConfigFiles(const string& imagePath, const ColorScheme& colors) {
    RGB rgb_background = hex_to_rgb(colors.background);
    // Extraction du nom de base de l'image
    size_t lastSlash = imagePath.find_last_of("/");
    string basename_wallpaper = imagePath.substr(lastSlash + 1);
    string home = string(getenv("HOME"));
    
    // Table de hachage pour stocker les paires fichier/contenu
    unordered_map<string, string> configFiles;
    
    // Préparer le contenu pour chaque fichier
    configFiles[home + "/.config/colors.css"] = 
        "@define-color foreground #" + colors.foreground + ";\n" +
        "@define-color background #" + colors.background + ";\n" +
        "@define-color rgbabackground " + "rgba(" + to_string(rgb_background.red) + ", " + to_string(rgb_background.green) + ", " + to_string(rgb_background.blue) + ", 0.8);\n"
        "@define-color accent #" + colors.accent + ";\n";
    
    configFiles[ home + "/.config/oh-my-posh/custom.json"] = 
        "{\n"
        "  \"$schema\": \"https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json\",\n"
        "  \"palette\": {\n"
        "    \"background\": \"0\",\n"
        "    \"accent\": \"11\",\n"
        "    \"font\": \"7\"\n"
        "  },\n"
        "  \"blocks\": [\n"
        "    {\n"
        "      \"type\": \"prompt\",\n"
        "      \"alignment\": \"left\",\n"
        "      \"newline\": false,\n"
        "      \"segments\": [\n"
        "        {\n"
        "          \"background\": \"p:background\",\n"
        "          \"foreground\": \"p:font\",\n"
        "          \"style\": \"powerline\",\n"
        "          \"powerline_symbol\": \"\",\n"
        "          \"template\": \" {{.HostName}} \",\n"
        "          \"type\": \"session\"\n"
        "        },\n"
        "        {\n"
        "          \"background\": \"p:accent\",\n"
        "          \"foreground\": \"p:font\",\n"
        "          \"style\": \"powerline\",\n"
        "          \"powerline_symbol\": \"\",\n"
        "          \"template\": \"{{.UserName}} \",\n"
        "          \"type\": \"session\"\n"
        "        },\n"
        "        {\n"
        "          \"background\": \"p:font\",\n"
        "          \"foreground\": \"p:background\",\n"
        "          \"style\": \"powerline\",\n"
        "          \"powerline_symbol\": \"\",\n"
        "          \"properties\": {\n"
        "            \"folder_icon\": \"\\uf07b\",\n"
        "            \"home_icon\": \"\\ueb06\"\n"
        "          },\n"
        "          \"template\": \"[{{.Path}}] \",\n"
        "          \"type\": \"path\"\n"
        "        }\n"
        "      ]\n"
        "    }\n"
        "  ],\n"
        "  \"console_title_template\": \"{{if .Root}}[root] {{end}}{{.Shell}} in <{{.Folder}}>\",\n"
        "  \"final_space\": true,\n"
        "  \"version\": 3\n"
        "}\n";
    
    // Contenu pour le fichier inori
    //configFiles[ home + "/.config/inori/config.toml"] = 
    //    "[theme.item_highlight_active]\n"
    //    "fg = \"#" + colors.foreground + "\"\n"
    //    "bg = \"#" + colors.accent + "\"\n\n"
    //    "[theme.item_highlight_inactive]\n"
    //    "fg = \"#" + colors.foreground + "\"\n"
    //    "bg = \"#" + colors.accent + "\"\n\n"
    //    "[theme.status_artist]\n"
    //    "fg = \"#" + colors.foreground + "\"\n"
    //    "bg = \"#" + colors.background + "\"\n\n"
    //    "[theme.status_album]\n"
    //    "fg = \"#" + colors.foreground + "\"\n"
    //    "bg = \"#" + colors.background + "\"\n\n"
    //    "[theme.album]\n"
    //    "fg = \"#" + colors.foreground + "\"\n"
    //    "bg = \"#" + colors.background + "\"\n\n"
    //    "[theme.playing]\n"
    //    "fg = \"#" + colors.accent + "\"\n\n"
    //    "[theme.paused]\n"
    //    "fg = \"#" + colors.accent + "\"\n"
    //    "bg = \"#" + colors.background + "\"\n\n"
    //    "[theme.stopped]\n"
    //    "fg = \"#" + colors.accent + "\"\n"
    //    "bg = \"#" + colors.accent + "\"\n\n"
    //    "[theme.slash_span]\n"
    //    "fg = \"#" + colors.accent + "\"\n"
    //    "bg = \"#" + colors.accent + "\"\n\n"
    //    "[theme.search_query_active]\n"
    //    "fg = \"#" + colors.accent + "\"\n"
    //    "bg = \"#" + colors.accent + "\"\n\n"
    //    "[theme.search_query_inactive]\n"
    //    "fg = \"#" + colors.accent + "\"\n"
    //    "bg = \"#" + colors.accent + "\"\n\n"
    //    "[theme.block_active]\n"
    //    "fg = \"#" + colors.accent + "\"\n";
    
    configFiles[ home + "/.config/eww/colors.scss"] = 
        "$background: #" + colors.background + ";\n"
        "$foreground: #" + colors.foreground + ";\n"
        "$accent: #" + colors.accent + ";\n";
    
    configFiles[ home + "/.config/hypr/colors.conf"] = 
        "$foreground = rgb(" + colors.foreground + ")\n"
        "$background = rgb(" + colors.background + ")\n";
    
    configFiles[ home + "/.config/kitty/kitty.conf"] = 
        "map cmd+c        copy_to_clipboard\n"
        "map cmd+v        paste_from_clipboard\n"
        "map super+backspace send_text all \x17\n"
        "map alt+k send_key up\n"
        "map alt+j send_key down\n"
        "map alt+h send_key left\n"
        "map alt+l send_key right\n"
        "map super+shift+h send_key alt+left\n"
        "map super+shift+l send_key alt+right\n"
        "enable_audio_bell no\n"
        "font_family      family='FiraCode Nerd Font' postscript_name=FiraCodeNF-Med\n"
        "bold_font        auto\n"
        "italic_font      auto\n"
        "bold_italic_font auto\n"
        "color0 #" + colors.background + "\n"
        "color11 #" + colors.accent+ "\n"
        "color7 #" + colors.foreground+ "\n"
        "background   #" + colors.background + "\n" 
        "foreground   #" + colors.foreground + "\n";
    configFiles[ home + "/.config/rofi/colors.rasi"] = 
        "* {\n"
        "    accent: #" + colors.accent + ";\n"
        "    rgbabackground: rgba(" + to_string(rgb_background.red) + ", " + to_string(rgb_background.green) + ", " + to_string(rgb_background.blue) + ", 0.8);\n"
        "    foreground: #" + colors.foreground + ";\n"
        "}";
    
    configFiles[ home + "/.cache/wal/colors.json"] = 
        "{\n"
        "    \"wallpaper\": \"" + imagePath + "\",\n"
        "    \"alpha\": \"100\",\n\n"
        "    \"special\": {\n"
        "        \"background\": \"#ffffff\",\n"
        "        \"foreground\": \"#ffffff\",\n"
        "        \"cursor\": \"#ffffff\"\n"
        "    },\n"
        "    \"colors\": {\n"
        "        \"color0\": \"#" + colors.background + "\",\n"
        "        \"color1\": \"#ffffff\",\n"
        "        \"color2\": \"#ffffff\",\n"
        "        \"color3\": \"#ffffff\",\n"
        "        \"color4\": \"#ffffff\",\n"
        "        \"color5\": \"#ffffff\",\n"
        "        \"color6\": \"#ffffff\",\n"
        "        \"color7\": \"#ffffff\",\n"
        "        \"color8\": \"#ffffff\",\n"
        "        \"color9\": \"#" + colors.accent + "\",\n"
        "        \"color10\": \"#ffffff\",\n"
        "        \"color11\": \"#ffffff\",\n"
        "        \"color12\": \"#ffffff\",\n"
        "        \"color13\": \"#ffffff\",\n"
        "        \"color14\": \"#ffffff\",\n"
        "        \"color15\": \"#" + colors.foreground + "\"\n"
        "    }\n"
        "}";
    
    configFiles[ home + "/.config/nvim/colors/colors-wal.vim"] = 
        "\" Nom du thème\n"
        "set background=dark\n"
        "highlight clear\n"
        "if exists(\"syntax_on\")\n"
        "    syntax reset\n"
        "endif\n"
        "let g:colors_name=\"custom_theme\"\n\n"
        "\" Configuration des numéros de ligne\n"
        "set number\n"
        "set nocursorline\n\n"
        "\" Interface générale\n"
        "hi Normal guifg=#" + colors.foreground + " guibg=NONE\n"
        "hi LineNr guifg=#" + colors.foreground + "\n"
        "hi CursorLine NONE ctermbg=NONE guibg=NONE\n"
        "hi CursorLineNr guifg=#" + colors.accent + " gui=NONE cterm=NONE\n"
        "hi Visual guibg=#" + colors.accent + "\n\n"
        "\" Syntaxe\n"
        "hi Comment guifg=#" + colors.accent + "\n"
        "hi String guifg=#" + colors.foreground + "\n"
        "hi Number guifg=#" + colors.foreground + "\n"
        "hi Function guifg=#" + colors.foreground + "\n"
        "hi Keyword guifg=#" + colors.accent + "\n"
        "hi Statement guifg=#" + colors.accent + "\n"
        "hi Identifier guifg=#" + colors.foreground + "\n"
        "hi PreProc guifg=#" + colors.accent + "\n"
        "hi Type guifg=#" + colors.foreground + "\n"
        "hi Special guifg=#" + colors.foreground + "\n"
        "hi Error guifg=#" + colors.foreground + " guibg=#" + colors.accent + "\n\n"
        "\" Menus et statut\n"
        "hi StatusLine guifg=#" + colors.foreground + " guibg=#" + colors.accent + "\n"
        "hi StatusLineNC guifg=#" + colors.accent + " guibg=#" + colors.accent + "\n"
        "hi VertSplit guifg=#" + colors.accent + " guibg=#" + colors.accent + "\n"
        "hi Pmenu guifg=#" + colors.foreground + " guibg=#" + colors.accent + "\n"
        "hi PmenuSel guifg=#" + colors.accent + " guibg=#" + colors.foreground + "\n";
    
    configFiles[ home + "/.config/theme.conf"] =  "[General]\n"
        "MainColor=\"#" + colors.accent + "\"\n"
        "AccentColor=\"#" + colors.accent + "\"\n"
        "IconColor=\"#" + colors.accent + "\"\n"
        "Background=\"Backgrounds/" + basename_wallpaper + "\"\n"
        "DimBackgroundImage=\"0.0\"\n"
        "ScaleImageCropped=\"true\"\n"
        "FullBlur=\"true\"\n"
        "PartialBlur=\"false\"\n"
        "BlurRadius=\"100\"\n"
        "HaveFormBackground=\"false\"\n"
        "FormPosition=\"left\"\n"
        "BackgroundImageHAlignment=\"center\"\n"
        "BackgroundImageVAlignment=\"center\"\n"
        "OverrideTextFieldColor=\"#ffffff\"\n"
        "OverrideLoginButtonTextColor=\"#ffffff\"\n"
        "InterfaceShadowSize=\"6\"\n"
        "InterfaceShadowOpacity=\"0.6\"\n"
        "RoundCorners=\"16\"\n"
        "ScreenPadding=\"0\"\n"
        "Font=\"FiraCode NerdFont\"\n"
        "FontSize=\"\"\n"
        "HideLoginButton=\"true\"\n"
        "ForceRightToLeft=\"false\"\n"
        "ForceLastUser=\"true\"\n"
        "ForcePasswordFocus=\"true\"\n"
        "ForceHideCompletePassword=\"true\"\n"
        "ForceHideVirtualKeyboardButton=\"true\"\n"
        "ForceHideSystemButtons=\"false\"\n"
        "AllowEmptyPassword=\"false\"\n"
        "AllowBadUsernames=\"false\"\n"
        "Locale=\"\"\n"
        "HourFormat=\"HH:mm\"\n"
        "DateFormat=\"dddd, MMMM ,d\"\n"
        "HeaderText=\"I like banana\"\n"
        "TranslatePlaceholderUsername=\"\"\n"
        "TranslatePlaceholderPassword=\"\"\n"
        "TranslateLogin=\"\"\n"
        "TranslateLoginFailedWarning=\"\"\n"
        "TranslateCapslockWarning=\"\"\n"
        "TranslateSuspend=\"\"\n"
        "TranslateHibernate=\"\"\n"
        "TranslateReboot=\"\"\n"
        "TranslateShutdown=\"\"\n"
        "TranslateVirtualKeyboardButton=\"\"";
    // Écrire les fichiers
    bool success = true;
    for (const auto& [path, content] : configFiles) {
        if (!writeToFile(path, content)) {
            success = false;
        }
    }
    char cmd[512]; 
    snprintf(cmd, sizeof(cmd), "for f in /dev/pts/[0-9]*; do     for i in 1 6; do         printf \"\\033]4;$i;rgb:66/55/49\007\" >> $f;     done; done", 
            rgb_background.red, rgb_background.green, rgb_background.blue);
    string jsp = exec(cmd);
    string lsoutput = exec("ls -l /dev/pts");
    return success;
}

// Fonction pour créer l'image floue pour wlogout

// Fonction pour redémarrer les services
void restartServices(const vector<string>& services) {
    for (const auto& service : services) {
        string kill_cmd = "pkill " + service;
        system(kill_cmd.c_str());
        
        if (service == "eww") {
            // Démarrer eww avec son option
            exec_background("eww open");
        } else {
            exec_background(service);
        }
    }
}

// Fonction pour obtenir la liste des wallpapers
vector<string> getWallpapers(const string& directory) {
    vector<string> wallpapers;
    for (const auto& entry : fs::directory_iterator(directory)) {
        if (entry.is_regular_file()) {
            string path = entry.path().string();
            string extension = entry.path().extension().string();
            if (extension == ".jpg" || extension == ".png") {
                wallpapers.push_back(entry.path().filename().string());
            }
        }
    }
    
    // Trier les wallpapers
    sort(wallpapers.begin(), wallpapers.end());
    
    return wallpapers;
}

// Fonction pour afficher le sélecteur rofi
string showRofiSelector(const vector<string>& items) {
    string home = string(getenv("HOME"));
    // Préparer la liste pour rofi
    //string item_list = "";
    //for (const auto& item : items) {
    //    item_list += item + "\n";
    //}
    //
    //// Écrire la liste dans un fichier temporaire
    //string temp_file = "/tmp/wallpaper_list.txt";
    //ofstream out(temp_file);
    //out << item_list;
    //out.close();
    
    // Afficher le menu rofi
    string cmd = "bash " + home + "/.config/scripts/rofi.sh";
    string selected = exec(cmd.c_str());
    
    // Supprimer les espaces et retours à la ligne
    selected.erase(remove(selected.begin(), selected.end(), '\n'), selected.end());
    selected.erase(remove(selected.begin(), selected.end(), '\r'), selected.end());
    
    return selected;
}

// Fonction principale
int main(int argc, char **argv) {
    string home = string(getenv("HOME"));
    if (getuid() == 0){
        cerr << "run this script with user privilege" << endl;
        return 1;
    }
    // Définition des variables
    string wallpaper_dir =  home + "/.config/wallpaper/";
    vector<string> services_to_restart = {"waybar", "eww", "swaync"};
    
    string selected_wallpaper;
    string full_path_wallpaper;
    
    // Si un argument est fourni, utiliser ce chemin
    if (argc == 2) {
        full_path_wallpaper = argv[1];
    } else {
        // Sinon, afficher le sélecteur rofi
        vector<string> wallpapers = getWallpapers(wallpaper_dir);
        
        if (wallpapers.empty()) {
            cerr << "Aucun wallpaper trouvé dans " << wallpaper_dir << endl;
            return 1;
        }
        
        selected_wallpaper = showRofiSelector(wallpapers);
        full_path_wallpaper = wallpaper_dir + selected_wallpaper;
        
        // Vérification du fichier
        if (!fs::exists(full_path_wallpaper)) {
            cerr << "Sélectionnez un wallpaper correct" << endl;
            return 1;
        }
    }
    
    
    // Extraire les couleurs du wallpaper
    ColorScheme colors = extractColors(full_path_wallpaper);
    
    // Générer les fichiers de configuration
    if (!generateConfigFiles(full_path_wallpaper, colors)) {
        cerr << "Erreur lors de la génération des fichiers de configuration" << endl;
        return 1;
    }
    
    // Définir le fond d'écran
    exec_background("swww img \"" + full_path_wallpaper + "\" --transition-type none");
    
    // Redémarrer les services en parallèle
    restartServices(services_to_restart);
    
    // Envoyer un signal à kitty sans utiliser pgrep
    string kitty_cmd = "pidof kitty | xargs -r kill -SIGUSR1";
    system(kitty_cmd.c_str());
    
    // Mettre à jour Firefox avec pywalfox en arrière-plan
    exec_background("pywalfox update");
    
    // Mettre à jour oh-my-posh
    system("eval \"$(oh-my-posh init bash --config $HOME/.config/oh-my-posh/custom.json)\"");
    
    // Démarrer l'horloge en arrière-plan
    exec_background("eww o bg_clock");
    return 0;
}

