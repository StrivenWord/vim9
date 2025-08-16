vim9script

# Vim doesn't care about the concept of a two dimensional 'window', and it
# doesn't refer to sections of the viewport as 'quadrants'. It only counts
# splits.
g:netrw_splits_count = 0

# Toggle variables to track the open/close state of the two fundamental
# windows -- the netrw file tree and the open files(s)
g:state_netrw_filetree = -1
g:state_netrw_content  = -1

export def AddNetrwSplit()
    g:netrw_splits_count += 1
enddef

export def SubtrNetrwSplit()
    g:netrw_splits_count -= 1
    if g:netrw_splits_count < 0
        g:netrw_splits_count = 0
    endif
enddef


