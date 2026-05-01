# gmux UI — Running Guide

Everything in this directory runs **independently of the backend**. No Rust, no tmux, no Python required to view or interact with the UIs. Mock data is built in and animates automatically.

When you're ready to wire live data, the `initDataSource()` function in each system automatically detects whether it's running inside Tauri and subscribes to the real `gmux-state` events.

---

## Quick Start — Browser (Fastest)

```bash
cd ~/projects/gmuxtest/UI_creation_independent
./serve.sh
```

Then open: **http://localhost:5550**

That's it. The hub page links to all demos and systems.

To use a different port:
```bash
./serve.sh 9000
```

Or with Python directly:
```bash
python3 -m http.server 8080
```

**Important:** You must serve over HTTP — not `file://`. ES module imports (`import { ... } from '...'`) and MediaPipe WASM require an HTTP server. Opening `index.html` directly in a browser will fail.

### Browser Compatibility

| Browser | Status | Notes |
|---|---|---|
| Chrome / Chromium | ✅ Full support | MediaPipe WASM + gesture works perfectly |
| Firefox | ✅ Full support | backdrop-filter needs `layout.css.backdrop-filter.enabled=true` in about:config if old version |
| Safari | ✅ Works | webkit-prefixed backdrop-filter, MediaPipe may need `-webkit-` |
| Edge | ✅ Full support | Chromium engine |

### Camera / Gesture in Browser

1. Open any system that has gesture support
2. Click **✋ Gesture** button (or press `G`)
3. Browser will ask for camera permission — allow it
4. MediaPipe model downloads from CDN (~8MB, cached after first load)
5. Hand skeleton appears in the PiP camera panel

**If MediaPipe fails to load**: You need an internet connection for the first load (model downloads from Google's CDN). After that it's cached in the browser.

---

## The 4 UI Systems

```
systems/
  A-ambient-glass/    Frosted glass, arc gauges, ambient colour auras
  B-dense-terminal/   Zellij-style pane grid, pane dimming, Powerline bar
  C-projector-focus/  Cinema-scale, one agent at a time, 3m-readable
  D-command-grid/     Raycast-style, searchable list, command palette
```

### System A — Ambient Glass
**URL:** http://localhost:5550/systems/A-ambient-glass/  
**Best for:** Desktop ambient display, second monitor, beautiful  
**Unique features:**
- Radial gradient aura behind each card (colour matches agent state)
- Arc gauge canvases for RAM and CPU (0–270° sweep)
- Frosted glass cards with `backdrop-filter: blur(16px) saturate(180%)`
- Full-screen agent selection in Focus view
- Ambient background canvas shifts colour as states change

### System B — Dense Terminal
**URL:** http://localhost:5550/systems/B-dense-terminal/  
**Best for:** Primary working display, maximum information density  
**Unique features:**
- Pane grid with **pane dimming** — inactive panes fade to 72% brightness, focus is visual
- Mock terminal output per pane with cursor blink
- Zellij-style pane headers (state dot, name, window, tool, badge)
- Per-pane footer: RAM · CPU · tokens · todo progress
- Right-side detail panel (toggle with `D` or Detail button)
- Powerline-style status bar segments

### System C — Projector Focus
**URL:** http://localhost:5550/systems/C-projector-focus/  
**Best for:** TV, projector, whiteboard, shared screen  
**Unique features:**
- 48px agent name, 28px metric values — readable at 3+ metres
- Left nav strip (coloured dots), right info strip (global counts)
- 6-metric grid per agent: RAM, CPU, tokens in/out, uptime, todos
- Ambient colour aura bleeds into the stage background
- Large approve/reject buttons (18px text, 18px padding)
- Action flash message: large, center-screen, auto-fades

### System D — Command Grid
**URL:** http://localhost:5550/systems/D-command-grid/  
**Best for:** Power users, keyboard-first, small screens  
**Unique features:**
- Raycast-style searchable agent list (⌘K to focus, type to filter)
- Filter presets: All / Active / Attention (waiting + permission only)
- Agent rows show state box (colour + character), RAM bar, current tool
- Command palette: contextual actions appear based on selected agent state
- Gesture HUD inline in the status bar (not a floating panel)
- Single blue accent colour — monochrome + accent design

---

## Running in Tauri (gmuxtest app)

The UI systems are designed to run as the **frontend of the gmuxtest Tauri app**. The shared `mock-data.js` automatically detects Tauri and switches to live data.

### Step 1: Copy a system into the Tauri src directory

```bash
# From the gmuxtest root
cp -r UI_creation_independent/systems/A-ambient-glass/* src/
# Or to test without disrupting main:
cp UI_creation_independent/systems/A-ambient-glass/index.html src/index-glass.html
```

### Step 2: Update the shared imports

The systems use relative imports (`../../shared/`). In the Tauri src, update the import paths:

```js
// Change this:
import { ... } from '../../shared/mock-data.js';
import { GestureEngine }   from '../../shared/gesture-engine.js';
import { GestureRenderer } from '../../shared/gesture-renderer.js';

// To this (Tauri src/ flat structure):
import { ... } from './mock-data.js';
import { GestureEngine }   from './gesture-engine.js';
import { GestureRenderer } from './gesture-renderer.js';
```

Copy shared files:
```bash
cp UI_creation_independent/shared/mock-data.js       src/
cp UI_creation_independent/shared/gesture-engine.js  src/
cp UI_creation_independent/shared/gesture-renderer.js src/
```

### Step 3: Run the Tauri dev server

```bash
cd ~/projects/gmuxtest
npm run tauri dev
```

This starts:
- Vite dev server on port 1421
- Tauri window pointing at `http://localhost:1421`
- Rust poll thread reading `/tmp/gmuxtest-pane-state.json` every 1s
- PTY connecting to tmux session

### Step 4: Live data auto-connects

When running in Tauri, `initDataSource()` in `mock-data.js` detects `window.__TAURI_INTERNALS__` and subscribes to the real `gmux-state` event instead of running mock evolution:

```js
// This runs automatically — no code change needed
if (window.__TAURI_INTERNALS__) {
  const { listen } = await import('@tauri-apps/api/event');
  await listen('gmux-state', (event) => {
    const real = JSON.parse(event.payload);
    // Merges into the pane objects
    onUpdate(merged);
  });
}
```

**Live data requires:**
- `monitor.py` running (writes `/tmp/gmuxtest-pane-state.json`)
- opencode/qalcode2 running in tmux panes
- At least one pane with `has_ai: true` in the state file

To start monitor.py manually:
```bash
python3.11 ~/projects/gmuxtest/src-py/status/monitor.py &
# Or via gmux:
gmuxtest start
```

### macOS Vibrancy (Tauri)

To enable native macOS blur-behind-window in Tauri, update `src-tauri/tauri.conf.json`:

```json
{
  "app": {
    "windows": [{
      "transparent": true,
      "decorations": false,
      "titleBarStyle": "Transparent",
      "hiddenTitle": true
    }]
  }
}
```

And in `src-tauri/src/lib.rs` (inside `.setup()`):

```rust
let window = app.get_webview_window("main").unwrap();
window.set_effects(tauri::window::WindowEffectsConfig {
    effects: vec![tauri::window::WindowEffect::UnderWindow],
    state: None, radius: None, color: None,
})?;
```

Add to `body` CSS:
```css
body { background: transparent; }
/* macOS traffic lights get 72px of padding-left */
#topbar { padding-left: 80px; }
```

> **Note:** When using `decorations: false` you lose native resize handles. Add `data-tauri-drag-region` to your topbar element and test resize manually.

---

## Running in Electron (Research Path)

For cross-platform packaging or if MediaPipe WASM has issues with WKWebView on macOS:

### Step 1: Create an Electron scaffold

```bash
mkdir ~/projects/gmux-electron && cd ~/projects/gmux-electron
npm init -y
npm install electron
```

Create `main.js`:
```js
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1400, height: 900,
    // macOS native vibrancy
    transparent: true,
    vibrancy: 'under-window',
    visualEffectState: 'active',
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 16 },
    backgroundColor: '#00000000',
    hasShadow: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
    }
  });

  // Point at the UI server (run serve.sh first)
  win.loadURL('http://localhost:5550/systems/A-ambient-glass/');
}

app.whenReady().then(createWindow);
```

Add to `package.json`:
```json
{ "main": "main.js", "scripts": { "start": "electron ." } }
```

### Step 2: Run

```bash
# In terminal 1: serve the UI
cd ~/projects/gmuxtest/UI_creation_independent && ./serve.sh

# In terminal 2: launch Electron window
cd ~/projects/gmux-electron && npm start
```

The Electron window will load the UI system with native vibrancy.

### Electron vs Tauri — When to choose each

| | Electron | Tauri |
|---|---|---|
| **MediaPipe WASM** | ✅ Full Chromium, zero concerns | ⚠️ Test SIMD on WKWebView (Safari) |
| **macOS vibrancy** | ✅ `win.setVibrancy('under-window')` | ✅ `WindowEffect::UnderWindow` in Rust |
| **PTY terminal** | Needs `node-pty` npm package | ✅ Native Rust `portable-pty` — already set up |
| **Bundle size** | ~150MB | ~5MB |
| **Windows blur** | ✅ `win.setBackgroundMaterial('mica')` | ✅ via Tauri |
| **Camera (macOS)** | ✅ Zero config | ✅ Needs NSCameraUsageDescription |
| **Ship to users** | Easier packaging | Better performance |

**Recommendation for gmux:** Stay with Tauri (PTY integration is already working). Use Electron only if you hit WebView/WASM compatibility issues.

---

## Tauri Event Reference

The Rust backend emits these events that the UI systems listen to:

| Event | Frequency | Payload | Received by |
|---|---|---|---|
| `gmux-state` | Every 1s | JSON string of pane state object | All systems via `initDataSource()` |
| `gmux-services` | Every 1s | JSON string of services flags | `updateServicesUI()` in main.js |
| `pty-data` | On terminal output | String (terminal bytes) | xterm.js `term.write()` |
| `first-launch` | Once at startup | `bool` | Shows welcome overlay |
| `gesture-toggle` | Global shortcut Alt+G | `()` | `toggleGestures()` |
| `voice-toggle` | Global shortcut Ctrl+Shift+Space | `()` | `setVoice(!)` |

### Pane state JSON schema

```json
{
  "%1": {
    "pane_id":              "%1",
    "window_index":         1,
    "window_name":          "volkus",
    "state":                "working",
    "has_ai":               true,
    "last_line":            "✓ Writing src/gesture-engine.js",
    "current_tool":         "write",
    "todo_done":            6,
    "todo_total":           8,
    "session_name":         "gmux",
    "sub_agent_permission": false
  }
}
```

The extended fields (`ram_mb`, `vram_mb`, `cpu_pct`, `token_in`, `token_out`, `model`, `tool_history`, `uptime_s`) come from `ram_tracker` integration (not yet live — see README).

---

## Gesture Reference

All 4 systems implement the same gesture bindings:

| Hand | Gesture | Action |
|---|---|---|
| Right | Swipe → | Next agent |
| Right | Swipe ← | Previous agent |
| Right | Swipe ↑ | Scroll up (where applicable) |
| Right | Swipe ↓ | Scroll down (where applicable) |
| Left | ☝ Point | Toggle voice on/off |
| Left | ✌+ Three fingers | Jump to next waiting/permission agent |
| Left | 👍 Thumbs up | Approve tool permission |
| Left | 👎 Thumbs down | Reject tool permission |
| Left | 🖐 Open palm | Show gesture reference (System A only) |

**Extended canvas zone:** All gesture systems use a 12% canvas extension (`EXTEND = 0.12`). This remaps MediaPipe's `[0,1]` normalized coordinates to `[-0.12, 1.12]`, so hands tracked near the edges of the camera frame don't abruptly disappear. A dashed ring around the PiP camera panel glows when a wrist is within 10% of the frame edge.

---

## Keyboard Reference

All systems share these keyboard shortcuts:

| Key | Action |
|---|---|
| `← →` or `↑ ↓` | Navigate between agents |
| `J` | Jump to next waiting or permission agent |
| `G` | Toggle gesture mode (enables camera) |
| `V` | Toggle voice targeting |
| `Enter` or `Space` | Approve permission (when selected agent needs approval) |
| `Backspace` | Reject permission (System D only) |
| `D` | Toggle detail panel (System B) |
| `F` | Toggle focus view / filter (Systems A, D) |
| `Escape` | Return to fleet / clear search |
| `⌘K` / `Ctrl+K` | Focus search input (System D) |

---

## File Structure

```
UI_creation_independent/
├── RUNNING.md                    ← This file
├── SCOPE.md                      ← Project vision and design language
├── RESEARCH_UI_DESIGN.md         ← Design research: glass, panes, gestures
├── index.html                    ← Hub page linking all systems + demos
├── serve.sh                      ← Quick HTTP server script
│
├── shared/
│   ├── mock-data.js              ← Canonical mock data + Tauri/mock bridge
│   ├── gesture-engine.js         ← MediaPipe gesture recognition (copied from src/)
│   └── gesture-renderer.js       ← Hand skeleton canvas renderer (copied from src/)
│
├── systems/                      ← The 4 fully-fleshed UI systems
│   ├── A-ambient-glass/          ← Frosted glass + arc gauges + colour auras
│   ├── B-dense-terminal/         ← Pane grid + dimming + Powerline bar
│   ├── C-projector-focus/        ← Cinema-scale, 3m-readable, one agent focus
│   └── D-command-grid/           ← Raycast-style, searchable, command palette
│
├── demos/                        ← Earlier component demos
│   ├── 01-gesture-playground/    ← Gesture-only: live skeleton, confidence bars
│   ├── 02-fleet-view/            ← Fleet grid + layout modes
│   ├── 03-full-ui/               ← Gesture + fleet + voice targeting
│   ├── 04-projector/             ← Earlier projector mock
│   └── 05-voice-gesture/         ← Voice waveform + transcript + gesture state
│
└── mobile/
    ├── android/                  ← Android PWA remote control
    └── ios/                      ← iOS PWA remote control (HIG-native)
```

---

## Common Issues

### "TypeError: Failed to resolve module specifier"
You opened an HTML file directly (`file://`). You must serve it over HTTP. Run `./serve.sh`.

### MediaPipe model fails to load
First load requires internet (downloads ~8MB model from Google CDN). Check console for errors. Model is cached after first download.

### Camera permission denied
- Browser: click the camera icon in the address bar and allow
- Tauri macOS: `NSCameraUsageDescription` must be in `tauri.conf.json` bundle section
- Linux: check v4l2 devices are available, use `/dev/video2` (virtual cam) not `/dev/video0`

### backdrop-filter not showing
The glass effect requires content **behind** the element. The systems use a background canvas (`#bg-canvas`) at `z-index: 0`. If you see grey panels, check that:
1. The element has `position: relative/absolute/fixed` 
2. No `will-change: transform` is on the same element
3. You're not on Firefox with the flag disabled

### Tauri: events not firing
Make sure `monitor.py` is running. Check `/tmp/gmuxtest-pane-state.json` exists and is being written:
```bash
watch -n1 cat /tmp/gmuxtest-pane-state.json
```

### Gesture tracking jittery
Increase `gestureConfirmFrames` (currently 3) to 5 for less false triggers:
```js
engine = new GestureEngine({ gestureConfirmFrames: 5, smoothingFactor: 0.8 })
```

Decrease `swipeVelocityThreshold` (currently 0.022) for more sensitive swipes. Increase for fewer false swipes.
