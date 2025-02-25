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
hi Normal guifg=#ffffff guibg=NONE
hi LineNr guifg=#ffffff
hi CursorLine NONE ctermbg=NONE guibg=NONE
hi CursorLineNr guifg=#6E93CB gui=NONE cterm=NONE
hi Visual guibg=#6E93CB

" Syntaxe
hi Comment guifg=#6E93CB
hi String guifg=#ffffff
hi Number guifg=#ffffff
hi Function guifg=#ffffff
hi Keyword guifg=#6E93CB
hi Statement guifg=#6E93CB
hi Identifier guifg=#ffffff
hi PreProc guifg=#6E93CB
hi Type guifg=#ffffff
hi Special guifg=#ffffff
hi Error guifg=#ffffff guibg=#6E93CB

" Menus et statut
hi StatusLine guifg=#ffffff guibg=#6E93CB
hi StatusLineNC guifg=#6E93CB guibg=#6E93CB
hi VertSplit guifg=#6E93CB guibg=#6E93CB
hi Pmenu guifg=#ffffff guibg=#6E93CB
hi PmenuSel guifg=#6E93CB guibg=#ffffff
