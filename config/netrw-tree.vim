packadd minpac
call minpac#init()

call minpac#add('tpope/vim-unimpaired')
call minpac#add('tpope/vim-vinegar')
call minpac#add('tpope/vim-fugitive', {'type': 'opt'})
call minpac#add('tpope/vim-surround')
call minpac#add('tpope/vim-commentary')
call minpac#add('tpope/vim-repeat')
call minpac#add('sukima/vim-tiddlywiki', {'type': 'opt'})


" === syntax === "

" ... JavaScript and ECMAScript variants ...
call minpac#add('pangloss/vim-javascript')
call minpac#add('maxmellon/vim-jsx-pretty')
call minpac#add('HerringtonDarkholme/yats.vim')

" ... HMTL and CSS standards ...
call minpac#add('othree/html5.vim')
call minpac#add('hail2u/vim-css3-syntax')
call minpac#add('ap/vim-css-color')

" ... front end preprocessors ...
call minpac#add('wavded/vim-stylus')
call minpac#add('cakebaker/scss-syntax.vim')
call minpac#add('groenewege/vim-less')
call minpac#add('digitaltoad/vim-pug')
call minpac#add('kchmck/vim-coffee-script')

" ... shells ...
call minpac#add('chrisbra/vim-zsh')
" Nu needed

" ... documents ...
call minpac#add('plasticboy/vim-markdown')
call minpac#add('marshallward/vim-restructuredtext')
call minpac#add('lervag/vimtex')

" ... miscellaneous ...
call minpac#add('StanAngeloff/php.vim')
call minpac#add('vim-python/python-syntax')
call minpac#add('vim-ruby/vim-ruby')
call minpac#add('tbastos/vim-lua')
call minpac#add('fatih/vim-go')
call minpac#add('vim-perl/vim-perl')
call minpac#add('rust-lang/rust.vim')
call minpac#add('vim-scripts/c.vim')

" ... TiddlyWiki ...
call minpac#add('sukima/vim-tiddlywiki')

" === colon commands === "

command! PackUpdate call minpac#update()
command! PackClean call minpac#clean()


" === configuration modules === "

" Create config directory if it doesn't exist
if !isdirectory(expand('~/.vim/config'))
  call mkdir(expand('~/.vim/config'), 'p')
endif

" Load enhanced netrw configuration
source ~/.vim/config/netrw-enhanced.vim


" === mappings === "

nnoremap <C-p> :<C-u>FZF<CR>
nnoremap <Bslash> :<C-u>Lex<CR>
inoremap <C-Bslash> <Esc>:<C-u>Lex<CR>
vnoremap <C-Bslash> :<C-u>Lex<CR>
tnoremap <C-Bslash> :<C-u>Lex<Cr>

" ... mapleader
let mapleader = " "

" ... terminal
tnoremap <C-t> <C-\><C-n>:q<CR>
nnoremap <leader>to :call <SID>OpenTerminal()<CR>
nnoremap <leader>tq :call <SID>QuitTerminal()<CR>

function! s:OpenTerminal()
  " Check if a terminal buffer already exists
  for buf in range(1, bufnr('$'))
    if getbufvar(buf, '&buftype') == 'terminal'
      " Terminal exists, find its window or open it in a split
      let winnr = bufwinnr(buf)
      if winnr != -1
        " Terminal is already visible, switch to it
        execute winnr . 'wincmd w'
      else
        " Terminal exists but not visible, open it in a split
        execute 'sbuffer ' . buf
      endif
      return
    endif
  endfor
  " No terminal found, create a new one
  terminal
endfunction

function! s:QuitTerminal()
  if &buftype == 'terminal'
    quit
  else
    " Find and quit the first terminal buffer
    for buf in range(1, bufnr('$'))
      if getbufvar(buf, '&buftype') == 'terminal'
        execute 'bdelete! ' . buf
        break
      endif
    endfor
  endif
endfunction


" === settings, unless overridden by augroups or editconfigs === "

set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
set hlsearch
" set incsearch
" set ignorecase
" set smartcase
set wildmenu
set wildmode=list:longest,full
set backspace=indent,eol,start
set hidden
set laststatus=2
set showcmd
set showmode
set ruler
set scrolloff=3
set sidescrolloff=5
set formatoptions=cq

syntax enable
filetype plugin indent on

" ... EditorConfig settings ...
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']


" === Terminal cursor configuration === "

if !has('gui_running')
  " Terminal cursor shapes for different modes
  " These work with Terminal.app and most modern terminals
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"  " Vertical bar in insert mode
  let &t_SR = "\<Esc>]50;CursorShape=2\x7"  " Underline in replace mode  
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"  " Block in normal mode
  
  " Alternative approach using more standard escape sequences
  " Uncomment these and comment the above if the first approach doesn't work
  " let &t_SI = "\e[6 q"  " steady bar
  " let &t_SR = "\e[4 q"  " steady underline
  " let &t_EI = "\e[2 q"  " steady block
endif


" === augroups -- specific settings for specific filetypes === "

" ... VimScript ...
augroup vim_config
  autocmd!
  autocmd FileType vim setlocal tabstop=2 shiftwidth=2 expandtab
  autocmd FileType vim setlocal foldmethod=marker
  autocmd FileType vim setlocal textwidth=80
  autocmd FileType vim setlocal commentstring=\"\ %s
  autocmd BufRead,BufNewFile .vimrc,.gvimrc setlocal filetype=vim
augroup END

" ... JavaScript ...
augroup javascript_config
  autocmd!
  autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 noexpandtab " personal preferrence for tabs in JS
  autocmd FileType javascript setlocal foldmethod=syntax
  autocmd FileType javascript setlocal conceallevel=1
  autocmd FileType javascript setlocal textwidth=120
  autocmd FileType javascript setlocal colorcolumn=100
augroup END
let g:javascript_plugin_jsdoc = 1


" === AI generated config -- NEEDS REVIEW === "
" CSS settings
augroup css_config
  autocmd!
  autocmd FileType css,scss,sass,stylus,less setlocal tabstop=2 shiftwidth=2 expandtab
  autocmd FileType css,scss,sass setlocal iskeyword+=-
augroup END

" HTML settings
augroup html_config
  autocmd!
  autocmd FileType html,htmldjango,jinja setlocal tabstop=2 shiftwidth=2 expandtab
  autocmd FileType html setlocal matchpairs+=<:>
augroup END

" PHP settings
augroup php_config
  autocmd!
  autocmd FileType php setlocal tabstop=4 shiftwidth=4 expandtab
  autocmd FileType php setlocal commentstring=//\ %s
augroup END

" Python settings
augroup python_config
  autocmd!
  autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab
  autocmd FileType python setlocal textwidth=79
  autocmd FileType python setlocal colorcolumn=80
augroup END

" Enable enhanced Python syntax highlighting
let g:python_highlight_all = 1

" Ruby settings
augroup ruby_config
  autocmd!
  autocmd FileType ruby setlocal tabstop=2 shiftwidth=2 expandtab
augroup END

" Go settings
augroup go_config
  autocmd!
  autocmd FileType go setlocal tabstop=4 shiftwidth=4 noexpandtab
augroup END

" Rust settings
augroup rust_config
  autocmd!
  autocmd FileType rust setlocal tabstop=4 shiftwidth=4 expandtab
  autocmd FileType rust setlocal textwidth=100
  autocmd FileType rust setlocal colorcolumn=101
augroup END

" Markdown settings
augroup markdown_config
  autocmd!
  autocmd FileType markdown setlocal wrap
  autocmd FileType markdown setlocal linebreak
  autocmd FileType markdown setlocal textwidth=80
augroup END