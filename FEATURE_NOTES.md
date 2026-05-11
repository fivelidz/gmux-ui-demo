# gmux UI — Feature Notes & Implementation Plan
**Captured:** 2026-05-09
**Implemented:** 2026-05-10 — all features below coded into `expose/version_zero/demos2/gmux-ui/index.html`
**Source file (latest demo):** `expose/version_zero/demos2/gmux-ui/index.html`  
**Canonical working file:** `UI_creation_independent/v2/index.html` (v2.4)
**Tauri backend:** `~/projects/gmuxtest/` (Rust lib.rs + Python monitor.py)

---

## 9 Feature Requests (verbatim + interpretation)

### 1. Create new agents easily — button, model selection, preset agents
**Request:** Possible to easily create new agents for each session with a button.  
The last model used should come up as the default.  
Model/agent can be selected and changed.  
Option for preset agents with transparency on their permissions/instructions  
when selected in the about section / agent list.

**What exists:**  
- New agent modal exists (cosmetic only — no Tauri command invoked)  
- Three types: QalCode 2, Claude Code, Terminal  
- No model picker, no presets, no permission transparency

**Implementation plan:**
- Add model selector dropdown to new agent modal (persist last-used model to localStorage)
- Available models: `claude-sonnet-4-5`, `claude-opus-4-5`, `claude-haiku-4-5`, `deepseek-r1`, `gpt-4o`
- Add "Preset agents" section: predefined system prompts with clear permission labels
  - e.g. "Code Reviewer" (read-only), "Architect" (read+write), "Terminal Bot" (full access)
- Each preset shows: name, description, permissions badge (🔒 read-only / ⚠️ write / ⚡ full)
- Wire `createAgent()` to invoke `open_project(dir)` Tauri command
- Add "About" section in agent sidebar showing: model, permissions, system prompt snippet

---

### 2. After voice — thumbs up to send message
**Request:** After using voice it should be thumbs up to input the message.

**What exists:**  
- Voice strip exists in chat panel with PTT button  
- `THUMBS_UP` gesture fires `approve()` on permission agents  
- No voice→confirm flow

**Implementation plan:**
- Add voice mode state: `voiceActive` + `voiceDraft` (accumulated transcript)
- When voice is active (mic open) and `gestureStart` fires `THUMBS_UP` on either hand:
  - Copy voiceDraft text into `#cp-inp`
  - Call `sendChat()` to submit it
  - Flash the input green briefly as visual confirmation
  - Stop voice mode
- Only applies when `voiceMode === true` (don't interfere with approval gesture in normal mode)

---

### 3. Get voice interactivity actually working
**Request:** Get the voice interactivity working.

**What exists:**  
- Mic access via `getUserMedia({audio:true})` works  
- AudioContext waveform + level meter works  
- Transcript text is **100% mock** — cycles through `MOCK_PHRASES[]` array  
- No real STT anywhere

**Implementation plan:**
- Use browser native `window.SpeechRecognition` (Web Speech API) — zero dependencies
  - Works in Chrome/Chromium/Electron/Tauri WebView
  - `recognition.interimResults = true` for live partial transcript
  - `recognition.continuous = false` — restart on each PTT press
- Flow:
  1. User presses PTT or POINT gesture → `recognition.start()`
  2. `onresult` events stream partial transcript to `.v-transcript` with `partial` class
  3. On `onend` → final result goes into `#cp-inp` as draft
  4. THUMBS_UP gesture (or Enter) → `sendChat()` submits
- Fallback: if SpeechRecognition unavailable → show toast "Voice requires Chrome/Chromium"
- For real production: wire to faster-whisper via WebSocket (already planned in SCOPE.md)

---

### 4. Both hands detected, not just one
**Request:** Both hands to be able to be detected not just one.

**What exists:**  
- `gesture-engine.js` supports two hands fully (`this.hands = { Left, Right }`)  
- `_updateTwoHandMetrics()` calculates cross-hand distances, angles, cross-pinch points  
- MediaPipe is configured with `numHands: 2` in v2  
- **The bug:** The hand-states HUD (`#hs-r`, `#hs-l`) and gesture sidebar only update  
  whichever hand fires. Both hands ARE detected but the UI only responds to whichever  
  hand is dominant in any given frame.

**Implementation plan:**
- Verify MediaPipe is initialized with `numHands: 2` (it should be already)
- Fix the `gestureStart` handler to process both hands per frame, not break early
- Update `#hs-r` and `#hs-l` displays on every `frame` event (not just `gestureStart`)
- Both the PiP canvas and the `#hand-overlay` canvas already draw both hands via the renderer
- Add a "twoHand" visual indicator in the gesture sidebar when both are detected

---

### 5. Both index fingers together = activate talking
**Request:** Talking can also be activated by bringing both index fingers together.

**What exists:**  
- `_updateTwoHandMetrics()` already computes `crossPinch.index.dist` = distance between  
  the two hands' index-thumb pinch points  
- Also computes raw `indexDist` = distance between `lm_L[8]` and `lm_R[8]` (index tips)

**Implementation plan:**
- In the `twoHand` event handler, check:
  ```js
  engine.on('twoHand', (data) => {
    // Index tips close together (< 0.08 normalized distance)
    if (data.indexDist < 0.08 && !voiceMode) {
      toggleVoice();
    }
  });
  ```
- Debounce: 800ms cooldown after trigger to prevent flicker
- Visual: when the two index tips are close, draw a connecting arc/spark on the overlay canvas
- This is additive — POINT gesture on left hand still also works

---

### 6. Dragging an agent panel should insert it above the drop target, not swap
**Request:** Moving an agent panel doesn't actually swap it with the panel it is placed on.  
It should work by inserting itself one above whatever other panel it is dragged to.

**What exists:**  
- Drag handles exist on panes (`.pane-drag`)  
- `dragstart` / `dragover` / `drop` handlers exist  
- Current behavior: swaps the two panes' positions in the `panes` array  
- `.drag-over` class applied as visual indicator

**Implementation plan:**
- Change drop logic: instead of `arr.splice(toIdx, 0, arr.splice(fromIdx, 1)[0])` (swap),  
  do true insertion: remove from `fromIdx`, insert at `toIdx` (one position above drop target)
- Visually: show a line/bar ABOVE the hovered pane (not an outline around it) to indicate  
  insertion point, like a proper list reorder
- CSS: add `.drop-above` style with a top-border accent line instead of `.drag-over` outline
- The grid re-renders on `panes` array change so order will immediately update

---

### 7. THREE gesture to jump to next waiting agent ✓ (keep as-is)
**Request:** The gesture three is pretty good to pick up and going to next waiting agent is smart.

**Status:** Keep. Works (when swipe bug is fixed). No changes needed.

---

### 8. Remove THUMBS_DOWN — only use THUMBS_UP
**Request:** Thumbs down doesn't register properly so we should just have thumbs up.

**What exists:**  
- `THUMBS_DOWN` has **no classifier rule** in `_classifyGesture()` — it literally never fires  
- The reject/deny button still exists in the UI  
- `THUMBS_UP` = approve, `THUMBS_DOWN` = reject — both referenced in gesture map

**Implementation plan:**
- Remove `THUMBS_DOWN` from the gesture tutorial list and gesture map display
- Remove the THUMBS_DOWN handler from `gestureStart` listener
- Keep the reject button in the permission UI (clickable/pinch) but remove the gesture binding
- Update hotkeys reference table to remove 👎 row
- Consider: FIST as an alternative reject gesture (more distinct, easy to detect) — optional

---

### 9. Session switching / adding — pointer dwell to select (no visual hint, timer fill)
**Request:** To change the sessions and add a session this should be able to be done  
by pointing and holding the pointer over the session to select.  
This should NOT be indicated (no tooltip/hover hint) but require the finger to be left  
there for a time with a visual LOAD feature indicating it is being selected.  
Reference: how we did this in the Hand of the King game on the menu UI.

**Reference implementation (castle-defense/index.html):**
- `registerDwellTarget(id, x, y, w, h, frameCount, callback)` — registers a hit zone
- `getDwellProgress(id)` → returns 0..1 float
- `--dwell-progress` CSS custom property set each frame via `setProperty`
- CSS `::after` pseudo-element animates a fill bar from 0% → 100% width
- `btn-dwell-active` class makes the `::after` bar visible
- No visual hint until the dwell starts — only the fill bar appears while hovering

**Implementation plan for gmux sessions:**
- Session pills (`.stab`) in the topbar get dwell targets registered when gesture mode is on
- Dwell time: ~60 frames (~1 second at 60fps) — feels natural, not too slow
- Visual: a thin arc/line that fills around the bottom edge of the session pill
  - CSS: `.stab::after { content:''; position:absolute; bottom:0; left:0; height:2px; background:var(--accent); width: calc(var(--dwell-progress, 0) * 1%); }`
  - No cursor change, no tooltip, no pre-fill hint — just the bar appears as you hold
- On complete (progress = 1): switch to that session (existing `switchSession()` call)
- The `+ add` session tab also gets a dwell target → opens new session modal
- Implemented in the overlay's `frame` event loop — check index tip position against pill rects each frame
- Reset progress if finger moves away

---

## Critical Bugs to Fix First (pre-requisites)

### BUG A — Swipe events never reach the gestureStart handler
**File:** `v2/index.html` (and `demos/03-full-ui/index.html`)  
**Problem:** Handler listens for `engine.on('gestureStart', e => { if (g === 'SWIPE_RIGHT') ... })`  
but engine emits swipes via `engine.on('swipe', ...)` — different event channel.  
**Fix:**
```js
// Add alongside existing gestureStart handler:
engine.on('swipe', ({ hand, direction }) => {
  if (direction === 'RIGHT') { /* next pane */ }
  if (direction === 'LEFT')  { /* prev pane */ }
  if (direction === 'UP')    { gestureScroll(-160); }
  if (direction === 'DOWN')  { gestureScroll(160); }
});
```

### BUG B — object-fit:cover landmark offset
**File:** `shared/gesture-renderer.js`  
**Problem:** `_toScreen()` has cover compensation but `config.cover` is never set.  
Landmarks draw offset from real finger position on the screen.  
**Fix:** Pass cover metadata when creating the renderer for the cam-video element.

---

## Tauri Build Status

**Backend is LIVE and functional:**
- `~/projects/gmuxtest/src-tauri/src/lib.rs` — Rust PTY + state polling + event emission
- `/tmp/gmux-pane-state.json` — written by `monitor.py` every 2s
- `gmux-state` Tauri event emitted every 1s to JS
- `initDataSource()` in the UI already detects Tauri and switches from mock to live data
- `pty_write`, `pty_resize`, `open_project`, `get_pane_state` commands all implemented

**What's missing for full Tauri integration:**
1. `createAgent()` needs to call `invoke('open_project', {path: dir})` — currently just toasts
2. HTTP/SSE endpoint in `monitor.py` for web/phone access (not needed for Tauri app itself)
3. Approval/rejection commands need a Tauri command → shell escape to send tmux keystrokes
4. Voice STT: Tauri's WebView (WKWebView on mac, WebView2 on Windows, WebKitGTK on Linux)  
   — on Linux/CachyOS, WebKitGTK supports Web Speech API ✓

**To run the Tauri app:**
```bash
cd ~/projects/gmuxtest
npm run tauri dev
# Python monitor spawns automatically via Tauri sidecar
```

---

## Implementation Priority Order

| # | Feature | Complexity | Impact |
|---|---------|-----------|--------|
| 1 | Fix swipe event wiring (Bug A) | Low | 🔥 Critical — unblocks nav + scroll |
| 2 | Real voice STT (Web Speech API) | Medium | High — core interaction |
| 3 | Both index fingers = talk | Low | High — natural gesture |
| 4 | Thumbs up = send voice message | Low | High — completes voice flow |
| 5 | Remove THUMBS_DOWN | Low | Medium — cleanup |
| 6 | Session dwell-select | Medium | High — gesture UX |
| 7 | Panel insert-above (not swap) | Low | Medium — polish |
| 8 | Both hands confirmed visible | Low | Medium — clarity |
| 9 | New agent: model selector + presets | High | High — product feature |

---

## Files to Modify

| File | Changes |
|------|---------|
| `expose/version_zero/demos2/gmux-ui/index.html` | Primary working file — all JS changes |
| `shared/gesture-engine.js` | Remove THUMBS_DOWN from classifier (or keep, just don't wire it) |
| `shared/gesture-renderer.js` | Fix cover offset config |
| `~/projects/gmuxtest/src-tauri/src/lib.rs` | Add approval Tauri command |
| `~/projects/gmuxtest/src-py/status/monitor.py` | Add HTTP/SSE endpoint (optional) |
