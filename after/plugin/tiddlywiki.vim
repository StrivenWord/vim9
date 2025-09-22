vim9script

# Simple TiddlyWiki configuration
# Provides basic wiki switching and watching functionality

echom "Loading TiddlyWiki configuration..."

# --- Basic plugin configuration ---
g:tiddlywiki_author = 'striv'
g:tiddlywiki_journal_format = '%YYYY-%MM-%DD'
g:tiddlywiki_autoupdate = 1

# Path to the Python watcher script
g:tiddlywiki_watcher_script = expand('~/.vim/scripts/twatcher/tiddlywiki_watcher.py')

# Track running watcher processes
g:tiddlywiki_watcher_jobs = {}

# Initialize wiki dictionary
g:tiddlywiki_wikis = {}


# --- Core Functions ---

# Function to switch wikis
def TiddlyWikiSwitch(wiki_name: string)
  var wikis_base = expand('~/Documents/wikis')
  var wiki_path = wikis_base .. '/' .. wiki_name
  var tiddlers_path = wiki_path .. '/tiddlers'

  echom "Looking for wiki: " .. wiki_path

  if !isdirectory(wiki_path)
    echom "Error: Wiki directory not found: " .. wiki_path
    echom "Available wikis in " .. wikis_base .. ":"
    for dir in glob(wikis_base .. '/*', 0, 1)
      if isdirectory(dir)
        echom "  " .. fnamemodify(dir, ':t')
      endif
    endfor
    return
  endif

  # Set the wiki variables
  g:tiddlywiki_current_wiki = wiki_name
  g:tiddlywiki_dir = tiddlers_path

  echom "Switched to wiki: " .. wiki_name
  echom "Tiddlers directory: " .. g:tiddlywiki_dir
  echom "Wiki root: " .. wiki_path
enddef

# Function to get available wikis for tab completion
def TiddlyWikiComplete(ArgLead: string, CmdLine: string, CursorPos: number): list<string>
  var wikis_base = expand('~/Documents/wikis')
  var available_wikis: list<string> = []

  for dir in glob(wikis_base .. '/*', 0, 1)
    if isdirectory(dir)
      var wiki_name = fnamemodify(dir, ':t')
      if wiki_name =~ '^' .. ArgLead
        available_wikis->add(wiki_name)
      endif
    endif
  endfor

  return available_wikis
enddef

# Function to start the file watcher for the current wiki
def TiddlyWikiStartWatcher(host = '127.0.0.1', port = 8080)
  if !exists('g:tiddlywiki_dir') || empty(g:tiddlywiki_dir)
    echom "Error: No wiki selected. Use :TWSwitch <wiki_name> to select a wiki first."
    echom "Available wikis:"
    TiddlyWikiListWikis()
    return
  endif

  # Check if watcher script exists
  if !filereadable(g:tiddlywiki_watcher_script)
    echom "Error: Watcher script not found at " .. g:tiddlywiki_watcher_script
    echom "Make sure to save the Python script to that location."
    return
  endif

  # Get the wiki directory (parent of tiddlers)
  var wiki_dir = fnamemodify(g:tiddlywiki_dir, ':h')

  echom "Starting TiddlyWiki watcher..."
  echom "Current wiki: " .. get(g:, 'tiddlywiki_current_wiki', 'unknown')
  echom "Wiki directory: " .. wiki_dir
  echom "URL: http://" .. host .. ":" .. port

  # Stop existing watcher if running
  TiddlyWikiStopWatcher()

  # Start new watcher
  var cmd = [
    'python3',
    g:tiddlywiki_watcher_script,
    wiki_dir,
    '--host', host,
    '--port', port->string()
  ]

  var job = job_start(cmd, {
    out_cb: TiddlyWikiWatcherOutput,
    err_cb: TiddlyWikiWatcherError,
    exit_cb: TiddlyWikiWatcherExit
  })

  if job_status(job) == 'run'
    g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki] = {
      job: job,
      host: host,
      port: port,
      wiki_dir: wiki_dir
    }
    echom "Watcher started successfully!"
  else
    echom "Failed to start watcher"
  endif
enddef

# Function to stop the file watcher
def TiddlyWikiStopWatcher()
  if !exists('g:tiddlywiki_current_wiki')
        || !has(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
    echom "No watcher running for current wiki"
    return
  endif

  var job_info = g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
  var job = job_info.job

  if job_status(job) == 'run'
    echom "Stopping TiddlyWiki watcher..."
    job_stop(job, 'term')

    # Give it a moment to stop gracefully
    sleep 500m

    # Force kill if still running
    if job_status(job) == 'run'
      job_stop(job, 'kill')
    endif
  endif

  remove(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
  echom "Watcher stopped"
enddef

# Function to check watcher status
def TiddlyWikiWatcherStatus()
  if !exists('g:tiddlywiki_current_wiki')
    echom "No current wiki selected"
    return
  endif

  echom "Current wiki: " .. g:tiddlywiki_current_wiki
  echom "Wiki directory: " .. get(g:, 'tiddlywiki_dir', 'not set')

  if has(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
    var job_info = g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
    var status = job_status(job_info.job)
    echom "Watcher status: " .. status
    if status == 'run'
      echom "URL: http://" .. job_info.host .. ":" .. job_info.port
    endif
  else
    echom "No watcher running"
  endif
enddef

# Function to list available wikis
def TiddlyWikiListWikis()
  var wikis_base = expand('~/Documents/wikis')
  echom "Available wikis in " .. wikis_base .. ":"

  for dir in glob(wikis_base .. '/*', 0, 1)
    if isdirectory(dir)
      echom "  " .. fnamemodify(dir, ':t')
    endif
  endfor
enddef

# Open current wiki in browser
def TiddlyWikiOpenBrowser()
  if !exists('g:tiddlywiki_current_wiki')
      || !has(g:tiddlywiki_watcher_jobs, g:tiddlywiki_current_wiki)
    echom "No watcher running. Start with :TWWatch first."
    return
  endif

  var job_info = g:tiddlywiki_watcher_jobs[g:tiddlywiki_current_wiki]
  var url = 'http://' .. job_info.host .. ':' .. job_info.port

  # Open URL based on operating system
  if has('mac')
    system('open "' .. url .. '"')
  elseif has('unix')
    system('xdg-open "' .. url .. '"')
  elseif has('win32')
    system('start "" "' .. url .. '"') # Corrected for Windows
  else
    echom "URL: " .. url
  endif
enddef


# --- Callback functions for job output ---

def TiddlyWikiWatcherOutput(channel: channel, msg: string)
  # Optional: uncomment to see watcher output
  # echom "Watcher: " .. msg
enddef

def TiddlyWikiWatcherError(channel: channel, msg: string)
  echom "Watcher Error: " .. msg
enddef

def TiddlyWikiWatcherExit(job: job, exit_status: number)
  echom "Watcher exited with status: " .. exit_status
  # Remove from tracking
  for [wiki, info] in items(g:tiddlywiki_watcher_jobs)
    if info.job == job
      remove(g:tiddlywiki_watcher_jobs, wiki)
      break
    endif
  endfor
enddef


# --- Define commands, mappings, and autocommands ---

command! -nargs=1 -complete=customlist,TiddlyWikiComplete TWSwitch TiddlyWikiSwitch(<q-args>)
command! -nargs=* TWWatch TiddlyWikiStartWatcher(<f-args>)
command! TWStopWatch TiddlyWikiStopWatcher()
command! TWStatus TiddlyWikiWatcherStatus()
command! TWOpen TiddlyWikiOpenBrowser()
command! TWList TiddlyWikiListWikis()

nnoremap <silent> <leader>tws :TWWatch<CR>
nnoremap <silent> <leader>twx :TWStopWatch<CR>
nnoremap <silent> <leader>twr :TWStatus<CR>
nnoremap <silent> <leader>two :TWOpen<CR>
nnoremap <silent> <leader>twl :TWList<CR>

# Auto-stop watchers on Vim exit
augroup tiddlywiki_cleanup
  autocmd!
  autocmd VimLeavePre * TiddlyWikiStopWatcher()
augroup END

echom "TiddlyWiki configuration loaded successfully!"
echom "Commands available: :TWSwitch, :TWWatch, :TWStatus, :TWList"
