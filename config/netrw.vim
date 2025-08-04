vim9script

# Enhanced netrw ftplugin for vertical split with 'f' key
# ~/.vim/after/ftplugin/netrw.vim

# Only set up once per buffer
if exists('b:netrw_enhanced_set')
  finish
endif
b:netrw_enhanced_set = true

# Function to open file in vertical split to the right
def OpenVerticalSplit()
  # Get the file under cursor
  var filename = expand('<cfile>')
  
  # Skip if empty filename
  if empty(filename)
    return
  endif
  
  # Get current directory from netrw
  var current_dir = exists('b:netrw_curdir') ? b:netrw_curdir : getcwd()
  
  # Construct full path - handle path separator properly
  var full_path = current_dir
  if current_dir !~ '/$'
    full_path ..= '/'
  endif
  full_path ..= filename
  
  # If it's a directory, use normal netrw navigation
  if isdirectory(full_path)
    execute "normal! \<CR>"
    return
  endif
  
  # If it's a file, open in vertical split to the right
  if filereadable(full_path)
    # Save current netrw window number
    var netrw_win = winnr()
    
    # Create vertical split to the right
    rightbelow vsplit
    
    # Open the file in the new split
    execute 'edit ' .. fnameescape(full_path)
    
    # Return focus to netrw window
    execute netrw_win .. 'wincmd w'
  else
    echo 'File not readable: ' .. full_path
  endif
enddef

# Map 'f' key to our function - use :call with <SID> for compatibility
nnoremap <buffer><silent> f :call <SID>OpenVerticalSplit()<CR>