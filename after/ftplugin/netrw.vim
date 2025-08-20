vim9script

# Enhanced netrw mappings using Vim9 script
# This file runs AFTER netrw sets its own mappings, ensuring ours take precedence

# Only set up mappings once per buffer
if exists('b:netrw_enhanced_mappings_set')
  finish
endif
b:netrw_enhanced_mappings_set = 1

echo "Setting up netrw enhanced mappings via Vim9 ftplugin..."

# Legacy function wrappers for mappings (these can be called via <SID>)

function! s:NetrwOpenVerticalSplit()
  call NetrwOpenVerticalSplitImpl()
endfunction

function! s:NetrwOpenHorizontalSplit()
  call NetrwOpenHorizontalSplitImpl()
endfunction

function! s:NetrwOpenTerminal()
  call NetrwOpenTerminalImpl()
endfunction

function! s:NetrwOpenTab()
  call NetrwOpenTabImpl()
endfunction

# Vim9 implementation functions

#def NetrwOpenVerticalSplitImpl()
#  var filepath = GetNetrwFile()
#  var filename = fnamemodify(filepath, ':t')
#  
#  if filename == '' || filename == '.' || filename == '..'
#    echo "No valid file selected"
#    return
#  endif
#  
#  if isdirectory(filepath)
#    # For directories, use normal netrw navigation
#    normal! 
#    return
#  endif
#
#  if !filereadable(filepath)
#    echo "File not readable: " .. filepath
#    return
#  endif
#  
#  # Save current netrw window
#  var netrw_win = winnr()
#  var total_windows = winnr('$')
#  
#  if total_windows == 1
#    # Only netrw window - create new vertical split to the right
#    rightbelow vsplit
#    execute 'edit ' .. fnameescape(filepath)
#  else
#    # Multiple windows - try to use right window or create new split
#    wincmd l  # Move to window on the right
#    if winnr() != netrw_win
#      # Successfully moved to right window, replace its content
#      execute 'edit ' .. fnameescape(filepath)
#    else
#      # Couldn't move right, create new split
#      rightbelow vsplit
#      execute 'edit ' .. fnameescape(filepath)
#    endif
#  endif
#  
#  # Return focus to netrw
#  execute netrw_win .. 'wincmd w'
#  echo "Opened " .. filename .. " in vertical split"
#enddef

#def NetrwOpenHorizontalSplitImpl()
#  var filepath = GetNetrwFile()
#  var filename = fnamemodify(filepath, ':t')
#  
#  if filename == '' || filename == '.' || filename == '..'
#    echo "No valid file selected"
#    return
#  endif
#  
#  if isdirectory(filepath)
#    # For directories, use normal netrw navigation
#    normal! 
#    return
#  endif
#
#  if !filereadable(filepath)
#    echo "File not readable: " .. filepath
#    return
#  endif
#  
#  # Save current netrw window
#  var netrw_win = winnr()
#  var total_windows = winnr('$')
#  
#  if total_windows == 1
#    # Only netrw window - create horizontal split below
#    below split
#    execute 'edit ' .. fnameescape(filepath)
#  else
#    # Multiple windows - try to find a good place for horizontal split
#    # First try to move down to see if there's a window below
#    wincmd j
#    if winnr() != netrw_win
#      # Successfully moved to lower window, replace its content
#      execute 'edit ' .. fnameescape(filepath)
#    else
#      # Couldn't move down, create split below netrw
#      below split
#      execute 'edit ' .. fnameescape(filepath)
#    endif
#  endif
#  
#  # Return focus to netrw
#  execute netrw_win .. 'wincmd w'
#  echo "Opened " .. filename .. " in horizontal split"
#enddef

#def NetrwOpenTerminalImpl()
#  # Save current netrw window
#  var netrw_win = winnr()
#  
#  # Create horizontal split below current window
#  below split
#  
#  # Open terminal in the new split
#  terminal
#  
#  # Return focus to netrw
#  execute netrw_win .. 'wincmd w'
#  echo "Terminal opened below netrw"
#enddef

#def NetrwOpenTabImpl()
#  var filepath = GetNetrwFile()
#  var filename = fnamemodify(filepath, ':t')
#  
#  if filename == '' || filename == '.' || filename == '..'
#    echo "No valid file selected"
#    return
#  endif
#  
#  if isdirectory(filepath)
#    # For directories, use normal netrw navigation
#    normal! 
#    return
#  endif
#
#  if !filereadable(filepath)
#    echo "File not readable: " .. filepath
#    return
#  endif
#
#  execute 'tabnew ' .. fnameescape(filepath)
#  echo "Opened " .. filename .. " in new tab"
#enddef

# Set up our enhanced mappings with <buffer> to make them buffer-local
# nnoremap <buffer><silent> f :call <SID>NetrwOpenVerticalSplit()<CR>
# nnoremap <buffer><silent> v :call <SID>NetrwOpenHorizontalSplit()<CR>
# nnoremap <buffer><silent> x :call <SID>NetrwOpenTerminal()<CR>
# nnoremap <buffer><silent> t :call <SID>NetrwOpenTab()<CR>

# Alternative mappings with leader key as backup
# nnoremap <buffer> <leader>f :call <SID>NetrwOpenVerticalSplit()<CR>
# nnoremap <buffer> <leader>v :call <SID>NetrwOpenHorizontalSplit()<CR>
# nnoremap <buffer> <leader>x :call <SID>NetrwOpenTerminal()<CR>
# nnoremap <buffer> <leader>t :call <SID>NetrwOpenTab()<CR>

# Debug function
function! s:NetrwDebugMappings()
  echo "=== Current buffer mappings ==="
  redir => mappings
  silent nmap <buffer>
  redir END
  echo mappings
  echo "=== End mappings ==="
endfunction

# Commands for debugging
command! NetrwMappings call <SID>NetrwDebugMappings()
# command! NetrwTestFile echo "File under cursor: " .. GetNetrwFile()

echo "Netrw Vim9 enhanced mappings loaded successfully"