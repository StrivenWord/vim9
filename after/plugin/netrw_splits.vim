vim9script

# Set up autocommands to track netrw window changes
augroup NetrwSplitsTracking
    autocmd!

    # When a netrw buffer is displayed in a window
    autocmd BufWinEnter * {
        if &filetype == 'netrw'
            netrw_init#AddNetrwSplit()
        endif
    }
    
    # When a netrw buffer is removed from a window
    autocmd BufWinLeave * {
        if &filetype == 'netrw'
            netrw_init#SubtrNetrwSplit()
        endif
    }
augroup END

# Toggle netrw file tree. Most important feature.
def ToggleNetrw()
    if netrw_init#NetrwIsOpen()
        # If open, close
        var netrw_win = netrw_init#FindNetrwWindow()
        if netrw_win != -1
            execute ':' .. netrw_win .. 'wincmd w'
            close
        endif
    else
        # Open netrw in left split. Probably depends on netrw_winsize
        # being defined in config/netrw-ext.vim
        aboveleft Lexplore
    endif
enddef

command! NetrwToggle call <SID>ToggleNetrw()