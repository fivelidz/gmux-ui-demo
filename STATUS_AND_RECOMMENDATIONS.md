# gmux UI — Status & Recommendations

**Date:** 2026-05-01
**Active build:** `v2/index.html` (v2.3 in progress; baseline v2.2 archived as `index.v2.2.preTrack.backup.html`)
**Live URL (local dev):** http://localhost:5550/v2/index.html

---

## Five development tracks

The product is being driven forward on five parallel tracks. Each track has its own success criteria, status, and next actions. Backend (Track 2) is intentionally last — the UI ships in pure HTML/JS and demos at gmux.ai *without* backend.

| # | Track | Status | Owner this sprint |
|---|---|---|---|
| 1 | **Gestures** — getting hand recognition reliable | active | this session |
| 2 | **Backend correspondence** — clean Tauri/HTTP data contract | deferred | last |
| 3 | **Packaging / shipping** — single-file demo, gmux.ai embed | active | this session |
| 4 | **Voice** — waveform, mic level, transcript, target highlight | active | this session |
| 5 | **AI performance & interaction** — tokens/sec, ttft, cost, history | active | this session |

---

## Track 1 — Gestures

### What works (verified in browser)
- MediaPipe HandLandmarker loads from CDN, GPU delegate, two-hand tracking.
- Per-hand state pills + confidence bars.
- Gesture-to-command map renders and flashes on fire.
- Recent action log (last 8).
- **Pinch-as-click** — confirmed working by user. Pinch with either hand triggers a synthetic `click` at thumb/index midpoint, with debounce (350 ms) and hysteresis (enter 0.30, exit 0.46).
- Full-screen hand overlay always-on while gesture mode is active (`<canvas id="hand-overlay">`, `pointer-events: none`).
- PiP camera preview (3 sizes, click to cycle).

### Known issues / improvement ideas
1. **Gesture flutter on borderline confidence.** SWIPE / THUMBS sometimes mis-fires when hand is moving between gestures. Confirm-frames is 3 — could expose as user setting and tune defaults.
2. **No teaching mode.** First-time users don't know what gestures exist or how the system thinks they're doing. Add a "training overlay" that shows live gesture recognition with a checklist of all gestures the user has successfully performed.
3. **No gesture-to-pane visual feedback.** Pinch fires a click but there's no permanent record of where you clicked. Add a brief crosshair trail at the click point.
4. **Open-palm gesture conflicts with idle.** Open palm is the natural rest position — currently mapped to "open chat". Consider replacing with a less-natural gesture (e.g. THREE-fingers → chat) and reserving open-palm for "show gesture legend".
5. **Sensitivity slider is non-persistent.** Slider in Options sets `engine.config.swipeVelocityThreshold` but value resets on reload.
6. **No two-hand gestures yet.** Single-hand only. Two-hand pinch (zoom), spread (next/prev session), wrist-distance (volume) are obvious additions.
7. **Cursor lag on pinch movement.** The full-screen overlay refreshes at requestAnimationFrame, but the cursor dot lags slightly behind the actual fingertip. May need predictive smoothing.
8. **Mirror-flip confusion.** MediaPipe labels Left/Right relative to camera; we mirror in display. The remapping (`viewerHand = label === 'Left' ? 'Right' : 'Left'`) is correct but error-prone — should be a single function with a unit test.

### Next actions for Track 1
- [ ] Add a **Gesture Tutorial overlay** (press `?` or click ✋ pill) that shows each gesture with a live confidence bar; tick off each gesture as the user successfully performs it.
- [ ] Persist sensitivity slider to localStorage.
- [ ] Add a **pinch trail / click ripple** that lingers 600 ms at the click point.
- [ ] Move open-palm to "show gesture legend" and use **CLOSED_FIST** for chat (more deliberate gesture).
- [ ] Document the L/R mirror logic in one helper `viewerHand(mediapipeLabel)`.

---

## Track 2 — Backend correspondence (deferred)

### Current data contract
The UI consumes pane state via `shared/mock-data.js → initDataSource()`. In Tauri it listens to `gmux-state` events; in the browser it runs `startMockEvolution()`.

```jsonc
// /tmp/gmuxtest-pane-state.json — ground truth schema
{
  "%1": {
    "pane_id": "%1", "window_index": 1, "window_name": "volkus",
    "state": "working", "has_ai": true,
    "last_line": "...", "current_tool": "write",
    "todo_done": 6, "todo_total": 8,
    "session_name": "gmux", "sub_agent_permission": false,

    // extended (from ram_tracker — not yet wired):
    "ram_mb": 1240, "vram_mb": 180, "cpu_pct": 34,
    "token_in": 42800, "token_out": 18300,
    "model": "claude-sonnet-4-5",
    "tool_history": ["read","glob","read","write"],
    "uptime_s": 847,
    "api_port": 8765,             // v2.2 added
    "children": [{"name":"node","ram":480}]   // v2.2 added (mock only)
  }
}
```

### Improvements to plan (do not implement yet)
1. **Pane chat history must be in the contract.** Currently `CHAT[paneId]` is a UI-side mock. The backend needs to write rolling chat per pane (last N messages) to a separate file or an event stream.
2. **Add `cwd` field** so the Folder Graph panel can show real per-agent directories.
3. **`session_color`** and **`session_id`** on the pane object so the session pills are data-driven.
4. **Tool history with timestamps** — currently a flat array; should be `[{tool, ts, ms}]` so we can show a timeline.
5. **Sub-agent tree** — `parent_pane_id` field so we can render hierarchies.
6. **Cost / token-rate** — emit per-second deltas, not just running totals.
7. **HTTP endpoint** alongside the Tauri event so Electron / web demos / phone PWAs can poll the same data.
8. **Schema versioning** — `_schema: "v1"` field so old/new clients can detect mismatches.

### Next actions for Track 2 (later)
- Document the full schema in `BACKEND_CONTRACT.md`.
- Stub out an HTTP `/state.json` server in `tauri-app/src-tauri/src/http.rs`.
- Add `_schema` and `cwd` fields to the live emitter.

---

## Track 3 — Packaging & shipping

### Goal
A single-file, dependency-free `gmux-demo.html` that:
- Runs at `gmux.ai/demo` (hidden link in the website footer).
- Auto-runs mock evolution.
- Has a "this is a demo" badge so visitors know nothing is real.
- Ships gestures + voice mock + theme switcher with no backend.

### Why a single file
- Embedding into Webflow / Framer / static sites is one `<iframe>`.
- No CORS, no build step, no module loader.
- Can be opened from `file://` if needed (today the v2 build can't, because it imports modules).

### Build approach
Two flavours:
1. **`v2/index.html`** stays as a multi-file dev build (importing `../shared/*.js`).
2. **`gmux-demo.html`** at the repo root: same UI but with `mock-data.js`, `gesture-engine.js`, `gesture-renderer.js` inlined into one file.

### Hidden link to gmux.ai
Add a small clickable element in the topbar (only visible when you know to look) that opens `https://gmux.ai/demo` in a new tab. Behaviours:
- The brand `bdot` (the pulsing purple dot) becomes long-press-able. Long-press 800 ms → opens the demo URL.
- Or: triple-click on the version label → reveals a "Share demo URL" toast with the link.

### Next actions for Track 3
- [x] Build `gmux-demo.html` — single-file, inlined modules, demo-only banner.
- [x] Add hidden long-press handler on `.bdot` to open `https://gmux.ai/demo`.
- [x] Add a small `Share` / `?demo` flag that exposes the URL via a toast.
- [ ] Write `PACKAGING.md` — covers Tauri bundle, Electron bundle, web embed (this last one done).

---

## Track 4 — Voice

### Goal
Voice is one of the three product pillars but currently nearly invisible in the UI:
- A pulsing red border on the Voice button.
- A `voiceTarget` is tracked but only shown by a left-edge tint on the targeted agent row (`.arow.vt`).
- PTT button in chat panel adds a fake "(voice message sent)" line.

### What "voice working in the UI" means
1. **Mic level meter** — visible volume bar that responds to actual microphone input (using `AudioContext.createAnalyser()`).
2. **Waveform** — small 60-frame circular buffer, drawn as a filled blob shape.
3. **Mock streaming transcript** — when voice is "on", words appear one at a time (mock LLM-driven phrasing).
4. **Voice target highlight** — the targeted pane gets a glowing border + a "🎙 listening" pill. Selecting another pane updates the target.
5. **Wake-word feedback** — show `"kalarc"` detected with a subtle ripple effect.
6. **Push-to-talk vs hands-free** — toggle in Options.

### Next actions for Track 4
- [x] Add `<canvas id="voice-waveform">` to the chat panel header (only visible when voice on).
- [x] Wire `getUserMedia({audio:true}) → AudioContext → AnalyserNode` for live mic level.
- [x] Mock streaming transcript: when PTT held, show partial words ticking up.
- [x] Border-glow animation on the voice-target pane.
- [ ] Wake-word detection placeholder (Picovoice Porcupine wasm — research only).

---

## Track 5 — AI performance & interaction

### Goal
Make every agent's *cost* and *throughput* visible at a glance.

### Current state
- Hardware tab shows tokens (in+out) as a single number.
- Model name shown as a string.
- No tokens/sec, no time-to-first-token, no cost estimate.

### Improvements
1. **Tokens/sec sparkline** — last 60 seconds of token rate, drawn inline in the pane footer.
2. **TTFT badge** — when a request fires, time the gap until the first agent message. Show as `↺ 1.2s` on the next reply.
3. **Cost estimate** — pricing table per model; show running cost in the hardware tab. (Even a rough estimate is more useful than nothing.)
4. **Tool history timeline** — instead of a flat array, render the last 20 tool calls as a horizontal timeline strip with type-coloured ticks.
5. **Comparison view** — when multiple agents are running, show a small table at the bottom with rows: agent | model | tokens | $/min | tools/min. Lets the user spot the runaway agent.
6. **Permission rate** — count `permission` events per minute. Helps tune permission thresholds.

### Next actions for Track 5
- [x] Add `tokens_in_per_s`, `tokens_out_per_s` to mock evolution.
- [x] Render a 60-frame sparkline in the pane footer for tokens/sec.
- [x] Add a `MODEL_COST` table and show `~$0.42` per agent in the hardware tab.
- [x] Tool history timeline strip in the hardware tab.
- [ ] Cross-agent comparison sheet (separate panel, opt-in).

---

## Versioning

| Version | Date | Highlights |
|---|---|---|
| v2.0 | Apr 24 (early) | First v2 build |
| v2.1 | Apr 24 13:15 | Sessions, panels |
| v2.2 | Apr 24 15:16 | Tab cycle (Tasks/Chat/HW), themes, RAM badges, fullscreen panes, modal new-agent |
| v2.2-preTrack | May 1 11:20 | Backup before track work |
| v2.3 | May 1 11:26 | Voice, sparklines, cost, ripple, tutorial, single-file demo |
| **v2.4** | May 1 (current) | UX fixes from user feedback (8 items) — see below |

## v2.4 — UX feedback round (May 1)

User feedback after first v2.3 session, all addressed in this build:

| # | Issue | Fix |
|---|---|---|
| 1 | Selected agent should have a coloured outline (purple/red/green) | `pane.sel-pane` now has a 2px purple outline; voice mode turns it red; approve flashes it green for 900ms. |
| 2 | Inactive panes too washed out / hard to read | `.pane.dim` lifted from `brightness(.65)` to `brightness(.92)` — readable but still de-emphasised. |
| 3 | Chat panel + Graph panel had redundant headers | Chat: removed `.ph` row entirely, drag-handle merged into `cp-head`. Graph: slim 28-px header with FOLDERS label + close button only. |
| 4 | Couldn't hide gesture panel without turning gestures off | Added `−` button on gesture panel header + `hideGesturePanel()`. Engine keeps running, PiP stays visible. `G` key restores panel. |
| 5 | Chat panel needed fullscreen + gesture scroll | New `⛶` button + `F` keybind toggles `#chat-panel.fullscreen`. SWIPE_UP / SWIPE_DOWN on right hand now scrolls the chat messages (or in-pane chat / todo list, whichever is most relevant). |
| 6 | Sessions weren't really clickable / no counts | Sessions filter `sorted()`. Added "All" pseudo-pill. Each pill shows a count badge. `addSession` now actually creates a session via `prompt`. Mock data sprinkled across 3 sessions for demo. |
| 7 | UI froze (cumulative timer/render storms) | Single perf-tick `setInterval` with overlap guard `_perfTickRunning`. Light DOM updates only — no full `render()` from the timer. Transcript timers cleaned up properly via `clearTranscriptTimers()` on stop. `_lastTool` declared before the data-source callback (was a TDZ bug). |
| 8 | Need a new build | Bumped to v2.4. `./build-demo.sh` produces a fresh `gmux-demo.html`. |

---

## How to run

```bash
cd ~/projects/gmuxtest/UI_creation_independent
./serve.sh                     # http://localhost:5550
# or specifically:
python3 -m http.server 5550

# v2 (dev, modular):
open http://localhost:5550/v2/index.html

# Single-file demo (for embedding):
open http://localhost:5550/gmux-demo.html
```

## Files of interest

```
v2/index.html                       ← active dev build (v2.3)
v2/index.v2.2.preTrack.backup.html  ← snapshot pre-track work
gmux-demo.html                      ← single-file embeddable demo (NEW)
shared/mock-data.js                 ← canonical state schema + Tauri bridge
shared/gesture-engine.js            ← MediaPipe → gesture events
shared/gesture-renderer.js          ← skeleton + trail rendering
STATUS_AND_RECOMMENDATIONS.md       ← this file
```
