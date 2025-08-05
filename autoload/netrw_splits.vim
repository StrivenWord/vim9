vim9script

# Vim doesn't care about the concept of a two dimensional 'window', and it
# doesn't refer to sections of the viewport as 'quadrants'. It only counts
# splits.
g:netrw_splits_count = 0

export def AddNetrwSplit()
    g:netrw_splits_count += 1
enddef

export def SubtrNetrwSplit()
    g:netrw_splits_count -= 1
    if g:netrw_splits_count < 0
        g:netrw_splits_count = 0
    endif
enddef


