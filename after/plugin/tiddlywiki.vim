" Simple TiddlyWiki configuration
" Provides basic wiki switching and watching functionality

echo "Loading TiddlyWiki configuration..."

" Basic plugin configuration
let g:tiddlywiki_author = 'striv'
let g:tiddlywiki_journal_format = '%YYYY-%MM-%DD'
let g:tiddlywiki_autoupdate = 1

" Path to the Python watcher script
let g:tiddlywiki_watcher_script = expand('~/.vim/scripts/twatcher/tiddlywiki_watcher.py')

" Track running watcher processes
let g:tiddlywiki_watcher_jobs = {}

" Initialize wiki dictionary
let g:tiddlywiki_wikis = {}

" Function to switch wikis
function! TiddlyWikiSwitch(wiki_name)
  let wikis_base = expand('~/Documents/wikis')
  let wiki_path = wikis_base . '/' . a:wiki_name
  let tiddlers_path = wiki_path . '/tiddlers'
  
  echo "Looking for wiki: " . wiki_path
  
  if !isdirectory(wiki_path)
    echo "Error: Wiki directory not found: " . wiki_path
    echo "Available wikis in " . wikis_base . ":"
    for dir in glob(wikis_base . '/*', 0, 1)
      if isdirectory(dir)
        echo "  " . fnamemodify(dir, ':t')
      endif
    endfor
    return
  endif
  
  " Set the wiki variables
  let g:tiddlywiki_current_wiki = a:wiki_name
  let g:tiddlywiki_dir = tiddlers_path
  
  echo "Switched to wiki: " . a:wiki_name
  echo "Tiddlers directory: " . g:tiddlywiki_dir
  echo "Wiki root: " . wiki_path
endfunction

" Function to get available wikis for tab completion
function! TiddlyWikiComplete(ArgLead, CmdLine, CursorPos)
  let wikis_base = expand('~/Documents/wikis')
  let available_wikis = []
  
  for dir in glob(wikis_base . '/*', 0, 1)
    if isdirectory(dir)
      let wiki_name = fnamemodify(dir, ':t')
      if wiki_name =~ '^' . a:ArgLead
        call add(available_wikis, wiki_name)
      endif
    endif
  endfor
  
  return available_wikis
endfunction

" Function to start the file watcher for current wiki
function! TiddlyWikiStartWatcher(...)
  " Get optional host and port arguments
  let host = get(a:, 1, '127.0.0.1')
  let port = get(a:, 2, 8080)
  
  if !exists('g:tiddlywiki_dir') || empty(g:tiddlywiki_dir)
    echo "Error: No wiki selected. Use :TWSwitch <wiki_name> to select a wiki first."
    echo "Available wikis:"
    call TiddlyWikiListWikis()
    return
  endif
  
  " Check if watcher script exists
  if !filereadable(g:tiddlywiki_watcher_script)
    echo "Error: Watcher script not found at " . g:tiddlywiki_watcher_script
    echo "Make sure to save the Python script to that location."
    return
  endif
  
  " Get the wiki directory (parent of tiddlers)
  let wiki_dir = fnamemodify(g:tiddlywiki_dir, ':h')
  
  echo "Starting TiddlyWiki watcher..."
  echo "Current wiki: " . get(g:, 'tiddlywiki_current_wiki', 'unknown')
  echo "Wiki directory: " . wiki_dir
  echo "URL: http://" . host . ":" . port
  
  " Stop existing watcher if running
  call TiddlyWikiStopWatcher()
  
  " Start new watcher
  let cmd = [
    \ 'python3',
    \ g:tiddlywiki_watcher_script,
    \ wiki_dir,
    \ '--host', host,
    \ '--port', string(port)
  \ ]
  
  let job = job_start(cmd, {
    \ 'out_cb': 'TiddlyWikiWatcherOutput',
    \ 'err_cb': 'TiddlyWikiWatcherError',
    \ 'exit_cb': 'TiddlyWikiWatcherExit'
  \ })
  
  if job_status(job) == 'run'
    let g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki] = {
      \ 'job': job,
      \ 'host': host,
      \ 'port': port,
      \ 'wiki_dir': wiki_dir
    \ }
    echo "Watcher started successfully!"
  else
    echo "Failed to start watcher"
  endif
endfunction

" Function to stop the file watcher
function! TiddlyWikiStopWatcher()
  if !exists('g:tiddlywiki_current_wiki') || 
     \ !has_key(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
    echo "No watcher running for current wiki"
    return
  endif
  
  let job_info = g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
  let job = job_info.job
  
  if job_status(job) == 'run'
    echo "Stopping TiddlyWiki watcher..."
    call job_stop(job, 'term')
    
    " Give it a moment to stop gracefully
    sleep 500m
    
    " Force kill if still running
    if job_status(job) == 'run'
      call job_stop(job, 'kill')
    endif
  endif
  
  unlet g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
  echo "Watcher stopped"
endfunction

" Function to check watcher status
function! TiddlyWikiWatcherStatus()
  if !exists('g:tiddlywiki_current_wiki')
    echo "No current wiki selected"
    return
  endif
  
  echo "Current wiki: " . g:tiddlywiki_current_wiki
  echo "Wiki directory: " . get(g:, 'tiddlywiki_dir', 'not set')
  
  if has_key(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
    let job_info = g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
    let status = job_status(job_info.job)
    echo "Watcher status: " . status
    if status == 'run'
      echo "URL: http://" . job_info.host . ":" . job_info.port
    endif
  else
    echo "No watcher running"
  endif
endfunction

" Function to list available wikis
function! TiddlyWikiListWikis()
  let wikis_base = expand('~/Documents/wikis')
  echo "Available wikis in " . wikis_base . ":"
  
  for dir in glob(wikis_base . '/*', 0, 1)
    if isdirectory(dir)
      echo "  " . fnamemodify(dir, ':t')
    endif
  endfor
endfunction

" Open current wiki in browser
function! TiddlyWikiOpenBrowser()
  if !exists('g:tiddlywiki_current_wiki') || 
     \ !has_key(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
    echo "No watcher running. Start with :TWWatch first."
    return
  endif
  
  let job_info = g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
  let url = 'http://' . job_info.host . ':' . job_info.port
  
  " Open URL based on operating system
  if has('mac')
    call system('open "' . url . '"')
  elseif has('unix')
    call system('xdg-open "' . url . '"')
  elseif has('win32')
    call system('start "' . url . '"')
  else
    echo "URL: " . url
  endif
endfunction

" Callback functions for job output
function! TiddlyWikiWatcherOutput(channel, msg)
  " Optional: uncomment to see watcher output
  " echo "Watcher: " . a:msg
endfunction

function! TiddlyWikiWatcherError(channel, msg)
  echo "Watcher Error: " . a:msg
endfunction

function! TiddlyWikiWatcherExit(job, exit_status)
  echo "Watcher exited with status: " . a:exit_status
  " Remove from tracking
  for [wiki, info] in items(g:tiddlywiki_watcher_jobs)
    if info.job == a:job
      unlet g:tiddlywiki_watcher_jobs[wiki]
      break
    endif
  endfor
endfunction

" Define commands
command! -nargs=1 -complete=customlist,TiddlyWikiComplete TWSwitch call TiddlyWikiSwitch(<q-args>)
command! -nargs=* TWWatch call TiddlyWikiStartWatcher(<f-args>)
command! TWStopWatch call TiddlyWikiStopWatcher()
command! TWStatus call TiddlyWikiWatcherStatus()
command! TWOpen call TiddlyWikiOpenBrowser()
command! TWList call TiddlyWikiListWikis()

" Mappings
nnoremap <leader>tws :TWWatch<CR>
nnoremap <leader>twx :TWStopWatch<CR>
nnoremap <leader>twr :TWStatus<CR>
nnoremap <leader>two :TWOpen<CR>
nnoremap <leader>twl :TWList<CR>

" Auto-stop watchers on Vim exit
augroup tiddlywiki_cleanup
  autocmd!
  autocmd VimLeavePre * call TiddlyWikiStopWatcher()
augroup END

echo "TiddlyWiki configuration loaded successfully!"
echo "Commands available: :TWSwitch, :TWWatch, :TWStatus, :TWList"
