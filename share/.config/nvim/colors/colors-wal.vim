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
hi Normal guifg=#F6EC80 guibg=NONE
hi LineNr guifg=#F6EC80
hi CursorLine NONE ctermbg=NONE guibg=NONE
hi CursorLineNr guifg=#965942 gui=NONE cterm=NONE
hi Visual guibg=#965942

" Syntaxe
hi Comment guifg=#965942
hi String guifg=#F6EC80
hi Number guifg=#F6EC80
hi Function guifg=#F6EC80
hi Keyword guifg=#965942
hi Statement guifg=#965942
hi Identifier guifg=#F6EC80
hi PreProc guifg=#965942
hi Type guifg=#F6EC80
hi Special guifg=#F6EC80
hi Error guifg=#F6EC80 guibg=#965942

" Menus et statut
hi StatusLine guifg=#F6EC80 guibg=#965942
hi StatusLineNC guifg=#965942 guibg=#965942
hi VertSplit guifg=#965942 guibg=#965942
hi Pmenu guifg=#F6EC80 guibg=#965942
hi PmenuSel guifg=#965942 guibg=#F6EC80
