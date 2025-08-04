" Configuration for sukima/vim-tiddlywiki
" Auto-discovers wikis in ~/Documents/wikis/ and provides switching functionality

" Debug: Check if plugin is loaded
if !exists('*TiddlyWikiEditTiddler')
  echo "Warning: TiddlyWiki plugin functions not found. Commands will still work for wiki switching and watching."
  " Don't finish - continue with our functionality
endif

" Basic plugin configuration
let g:tiddlywiki_author = 'striv'
let g:tiddlywiki_journal_format = '%YYYY-%MM-%DD'
let g:tiddlywiki_autoupdate = 1

" Path to the Python watcher script
let g:tiddlywiki_watcher_script = expand('~/.vim/scripts/tiddlywiki_watcher.py')

" Track running watcher processes
let g:tiddlywiki_watcher_jobs = {}

" Auto-discover wikis in ~/Documents/wikis/
function! TiddlyWikiDiscoverWikis()
  let wikis_base = expand('~/Documents/wikis')
  let g:tiddlywiki_wikis = {}
  
  echo "DEBUG: Looking for wikis in: " . wikis_base
  
  if !isdirectory(wikis_base)
    echo "Warning: ~/Documents/wikis/ directory not found"
    return
  endif
  
  " Find all subdirectories that contain tiddlywiki.info or tiddlers/
  for wiki_dir in glob(wikis_base . '/*', 0, 1)
    if isdirectory(wiki_dir)
      let wiki_name = fnamemodify(wiki_dir, ':t')
      let tiddlywiki_info = wiki_dir . '/tiddlywiki.info'
      let tiddlers_dir = wiki_dir . '/tiddlers'
      
      echo "DEBUG: Checking " . wiki_name . " - info: " . filereadable(tiddlywiki_info) . ", tiddlers: " . isdirectory(tiddlers_dir)
      
      " Check if it's a valid TiddlyWiki
      if filereadable(tiddlywiki_info) || isdirectory(tiddlers_dir)
        let g:tiddlywiki_wikis[wiki_name] = tiddlers_dir
        echo "DEBUG: Added wiki: " . wiki_name . " -> " . tiddlers_dir
      endif
    endif
  endfor
  
  echo "Discovered " . len(g:tiddlywiki_wikis) . " wikis: " . join(keys(g:tiddlywiki_wikis), ', ')
endfunction

" Initialize wikis on startup
echo "DEBUG: Initializing TiddlyWiki configuration..."
call TiddlyWikiDiscoverWikis()

" Set default wiki if not already set
if !exists('g:tiddlywiki_current_wiki') && len(g:tiddlywiki_wikis) > 0
  let g:tiddlywiki_current_wiki = keys(g:tiddlywiki_wikis)[0]
  let g:tiddlywiki_dir = g:tiddlywiki_wikis[g:tiddlywiki_current_wiki]
  echo "DEBUG: Set default wiki to: " . g:tiddlywiki_current_wiki . " (" . g:tiddlywiki_dir . ")"
else
  echo "DEBUG: No wikis found or current wiki already set"
endif

" Function to switch wikis
function! TiddlyWikiSwitch(wiki_name)
  if !exists('g:tiddlywiki_wikis')
    call TiddlyWikiDiscoverWikis()
  endif
  
  if has_key(g:tiddlywiki_wikis, a:wiki_name)
    let g:tiddlywiki_current_wiki = a:wiki_name
    let g:tiddlywiki_dir = g:tiddlywiki_wikis[a:wiki_name]
    echo "Switched to wiki: " . a:wiki_name . " (" . g:tiddlywiki_dir . ")"
  else
    echo "Unknown wiki: " . a:wiki_name
    echo "Available wikis: " . join(keys(g:tiddlywiki_wikis), ', ')
  endif
endfunction

" Tab completion for wiki names
function! TiddlyWikiComplete(ArgLead, CmdLine, CursorPos)
  if !exists('g:tiddlywiki_wikis')
    call TiddlyWikiDiscoverWikis()
  endif
  return filter(keys(g:tiddlywiki_wikis), 'v:val =~ "^" . a:ArgLead')
endfunction

" Function to start the file watcher for current wiki
function! TiddlyWikiStartWatcher(...)
  " Get optional host and port arguments
  let host = get(a:, 1, '127.0.0.1')
  let port = get(a:, 2, 8080)
  
  if !exists('g:tiddlywiki_dir') || empty(g:tiddlywiki_dir)
    echo "Error: g:tiddlywiki_dir not set. Use :TWSwitch to select a wiki first."
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
  
  echo "Starting TiddlyWiki watcher for: " . g:tiddlywiki_current_wiki
  echo "Wiki directory: " . wiki_dir
  echo "URL: http://" . host . ":" . port
  
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
  
  if has_key(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
    let job_info = g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
    let status = job_status(job_info.job)
    echo "Watcher for '" . g:tiddlywiki_current_wiki . "': " . status
    if status == 'run'
      echo "URL: http://" . job_info.host . ":" . job_info.port
    endif
  else
    echo "No watcher running for current wiki: " . g:tiddlywiki_current_wiki
  endif
endfunction

" Open current wiki in browser
function! TiddlyWikiOpenBrowser()
  if !has_key(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
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

" Enhanced wiki switching function that manages watchers
function! TiddlyWikiSwitchEnhanced(wiki_name)
  " Stop current watcher
  call TiddlyWikiStopWatcher()
  
  " Switch wiki
  call TiddlyWikiSwitch(a:wiki_name)
  
  echo "Switched to wiki: " . a:wiki_name
  echo "Use :TWWatch to start file watching"
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

" Commands (preserved from original)
echo "DEBUG: Defining TiddlyWiki commands..."
command! -nargs=1 -complete=customlist,TiddlyWikiComplete TWSwitch call TiddlyWikiSwitch(<q-args>)
command! -nargs=* TWWatch call TiddlyWikiStartWatcher(<f-args>)
command! TWStopWatch call TiddlyWikiStopWatcher()
command! TWStatus call TiddlyWikiWatcherStatus()
command! TWOpen call TiddlyWikiOpenBrowser()
command! -nargs=1 -complete=customlist,TiddlyWikiComplete TWSwitchWatch call TiddlyWikiSwitchEnhanced(<q-args>)

" Manual wiki switch commands removed per user request

" Utility commands
command! TWCurrent echo "Current wiki: " . get(g:, 'tiddlywiki_current_wiki', 'none') . " (" . get(g:, 'tiddlywiki_dir', 'not set') . ")"
command! TWList echo "Available wikis: " . join(keys(get(g:, 'tiddlywiki_wikis', {})), ', ')
command! TWRefresh call TiddlyWikiDiscoverWikis()
echo "DEBUG: TiddlyWiki commands defined successfully"

" Mappings (preserved from original)
nnoremap <leader>tws :TWWatch<CR>
nnoremap <leader>twx :TWStopWatch<CR>
nnoremap <leader>twr :TWStatus<CR>
nnoremap <leader>two :TWOpen<CR>

" Auto-stop watchers on Vim exit
augroup tiddlywiki_cleanup
  autocmd!
  autocmd VimLeavePre * call TiddlyWikiStopWatcher()
augroup END
