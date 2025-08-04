#!/usr/bin/env python3
"""
TiddlyWiki File Watcher
Watches for changes in *.tid files and restarts TiddlyWiki server
"""

import os
import sys
import time
import subprocess
import signal
import argparse
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Global variable for signal handler
handler = None


class TiddlyWikiHandler(FileSystemEventHandler):
    def __init__(self, wiki_dir, host='127.0.0.1', port=8080, debounce_time=1.0):
        self.wiki_dir = Path(wiki_dir).resolve()
        self.host = host
        self.port = port
        self.debounce_time = debounce_time
        self.last_restart = 0
        self.process = None
        self.should_stop = False
        
        # Validate wiki directory
        if not self.wiki_dir.exists():
            raise ValueError(f"Wiki directory does not exist: {self.wiki_dir}")
        
        # Check if it's a valid TiddlyWiki directory
        if not (self.wiki_dir / 'tiddlywiki.info').exists():
            print(f"Warning: {self.wiki_dir} doesn't appear to be a TiddlyWiki directory")
            print("Looking for tiddlywiki.info file...")
        
        # Start initial server
        self.start_server()
    
    def on_modified(self, event):
        if event.is_directory:
            return
        
        # Only respond to .tid file changes
        if event.src_path.endswith('.tid'):
            self.restart_server_debounced()
    
    def on_created(self, event):
        if event.is_directory:
            return
        
        if event.src_path.endswith('.tid'):
            self.restart_server_debounced()
    
    def on_deleted(self, event):
        if event.is_directory:
            return
        
        if event.src_path.endswith('.tid'):
            self.restart_server_debounced()
    
    def restart_server_debounced(self):
        """Restart server with debouncing to avoid rapid restarts"""
        current_time = time.time()
        if current_time - self.last_restart < self.debounce_time:
            return
        
        self.last_restart = current_time
        print(f"[{time.strftime('%H:%M:%S')}] Tiddler change detected, restarting server...")
        self.restart_server()
    
    def start_server(self):
        """Start the TiddlyWiki server"""
        cmd = [
            'tiddlywiki',
            str(self.wiki_dir),
            '--listen',
            f'host={self.host}',
            f'port={self.port}'
        ]
        
        try:
            print(f"Starting TiddlyWiki server: {' '.join(cmd)}")
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=os.setsid  # Create new process group
            )
            print(f"Server started with PID {self.process.pid}")
            print(f"TiddlyWiki should be available at http://{self.host}:{self.port}")
            
            # Check if process started successfully
            time.sleep(2)
            if self.process.poll() is not None:
                stdout, stderr = self.process.communicate()
                print(f"Server failed to start!")
                print(f"STDOUT: {stdout.decode()}")
                print(f"STDERR: {stderr.decode()}")
                self.process = None
                
        except FileNotFoundError:
            print("Error: 'tiddlywiki' command not found.")
            print("Make sure TiddlyWiki is installed: npm install -g tiddlywiki")
            sys.exit(1)
        except Exception as e:
            print(f"Error starting server: {e}")
            sys.exit(1)
    
    def stop_server(self):
        """Stop the TiddlyWiki server"""
        if self.process:
            try:
                # Kill the entire process group
                os.killpg(os.getpgid(self.process.pid), signal.SIGTERM)
                
                # Wait for process to terminate
                try:
                    self.process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    # Force kill if it doesn't stop gracefully
                    os.killpg(os.getpgid(self.process.pid), signal.SIGKILL)
                    self.process.wait()
                
                print(f"[{time.strftime('%H:%M:%S')}] Server stopped")
                self.process = None
                
            except ProcessLookupError:
                # Process already dead
                self.process = None
            except Exception as e:
                print(f"Error stopping server: {e}")
    
    def restart_server(self):
        """Restart the TiddlyWiki server"""
        self.stop_server()
        time.sleep(0.5)  # Brief pause
        self.start_server()
    
    def cleanup(self):
        """Clean up resources"""
        self.should_stop = True
        self.stop_server()


def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully"""
    print("\nShutting down...")
    global handler
    if handler:
        handler.cleanup()
    sys.exit(0)


def find_tiddlers_dir(wiki_path):
    """Find the tiddlers directory in a TiddlyWiki"""
    wiki_path = Path(wiki_path)
    
    # If the path itself is a tiddlers directory
    if wiki_path.name == 'tiddlers' and wiki_path.exists():
        return wiki_path
    
    # Look for tiddlers subdirectory
    tiddlers_path = wiki_path / 'tiddlers'
    if tiddlers_path.exists():
        return tiddlers_path
    
    # If no tiddlers directory found, watch the wiki directory itself
    return wiki_path


def main():
    global handler
    
    parser = argparse.ArgumentParser(description='Watch TiddlyWiki files and restart server on changes')
    parser.add_argument('wiki_dir', help='Path to TiddlyWiki directory')
    parser.add_argument('--host', default='127.0.0.1', help='Server host (default: 127.0.0.1)')
    parser.add_argument('--port', type=int, default=8080, help='Server port (default: 8080)')
    parser.add_argument('--debounce', type=float, default=1.0, 
                       help='Debounce time in seconds (default: 1.0)')
    
    args = parser.parse_args()
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Find the appropriate directory to watch
        wiki_dir = Path(args.wiki_dir).resolve()
        tiddlers_dir = find_tiddlers_dir(wiki_dir)
        
        print(f"Watching for changes in: {tiddlers_dir}")
        print(f"Wiki directory: {wiki_dir}")
        
        # Create event handler
        handler = TiddlyWikiHandler(
            wiki_dir=wiki_dir,
            host=args.host,
            port=args.port,
            debounce_time=args.debounce
        )
        
        # Set up file system observer
        observer = Observer()
        observer.schedule(handler, str(tiddlers_dir), recursive=True)
        observer.start()
        
        print(f"File watcher started. Press Ctrl+C to stop.")
        print(f"Watching: {tiddlers_dir}")
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    finally:
        if 'observer' in locals():
            observer.stop()
            observer.join()
        if handler:
            handler.cleanup()


if __name__ == '__main__':
    main()
