vim9script

# Netrw configuration, outside of the filetype plug in
# ~/.vim/after/ftplugin/netrw.vim

# === Display and Interface === #
g:netrw_liststyle = 3   # tree style
g:netrw_banner    = 1
g:netrw_winsize   = 25
g:netrw_hide      = 0   # show dotfiles

# === Navigation behavior === #

# Keep current directory in sync with browsed directory
g:netrw_keepdir   = 0

# When browsing, change Vim's working directory to follow netrw
g:netrw_browse_split = 0

# === File operations === #

# System commands
if has('mac')
  g:netrw_localcopycmd = 'cp'
  g:netrw_localmovecmd = 'mv'
  g:netrw_localrmdir   = 'rmdir'
elseif has('unix')
  g:netrw_localcopycmd = 'cp'
  g:netrw_localmovecmd = 'mv'
  g:netrw_localrmdir   = 'rmdir'
endif

# === Sorting === #

g:netrw_sort_by = 'name'  # other options: time, size
g:netrw_sort_sequence = '[\/]$,*'

# === Preview === #

# Preview window split direction (1 = horizontal, 0 = vertical)
g:netrw_preview = 1

# size
g:netrw_winsize = 30

# === Misc Enhancements === #

g:netrw_fastbrowse = 2
g:netrw_usetab     = 1
g:netrw_silent     = 1
