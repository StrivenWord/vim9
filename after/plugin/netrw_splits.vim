vim9script

# Set up autocommands to track netrw window changes
augroup NetrwSplitsTracking
    autocmd!

    # When a netrw buffer is displayed in a window
    autocmd BufWinEnter * {
        if &filetype == 'netrw'
            netrw_splits#AddNetrwSplit()
        endif
    }
    
    # When a netrw buffer is removed from a window
    autocmd BufWinLeave * {
        if &filetype == 'netrw'
            netrw_splits#SubtrNetrwSplit()
        endif
    }
augroup END