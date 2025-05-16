" Nom du thème
set background=dark
highlight clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name="custom_theme"

" Configuration des numéros de ligne
set number
set nocursorline

" Interface générale
hi Normal guifg=#D7A2AD guibg=NONE
hi LineNr guifg=#D7A2AD
hi CursorLine NONE ctermbg=NONE guibg=NONE
hi CursorLineNr guifg=#A45C6B gui=NONE cterm=NONE
hi Visual guibg=#A45C6B

" Syntaxe
hi Comment guifg=#A45C6B
hi String guifg=#D7A2AD
hi Number guifg=#D7A2AD
hi Function guifg=#D7A2AD
hi Keyword guifg=#A45C6B
hi Statement guifg=#A45C6B
hi Identifier guifg=#D7A2AD
hi PreProc guifg=#A45C6B
hi Type guifg=#D7A2AD
hi Special guifg=#D7A2AD
hi Error guifg=#D7A2AD guibg=#A45C6B

" Menus et statut
hi StatusLine guifg=#D7A2AD guibg=#A45C6B
hi StatusLineNC guifg=#A45C6B guibg=#A45C6B
hi VertSplit guifg=#A45C6B guibg=#A45C6B
hi Pmenu guifg=#D7A2AD guibg=#A45C6B
hi PmenuSel guifg=#A45C6B guibg=#D7A2AD
