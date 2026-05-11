# gmux — Backend Integration Notes
**Written:** 2026-05-10  
**Purpose:** Strategy for connecting gmux UI to real AI coding agents + phone app

---

## Current State

The UI (`v2/index.html` v3.0) runs in two modes:
- **Mock mode** — browser, `● mock` in statusbar, fake data evolves every 2.2s
- **Tauri live** — inside Tauri app at `~/projects/gmuxtest/`, reads `/tmp/gmux-pane-state.json` via Rust polling → `gmux-state` events to JS

The critical state file contract:
```json
{
  "%pane_id": {
    "pane_id": "%1", "window_index": 1, "window_name": "my-project",
    "state": "working|waiting|permission|idle|done|error",
    "has_ai": true, "last_line": "last terminal line",
    "current_tool": "read|write|bash|glob|grep",
    "todo_done": 6, "todo_total": 8,
    "session_name": "gmux",
    "sub_agent_permission": false,
    "api_port": 42127,
    "ram_mb": 1240, "vram_mb": 180, "cpu_pct": 34,
    "token_in": 42800, "token_out": 18300,
    "model": "claude-sonnet-4-5",
    "tool_history": ["read","glob","write"],
    "uptime_s": 847
  }
}
```

---

## Tool Integration Priority

| Tool | API Quality | Already Used | Priority |
|------|-------------|-------------|----------|
| **OpenCode** | Full REST+SSE+WS | ✅ Yes (primary) | P0 |
| **Claude Code** | Hooks + JSONL files | ✅ Yes (via qc wrapper) | P1 |
| **Aider** | Gradio optional, --message | No | P2 |
| **Codex CLI** | CLI only | No | P3 |
| **Cursor** | None (GUI only) | No | P4 (skip) |

---

## 1. OpenCode — TIER 1 INTEGRATION ⭐⭐⭐⭐⭐

### How it works right now
OpenCode is the primary agent already. When running `opencode` in a tmux pane:
- Starts a Hono HTTP server on a **random port** at startup
- `monitor.py` polls `/tmp/gmux-pane-state.json` — this file is written by the opencode wrapper  

### Port Discovery (solved)
OpenCode doesn't write its port to a file. Discovery via process inspection:
```bash
for pid in $(pgrep -f "opencode.*src/index.ts" 2>/dev/null); do
  dir=$(tr '\0' ' ' </proc/$pid/cmdline | grep -oP '(?<=src/index.ts )\S+')
  port=$(ss -tlnp 2>/dev/null | grep "pid=$pid," | awk '{print $4}' | cut -d: -f2)
  [ -n "$port" ] && echo "{\"pid\":$pid,\"port\":$port,\"dir\":\"$dir\"}"
done
```
Confirmed working — right now 5 live instances found on this machine.

**Action for monitor.py:** Run this discovery every 10s, write ports to `/tmp/gmux-pane-state.json` as `api_port` field. This is already done for some panes.

### API Endpoints (all confirmed)

**Session state:**
```
GET  /session/status?directory=<path>
     → [{"type":"idle"},{"type":"busy"},{"type":"retry","attempt":1,"at":...}]

GET  /event?directory=<path>       (SSE stream)
     Key events:
     - session.status  → {sessionID, status: {type:"idle"|"busy"|"retry"}}
     - message.part.updated → streaming tool calls / text chunks
     - permission.updated → agent waiting for approve/deny
     - session.error
```

**Sending prompts:**
```
POST /session/:sessionId/message?directory=<path>
     Body: {"parts":[{"type":"text","text":"do X"}],"agent":"build"}
     (blocks until done — returns full response)

POST /session/:sessionId/prompt_async?directory=<path>  
     (fire-and-forget, returns 204 immediately)

POST /session/:sessionId/abort?directory=<path>
     (cancels current run)
```

**Sessions:**
```
POST /session?directory=<path>    → create session
GET  /session?directory=<path>    → list sessions
GET  /session/:id?directory=<path> → get session detail
DEL  /session/:id?directory=<path> → delete session
```

### gmux UI → OpenCode integration plan

```javascript
// In shared/mock-data.js or initDataSource():

async function connectOpenCode(port, dir) {
  // 1. SSE for real-time state
  const evSource = new EventSource(`http://127.0.0.1:${port}/event?directory=${dir}`);
  evSource.onmessage = (e) => {
    const ev = JSON.parse(e.data);
    if (ev.type === 'session.status') {
      const pane = findPaneByDir(dir);
      if (pane) {
        pane.state = ev.status.type === 'busy' ? 'working' :
                     ev.status.type === 'retry' ? 'waiting' : 'idle';
        onUpdate({...panes});
      }
    }
    if (ev.type === 'permission.updated') {
      const pane = findPaneByDir(dir);
      if (pane) { pane.state = 'permission'; onUpdate({...panes}); }
    }
  };
  // 2. Send from chat panel
  return async (sessionId, message) => {
    await fetch(`http://127.0.0.1:${port}/session/${sessionId}/prompt_async?directory=${dir}`, {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({parts:[{type:'text',text:message}]})
    });
  };
}
```

**What to read from opencode.db directly** (SQLite at `~/.local/share/opencode/opencode.db`):
```sql
-- Get all sessions with last activity
SELECT s.id, s.title, s.updated, m.role, p.text
FROM session s
LEFT JOIN message m ON m.sessionID = s.id
LEFT JOIN part p ON p.messageID = m.id AND p.type='text'
ORDER BY s.updated DESC;

-- Get tool calls for a session
SELECT p.type, p.toolName, p.text, m.time
FROM part p JOIN message m ON p.messageID=m.id
WHERE m.sessionID='ses_xxx' AND p.type='tool-invocation'
ORDER BY m.time;
```

The `ram_tracker/claude_usage.py` already reads this DB — reuse that code.

---

## 2. Claude Code — TIER 2 INTEGRATION ⭐⭐⭐

### Hooks (most practical for gmux)
Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "type": "command",
      "command": "/home/fivelidz/projects/gmuxtest/src-py/hooks/claude_state.sh",
      "timeout": 5
    }],
    "Stop": [{
      "type": "command", 
      "command": "/home/fivelidz/projects/gmuxtest/src-py/hooks/claude_state.sh",
      "timeout": 5
    }],
    "PostToolUse": [{
      "type": "command",
      "command": "/home/fivelidz/projects/gmuxtest/src-py/hooks/claude_state.sh",
      "timeout": 3
    }]
  }
}
```

Hook script writes to shared state file:
```bash
#!/bin/bash
# claude_state.sh — reads hook JSON from stdin, writes to gmux state
read -r HOOK_JSON
SESSION_ID=$(echo "$HOOK_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))")
EVENT=$(echo "$HOOK_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('hook_event_name',''))")
TRANSCRIPT=$(echo "$HOOK_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('transcript_path',''))")
# Map event name to state
STATE="idle"
[ "$EVENT" = "UserPromptSubmit" ] && STATE="working"
[ "$EVENT" = "PostToolUse" ] && STATE="working"
[ "$EVENT" = "Stop" ] && STATE="waiting"
# Write to state file for monitor.py to pick up
python3 -c "
import json,os,sys
f='/tmp/claude-hook-state-$SESSION_ID.json'
d={'session_id':'$SESSION_ID','state':'$STATE','event':'$EVENT','ts':__import__('time').time()}
with open(f,'w') as fp: json.dump(d,fp)
"
```

### JSONL file watching
Claude stores conversations at `~/.claude/projects/<encoded-path>/<session-id>.jsonl`:
```python
import json
from pathlib import Path

def get_claude_state(project_dir):
    """Watch Claude Code session JSONL for last message type."""
    encoded = project_dir.replace('/', '-').lstrip('-')
    sessions_dir = Path.home() / '.claude' / 'projects' / encoded
    if not sessions_dir.exists(): return 'idle'
    # Find most recently modified session file
    files = list(sessions_dir.glob('*.jsonl'))
    if not files: return 'idle'
    latest = max(files, key=lambda f: f.stat().st_mtime)
    # Read last line
    with open(latest) as f:
        lines = f.readlines()
    if not lines: return 'idle'
    last = json.loads(lines[-1])
    if last.get('type') == 'user': return 'working'
    if last.get('type') == 'assistant': return 'waiting'
    return 'idle'
```

### Sending messages to Claude Code (subprocess)
```python
import subprocess
def send_to_claude(message, project_dir, session_id=None):
    cmd = ['claude', '-p', '--output-format=stream-json']
    if session_id: cmd += ['-r', session_id]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
                            cwd=project_dir, text=True)
    proc.stdin.write(message + '\n')
    proc.stdin.close()
    # Parse stream-json output
    for line in proc.stdout:
        ev = json.loads(line.strip())
        if ev.get('type') == 'result':
            return ev.get('result', '')
```

---

## 3. HTTP Endpoint for Web/Phone Access

The Tauri app works for desktop but `gmux.ai` and the phone PWA need an HTTP API.

**Add to `monitor.py`** — a simple SSE server:
```python
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, threading, time

CLIENTS = []

class StateHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/state':
            data = open('/tmp/gmux-pane-state.json').read()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
        
        elif self.path == '/api/stream':
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            CLIENTS.append(self.wfile)
            # Keep connection open until client disconnects
            try:
                while True: time.sleep(30); self.wfile.write(b': keepalive\n\n'); self.wfile.flush()
            except: CLIENTS.remove(self.wfile)
        
        else:
            self.send_response(404); self.end_headers()
    
    def log_message(self, *args): pass  # suppress access logs

def broadcast_state():
    """Call this whenever state changes — broadcasts to all SSE clients."""
    data = open('/tmp/gmux-pane-state.json').read()
    msg = f'data: {data}\n\n'.encode()
    dead = []
    for w in CLIENTS:
        try: w.write(msg); w.flush()
        except: dead.append(w)
    for w in dead: CLIENTS.remove(w)

# Start HTTP server on port 8768 (phone PWA uses this)
server = HTTPServer(('0.0.0.0', 8768), StateHandler)
threading.Thread(target=server.serve_forever, daemon=True).start()
```

**Update `mock-data.js` `initDataSource` to add HTTP polling fallback:**
```javascript
async function initDataSource(panesObj, onUpdate) {
  // 1. Try Tauri first
  if (window.__TAURI_INTERNALS__) {
    // ... existing Tauri code
    return 'tauri';
  }
  // 2. Try HTTP endpoint (local or network)
  const BASE = window.GMUX_SERVER || 'http://127.0.0.1:8768';
  try {
    const test = await fetch(`${BASE}/api/state`, {signal: AbortSignal.timeout(2000)});
    if (test.ok) {
      // Use SSE for real-time updates
      const es = new EventSource(`${BASE}/api/stream`);
      es.onmessage = (e) => {
        const real = JSON.parse(e.data);
        for (const [id, pane] of Object.entries(real)) {
          if (panesObj[id]) Object.assign(panesObj[id], pane);
        }
        onUpdate({...panesObj});
      };
      // Also poll as fallback every 3s
      setInterval(async () => {
        const r = await fetch(`${BASE}/api/state`).then(r=>r.json()).catch(()=>null);
        if (r) { for (const [id,p] of Object.entries(r)) if(panesObj[id])Object.assign(panesObj[id],p); onUpdate({...panesObj}); }
      }, 3000);
      return 'http';
    }
  } catch(e) {}
  // 3. Mock fallback
  startMockEvolution(panesObj, onUpdate);
  return 'browser';
}
```

---

## 4. Phone PWA Architecture

The phone app at `:8768` (already referenced in SCOPE.md) should be:

```
Phone Browser (PWA)
  ↓ HTTP / SSE
gmux HTTP server at 127.0.0.1:8768
  ↓
/tmp/gmux-pane-state.json  ← monitor.py writes this
  ↑
tmux panes (opencode, claude, etc.)
```

**Phone PWA features:**
- Shows agent list with state (working/waiting/permission)
- Approve/deny permission requests with one tap
- Send voice message to selected agent (Web Speech API works on mobile Chrome/Safari)
- Gesture: phone camera → gesture control (POINT, PINCH, THREE) for approval flows
- `manifest.json` for home screen install + offline caching of UI

**Phone gesture considerations:**
- Phone camera is usually selfie-cam — same `facingMode: 'user'` as desktop
- Smaller screen: use simplified layout (single agent list, not grid)
- Pinch gesture naturally maps to phone touch — but on phone use touch events too for redundancy
- Voice STT via Web Speech API works natively on Android Chrome and iOS Safari 14.5+

---

## 5. Agent Launch Commands by Tool Type

When `createAgent()` is called in the UI, the Tauri backend needs to know what to run:

```rust
// In lib.rs — new Tauri command:
#[tauri::command]
fn open_agent(path: String, model: String, agent_type: String, preset: Option<String>) -> String {
    let cmd = match agent_type.as_str() {
        "qalcode" | "opencode" => format!("cd {path} && opencode"),
        "claude"               => format!("cd {path} && claude --model {model}"),
        "aider"                => format!("cd {path} && aider --model {model} --no-pretty"),
        "codex"                => format!("cd {path} && codex"),
        "terminal"             => format!("cd {path} && $SHELL"),
        _                      => format!("cd {path} && opencode"),
    };
    // Create new tmux window and run command
    let _ = std::process::Command::new("tmux")
        .args(["new-window", "-n", &path.split('/').last().unwrap_or("agent"), &cmd])
        .status();
    cmd
}
```

**Model passthrough for each tool:**
```bash
# OpenCode — via config or env:
OPENCODE_MODEL=claude-opus-4-5 opencode

# Claude Code — via flag or env:
claude --model claude-opus-4-5

# Aider — via flag:
aider --model claude/claude-opus-4-5

# Codex — via env:
OPENAI_MODEL=o3 codex
```

---

## 6. State Schema Extension (needed for multi-tool support)

Add to `/tmp/gmux-pane-state.json` schema:
```json
{
  "%1": {
    "_existing_fields_...",
    "agent_type": "opencode|claude|aider|codex|terminal",
    "agent_port": 42127,           // HTTP API port if available (opencode)
    "agent_session_id": "ses_xxx", // OpenCode session ID
    "cwd": "/home/fivelidz/projects/myproject",
    "git_branch": "main",
    "last_commit": "a1b2c3d fix: gesture handling",
    "cost_usd": 0.042,
    "token_rate_per_s": 45.2,
    "_schema": "3"                 // version for migration
  }
}
```

**monitor.py additions needed:**
1. Detect `agent_type` from process cmdline (`pgrep` checks)
2. Discover `agent_port` using ss+proc for opencode instances
3. Read `cwd` from `/proc/<pid>/cwd` symlink
4. Pull `git_branch` via `git -C <cwd> rev-parse --abbrev-ref HEAD`
5. Pull `cost_usd` from opencode.db or claude session JSONL
6. Calculate `token_rate_per_s` as rolling average

---

## 7. Files to Create/Modify

| File | Action | What |
|------|--------|------|
| `src-py/status/monitor.py` | Modify | Add HTTP server on :8768, opencode port discovery, git branch, agent_type |
| `src-py/hooks/claude_state.sh` | Create | Claude Code hook script → state file |
| `src-tauri/src/lib.rs` | Modify | Add `open_agent` command, add `approve_agent`/`reject_agent` commands |
| `shared/mock-data.js` | Modify | Add HTTP polling fallback in `initDataSource()` |
| `v2/index.html` | Modify | Wire `sendChat()` → real HTTP POST to agent API |
| New: `mobile/pwa/index.html` | Create | Phone PWA with voice + gesture + approve flow |
| New: `mobile/manifest.json` | Create | PWA manifest for home screen install |

---

## 8. Testing Plan

Before shipping any backend wiring, test these flows:

1. **OpenCode SSE** — open a browser tab to `http://127.0.0.1:42127/event?directory=<path>`, watch events stream as agent works
2. **Claude Code hooks** — add Stop hook, verify JSON appears in `/tmp/claude-hook-state-*.json`
3. **HTTP state endpoint** — run `python3 -m http.server 8768` stub returning the pane JSON, load UI with `?server=http://localhost:8768`
4. **Voice STT** — serve UI via `npx serve` (https://), test Web Speech API — requires HTTPS or localhost
5. **Phone gesture** — test on Android Chrome with phone camera, verify MediaPipe loads (WASM requires HTTPS)
6. **Two-hand zoom** — test spread/pinch to change grid columns, verify 800ms cooldown prevents runaway
7. **Pinch-drag vs select** — verify < 15px movement fires click, > 15px fires scroll

---

## 9. Quick Start Commands

```bash
# Run the new v3 UI:
cd ~/projects/gmuxtest/UI_creation_independent
python3 -m http.server 8080
# Open: http://localhost:8080/v2/index.html

# Run Tauri dev build:
cd ~/projects/gmuxtest
npm run tauri dev

# Discover live OpenCode instances:
for pid in $(pgrep -f "opencode.*src/index.ts" 2>/dev/null); do
  port=$(ss -tlnp 2>/dev/null | grep "pid=$pid," | awk '{print $4}' | cut -d: -f2)
  dir=$(ls -la /proc/$pid/cwd 2>/dev/null | awk '{print $NF}')
  echo "pid=$pid port=$port dir=$dir"
done

# Test OpenCode API on a live instance:
PORT=42127  # replace with discovered port
curl -s "http://127.0.0.1:$PORT/session/status?directory=$(pwd)" | python3 -m json.tool

# Stream OpenCode events:
curl -N "http://127.0.0.1:$PORT/event?directory=$(pwd)"
```
