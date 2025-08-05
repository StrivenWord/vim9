" ~/.gvimrc - MacVim GUI configuration

" Font configuration
set guifont=SF\ Mono:h16
" Alternative fonts you might prefer:
" set guifont=Menlo:h14
" set guifont=Monaco:h14
" set guifont=JetBrains\ Mono:h14

" Window appearance
set lines=50
set columns=120
set linespace=2

" GUI options
set guioptions-=T    " Remove toolbar
set guioptions-=r    " Remove right scrollbar
set guioptions-=L    " Remove left scrollbar
set guioptions-=m    " Remove menu bar (optional)
set guioptions+=c    " Use console dialogs instead of popup dialogs

" Enable mouse support
set mouse=a

" Color scheme for GUI
if has('gui_running')
  colorscheme desert
  " Alternative color schemes:
  " colorscheme slate
  " colorscheme torte
  " colorscheme peachpuff
endif

" Transparency (MacVim specific)
set transparency=5

" Full screen options (MacVim)
set fuoptions=maxvert,maxhorz

" Tab appearance
set showtabline=2
set tabpagemax=15

" GUI Cursor settings - simplified and working
set guicursor=n-v-c:block-Cursor
set guicursor+=i:ver25-Cursor
set guicursor+=r-cr:hor20-Cursor
set guicursor+=a:blinkon250-blinkoff150-blinkwait700

" Anti-aliasing
if has('gui_macvim')
  set antialias
endif

" Better text rendering
if has('gui_macvim') && has('gui_running')
  set macligatures
endif
