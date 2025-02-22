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
hi Normal guifg=#f6ec80 guibg=NONE
hi LineNr guifg=#f6ec80
hi CursorLine NONE ctermbg=NONE guibg=NONE
hi CursorLineNr guifg=#965942 gui=NONE cterm=NONE
hi Visual guibg=#965942

" Syntaxe
hi Comment guifg=#965942
hi String guifg=#f6ec80
hi Number guifg=#f6ec80
hi Function guifg=#f6ec80
hi Keyword guifg=#965942
hi Statement guifg=#965942
hi Identifier guifg=#f6ec80
hi PreProc guifg=#965942
hi Type guifg=#f6ec80
hi Special guifg=#f6ec80
hi Error guifg=#f6ec80 guibg=#965942

" Menus et statut
hi StatusLine guifg=#f6ec80 guibg=#965942
hi StatusLineNC guifg=#965942 guibg=#965942
hi VertSplit guifg=#965942 guibg=#965942
hi Pmenu guifg=#f6ec80 guibg=#965942
hi PmenuSel guifg=#965942 guibg=#f6ec80
