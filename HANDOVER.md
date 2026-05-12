# gmux v3.1 LIVE — Handover Document

**Refactor date:** 2026-05-12
**Status:** UI + backend converted from mock-driven demo to live data integration

This document is for the next developer (human or agent) who needs to extend or
maintain gmux. It covers the architecture, data flow, what was changed in the
v3.0→v3.1 refactor, and the gotchas you will hit.

---

## 1. What gmux is

A multi-agent monitoring and control UI for tmux-hosted AI coding agents
(QalCode2 / OpenCode / Claude Code / aider / cursor, etc.). Each tmux pane that
runs an agent shows up as a tile in a grid with its current task, todo list,
state, RAM/CPU usage, model, token spend, and a chat panel for interaction.

There are also gesture (MediaPipe hand-tracking) and voice (Web Speech API)
control surfaces, but those are independent of the data layer this document
covers.

---

## 2. Repo layout (relevant parts)

```
/home/fivelidz/projects/
├── gmuxtest/UI_creation_independent/     ← UI lives here
│   ├── v2/index.html                     ← THE LIVE UI (v3.1)
│   ├── archive/demos/
│   │   └── index.v3.0-demo-fullmock.20260512.html  ← preserved demo build
│   ├── HANDOVER.md                       ← this file
│   ├── RESEARCH_UI_DESIGN.md
│   ├── BACKEND_INTEGRATION.md
│   └── ...
└── gmux-system/                          ← backend lives here
    ├── backend/status/
    │   ├── monitor.py                    ← THE BACKEND (HTTP server :8769)
    │   ├── monitor.py.bak.20260512       ← pre-refactor backup
    │   ├── jump_red.py
    │   └── pane_status.py
    ├── app/                              ← Tauri desktop wrapper (optional)
    └── docs/
```

The UI is a single standalone HTML file. The backend is a single Python script.
Both can run independently — you can open `v2/index.html` in a browser and it
will fetch from `http://127.0.0.1:8769` if the backend is running.

---

## 3. Architecture / Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│  tmux  ←→  bun (OpenCode/QalCode2 agents)  ←→  filesystem        │
│   ▲                       ▲                                       │
│   │ tmux poll             │ /event SSE, /session, /session/:id   │
│   │ (2s)                  │ /session/:id/todo                    │
│   │                       │ /session/:id/message                 │
│   │                       │                                       │
│  ┌┴───────────────────────┴─────────────────────────────────┐    │
│  │  monitor.py    (gmux-system/backend/status/monitor.py)   │    │
│  │                                                            │    │
│  │  Threads:                                                  │    │
│  │   - main poll loop      (2s tmux scan → /tmp/state.json)  │    │
│  │   - per-pane SSE        (one thread per agent, real-time) │    │
│  │   - aggregate worker    (10s/pane: msg totals, model)     │    │
│  │   - psutil queries      (inline, ~30ms per pane per poll) │    │
│  │   - HTTP server         (port 8769)                       │    │
│  └────────────────────────────┬─────────────────────────────┘    │
│                               │                                   │
│                               │ JSON over HTTP+SSE                │
│                               ▼                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  v2/index.html  (UI)                                       │  │
│  │                                                              │  │
│  │  initDataSource() → fetch /api/state, subscribe /api/stream │  │
│  │  applyRealStateExtras() → mirror p.todos / p.children       │  │
│  │  fetchChat(pid)   → /api/pane/<pid>/messages on chat open   │  │
│  │  fetchTodos(pid)  → /api/pane/<pid>/todos refresh           │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### Refresh cadence

| Field | Update mechanism | Cadence |
|---|---|---|
| `state` (working/waiting/etc.) | SSE `session.status` event from OpenCode | real-time |
| `current_tool` | SSE `message.part.updated` | real-time |
| `permission` flag | SSE `permission.updated` | real-time |
| `todo_done`/`todo_total`/`todos[]` | SSE `todo.updated` + REST fallback | real-time + 2s poll |
| `last_line` | `tmux capture-pane` | 2s |
| `ram_mb`/`cpu_pct`/`uptime_s`/`children` | psutil walk of bun PID | 2s (during tmux poll) |
| `model`/`token_in`/`token_out`/`cost_usd`/`msg_count` | aggregate worker thread | 10s per pane |
| chat history (`CHAT` cache in UI) | fetchChat on open + on send | on-demand |

---

## 4. Backend HTTP API

All endpoints served by `monitor.py` on `http://127.0.0.1:8769`.

### `GET /api/state`
Full state snapshot. Returns a dict keyed by pane_id (e.g. `"%1"`).

Each pane entry has the following fields (see `PaneInfo` dataclass for source):

```jsonc
{
  "pane_id":       "%1",
  "session_name":  "gmux",                  // tmux session
  "window_index":  1,
  "window_name":   "my-project",
  "pane_index":    1,
  "is_active":     true,
  "foreground_cmd": "bun",
  "state":         "working",               // 7-state enum (see monitor.py)
  "has_ai":        true,
  "last_line":     "  ✓ Reading src/main.rs",
  "api_port":      40167,                   // OpenCode HTTP port
  "current_tool":  "read",
  "todo_done":     5,
  "todo_total":    8,
  "pane_left":     0, "pane_top": 0,
  "pane_width":    255, "pane_height": 45,
  "sub_agent_permission": false,
  // ── v3.1 live-process fields (from psutil) ──
  "ram_mb":        364,                     // RSS of bun + children, MB
  "cpu_pct":       12.4,
  "uptime_s":      44272,
  "children":      [{"name":"ripgrep","ram_mb":12,"pid":12345}, ...],
  // ── v3.1 OpenCode aggregates (from message walk) ──
  "session_id":    "ses_1ea889f01...",      // active OpenCode session
  "model":         "claude-sonnet-4-6",
  "provider":      "anthropic",
  "token_in":      6885306,                 // includes cache.read
  "token_out":     39047,
  "token_reasoning": 0,
  "cost_usd":      0.0,                     // currently 0 in QalCode 1.1.x
  "msg_count":     122,
  // ── extras present from earlier work ──
  "todos":         [{"id":"1","content":"…","status":"completed","priority":"high"}],
  "tool_history":  ["read","write","bash"],
  "cwd":           "/home/fivelidz/projects/foo"
}
```

### `GET /api/stream`
Server-Sent Events feed. Pushes the same payload as `/api/state` whenever
`monitor.py` writes new state (every ~2s if anything changed). Sends keepalives
every 15s.

### `GET /api/pane/<pane_id>/todos`  *(new in v3.1)*
Proxy to OpenCode's `/session/<sid>/todo`. The pane_id must be URL-encoded
(e.g. `%1` → `%251`). Response:
```json
{
  "pane_id":    "%1",
  "session_id": "ses_…",
  "ok":         true,
  "data":       [{"id":"1","content":"…","status":"completed","priority":"high"}]
}
```
Returns `{ok: false, data: []}` when the pane has no agent or session.

### `GET /api/pane/<pane_id>/messages?limit=N`  *(new in v3.1)*
Proxy to OpenCode's `/session/<sid>/message`, trimmed to the last N messages
(default 50, max 500). Returns the raw OpenCode message shape — the UI's
`convertOpenCodeMessages()` flattens it.

### `GET /health`
Liveness probe. Returns `200 ok`.

---

## 5. What changed in the v3.0 → v3.1 refactor

### Backend (`monitor.py`)

**Added (new helpers):**
- `get_process_metrics(shell_pid)` — walks tmux pane PID → bun PID via psutil, returns RAM/CPU/uptime/children
- `_find_bun_pid(shell_pid)` — process-tree walker
- `aggregate_session_stats(port, session_id, directory)` — sums tokens/cost across all assistant messages
- `refresh_session_aggregate(pane_id)` — refresh wrapper called from the worker thread
- `get_session_todos(port, sid, directory)` — proxy helper
- `get_session_messages(port, sid, directory, limit)` — proxy helper
- `run_aggregate_worker()` + `start_aggregate_worker()` — background thread that calls `refresh_session_aggregate` on a 10s cycle
- `_StateHTTPHandler._resolve_pane(pane_id)` — translates pane_id → (port, session_id, directory)

**Modified:**
- `LiveState` dataclass — added 10 new fields for tokens/model/cost/session_id
- `PaneInfo` dataclass — added 12 new fields (process metrics + aggregates)
- `poll_tmux()` — calls `get_process_metrics` per AI pane, reads aggregates from `_live`
- `_StateHTTPHandler.do_GET()` — new routes `/api/pane/<pid>/todos` and `/api/pane/<pid>/messages`
- `run_daemon()` — starts `start_aggregate_worker()` and warns if psutil missing

**Backup:** `monitor.py.bak.20260512` is the pre-refactor file.

### UI (`v2/index.html`)

**Removed (all hardcoded mock data):**
- `MOCK_TODOS` (8 panes × ~5 task strings) — now `TODOS` (dict, runtime-populated)
- `MOCK_CHILDREN` — now `CHILDREN`
- `MOCK_PHRASES` (6 fake voice transcripts) — deleted entirely (Web Speech API is the source)
- `CHAT` as a hardcoded const — now an empty dict, populated by `fetchChat()`
- `REAL_CHAT` + `_fetchRealChat()` — folded into `CHAT` + `fetchChat()` to remove duplication
- `reassignSessionsForDemo` IIFE — deleted; `SESSIONS` now derived from real `session_name` fields
- Initial `SESSIONS` list `[{gmux},{work},{personal}]` — now starts `[]`
- Fake "Processing your message…" / "Got it" canned chat replies in `submitVoiceDraft`, `stopPTT`, and the no-port fallback of `sendChat`

**Added:**
- `GMUX_API_BASE` constant — points at the backend (defaults to `http://127.0.0.1:8769`, overridable via `window.GMUX_API`)
- `fetchTodos(pane_id)` — hits `/api/pane/<pid>/todos`, caches in `TODOS`
- `fetchChat(pane_id, limit)` — hits `/api/pane/<pid>/messages`, converts via `convertOpenCodeMessages()`, caches in `CHAT`
- `convertOpenCodeMessages(messages)` — flattens OpenCode's `parts[]` structure into `{role, text}` bubbles
- `applyRealStateExtras(panesObj)` — mirrors `p.todos`, `p.children`, `p.tool_history` into the in-memory stores
- `_refreshChatPanel(pane_id)` — throttled chat refresher (3s minimum between refetches)

**Modified:**
- `updatePaneEl()` — reads from `p.todos`/`p.children` directly (no more mock fallback branches)
- `openChat(id)` — calls `fetchChat(id)` + `fetchTodos(id)` in the background
- `renderChatPanel(p)` — reads from unified `CHAT[p.pane_id]`, kicks off `_refreshChatPanel()`
- `sendChat()` — on real-data send, schedules two follow-up `_refreshChatPanel()` calls so the assistant reply lands in the UI; on failure shows a real error rather than faking a reply
- `submitVoiceDraft()` — delegates to `window.sendChat()` instead of inventing fake replies
- `stopPTT()` — just shows a toast; no more fake chat exchange
- The 1Hz perf timer — stopped fabricating tokens for `working` agents; now just samples real cumulative totals into `pushTokenRate()`

**Preserved (intentionally not changed):**
- `MOCK_PANES` constant — still used as the initial seed for `panes`/`paneOrder` so the UI has something to render in the ~500ms before the first `/api/state` response arrives. When the backend is unreachable entirely, `startMockEvolution()` keeps the placeholder panes moving so the UI doesn't look frozen.
- `startMockEvolution()` — fallback only; never runs when backend is reachable
- `MODEL_COST` — pricing table for the cost calculation (configuration, not runtime data)
- All gesture/voice/UI-state code

---

## 6. The mock-fallback rule

The UI has three operating modes:

| Mode | Trigger | Data source | UI indicator |
|---|---|---|---|
| **tauri** | `window.__TAURI_INTERNALS__` present | Rust emits `gmux-state` events via `listen()` | `● tauri live` in statusbar |
| **http** / **http-poll** | Browser, monitor.py reachable on 8769 | SSE `/api/stream` (preferred) or 2s poll of `/api/state` | `● live :8769` |
| **mock** | Neither of the above | `MOCK_PANES` + `startMockEvolution()` | `● mock` |

`initDataSource()` (in the inlined `shared/mock-data.js` block, around line 1814)
walks these in order and the first one that succeeds wins.

When in mock mode, `TODOS`, `CHILDREN`, `CHAT` stay empty — the UI renders
"No tasks recorded" / "No conversation yet" placeholders. This is intentional:
mock mode is for "did the UI break?" diagnosis, not for demoing.

---

## 7. Running it

### Backend
```bash
# Dependencies: Python ≥3.11 + psutil
pip install psutil  # if not already installed

# Run
python3.11 /home/fivelidz/projects/gmux-system/backend/status/monitor.py
```

The monitor binds `0.0.0.0:8769` and writes `/tmp/gmuxtest-pane-state.json`.

Health check: `curl http://127.0.0.1:8769/health` → `ok`

Smoke test: `curl -s http://127.0.0.1:8769/api/state | jq 'first(.[])'`

### UI
```bash
# Just open the file via any local HTTP server — file:// won't work
cd /home/fivelidz/projects/gmuxtest/UI_creation_independent
python3 -m http.server 8000
# Then visit http://localhost:8000/v2/
```

If the backend isn't running, the UI falls back to mock mode and shows a
`backend down — UI on mock` warning in the bottom-right corner with a
"restart" button (only works under Tauri).

---

## 8. Gotchas / things that will bite you

### `pane_id` URL-encoding
Pane IDs start with `%` (e.g. `%1`, `%42`). To put them in a URL path you need
**double encoding**: `%` → `%25` → and the `1` stays. So `%1` becomes `%251`
in `/api/pane/%251/todos`. The UI's `fetchTodos`/`fetchChat` use
`encodeURIComponent(pane_id)` which does this correctly.

### `psutil` is required for live RAM/CPU
The backend prints a WARNING on startup if `psutil` is missing. Without it,
`ram_mb`/`cpu_pct`/`uptime_s`/`children` are all zero. The UI shows "—" for
all of them in this case.

### CPU% is "since last call"
`psutil.Process.cpu_percent(interval=None)` returns CPU since the previous
call. The first poll returns 0. We cache the `psutil.Process` object in
`_proc_cache` so successive polls give meaningful numbers. If the process
dies the cache entry is dropped.

### Session ID discovery is lazy
`_live[pane_id].session_id` starts empty. The aggregate worker fills it via
`get_active_session_id()` on its first run for that pane. Until then,
`/api/pane/<pid>/todos` returns `{ok: false, data: []}`. The UI handles this
gracefully by showing "No tasks recorded" until the next poll cycle.

### Sub-agent (Task tool) sessions are filtered out
`get_active_session_id()` skips sessions with a `parentID` because Task-tool
children don't carry their own todos. Only the top-level session is tracked.

### Cost is currently always 0
QalCode2 1.1.x sets `info.cost = 0` on every message even when there's a real
cost. The aggregation reads it correctly; it'll just show $0 until OpenCode
fixes the cost tracking. The UI's `calcCostUsd(p)` fallback (using
`MODEL_COST` × token counts) is no longer used because we trust the backend's
value — if you want to revive client-side cost calculation, change
`renderChatPanel`'s `tokTxt` line and `renderPerfStrip`'s `totalCost` line.

### Window name caching
tmux auto-renames windows to the foreground process name (so `bun` overwrites
your nice `my-project` name when the agent starts). `monitor.py` caches
"good" names in `/tmp/gmuxtest-window-names.json` and restores them. Don't
delete that file unless you want all your project names to reset to "bun".

### Two monitor.py processes
There's an old `gmux/src/status/monitor.py` (PID may still be around) and the
current `gmux-system/backend/status/monitor.py`. Only the latter has the v3.1
features. If port 8769 is bound by the wrong one, kill it.

```bash
ps aux | grep monitor.py | grep -v grep
# kill the gmux/src/status/ one if you see it
```

---

## 9. Common tweaks

### Change the aggregate cycle
Edit `AGGREGATE_INTERVAL` in `monitor.py` (default `10.0` seconds). Lower =
more responsive token counts, but more HTTP traffic to OpenCode.

### Change which fields the UI shows in the Hardware tab
`updatePaneEl()` in `v2/index.html` — the `vm === 'hw'` branch starting at
the `<div class="pane-hw">` template. All fields come from `p.*`.

### Add a new field
1. Add to `LiveState` dataclass (if SSE-fed) or compute in `poll_tmux` directly
2. Add to `PaneInfo` dataclass
3. Pass it in the `PaneInfo(...)` constructor at the end of `poll_tmux`
4. Read it as `p.your_field` in the UI

`asdict(p)` in `write_state()` picks it up automatically.

### Disable the demo banner / brand long-press
Find `setupDemoBanner` and `setupBrandLongPress` in the UI (near line 6600).
The demo banner currently shows by default in this single-file build —
delete or comment out the `setupDemoBanner` IIFE if shipping standalone.

---

## 10. Files touched in this refactor

```
gmuxtest/UI_creation_independent/
  v2/index.html                                              — main rewrite
  archive/demos/index.v3.0-demo-fullmock.20260512.html       — preserved demo
  HANDOVER.md                                                — this file

gmux-system/backend/status/
  monitor.py                                                 — added v3.1 helpers
  monitor.py.bak.20260512                                    — pre-refactor backup
```

---

## 11. Testing checklist

After any change to either side, verify:

```bash
# 1. Backend compiles
python3 -m py_compile /home/fivelidz/projects/gmux-system/backend/status/monitor.py && echo OK

# 2. Backend serves the new fields
curl -s http://127.0.0.1:8769/api/state | python3 -c "
import json,sys; d=json.load(sys.stdin); p=next(iter(d.values()))
need=['ram_mb','cpu_pct','uptime_s','children','model','token_in','token_out','session_id','todos']
miss=[k for k in need if k not in p]
print('MISSING:', miss) if miss else print('all fields present')
"

# 3. Proxy endpoints work
curl -s "http://127.0.0.1:8769/api/pane/%251/todos" | python3 -c "
import json,sys; d=json.load(sys.stdin); print('todos:', len(d.get('data',[])))
"
curl -s "http://127.0.0.1:8769/api/pane/%251/messages?limit=3" | python3 -c "
import json,sys; d=json.load(sys.stdin); print('msgs:', len(d.get('data',[])))
"

# 4. UI JS syntax
python3 -c "
import re
html=open('/home/fivelidz/projects/gmuxtest/UI_creation_independent/v2/index.html').read()
m=re.search(r'<script type=\"module\">(.*?)</script>', html, re.DOTALL)
open('/tmp/_chk.mjs','w').write(m.group(1))
"
node --check /tmp/_chk.mjs && echo OK

# 5. Visual verification
# Open http://localhost:8000/v2/ — check:
#   - Statusbar shows "● live :8769" (not "● mock")
#   - Hardware tab on a pane shows real RAM, CPU%, model name, token count
#   - Chat panel shows real recent messages (not the hardcoded "Build the gesture engine…")
#   - Todo list shows the agent's actual task list
```

---

## 12. Where to go next

Things this refactor did NOT do but would be natural follow-ups:

1. **WebSocket replacement for the chat refresh loop** — currently we poll
   `/api/pane/<pid>/messages` on demand. A real WS subscription to OpenCode's
   `/event` SSE stream (proxied via the backend) would give true real-time
   streaming responses in the chat panel.

2. **VRAM tracking** — `nvidia-smi` per-process query for local-GPU agents
   (mlx-distributed, llama.cpp). Currently `vram_mb` is removed from the UI.

3. **Voice daemon integration** — `connectVoiceDaemon()` already exists in
   the UI; if you run `~/projects/MASTER_PROJECTS/.../voice_daemon.py` on
   port 8770, you get faster-whisper transcription. The Web Speech API is
   the default browser fallback.

4. **Cost tracking** — wait for QalCode2 / OpenCode to actually populate
   `info.cost` and the UI lights up automatically. Or compute client-side
   from `MODEL_COST` if you want estimates now.

5. **Permission approve/reject buttons** — already wired through Tauri's
   `approve_agent` and `reject_agent` commands. In browser mode they only
   update local state — needs a backend proxy `POST /api/pane/<pid>/approve`
   for browser mode to actually work.

— end of handover —
