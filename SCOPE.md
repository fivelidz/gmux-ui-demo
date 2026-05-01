# gmux UI — Scope, Vision & Build Plan

**Working directory:** `UI_creation_independent/`  
**Status:** Independent UI build — no backend required  
**Date:** April 2026

---

## What gmux Is

gmux is a **gesture-first, voice-ready, ambient workspace** for people running multiple AI coding agents simultaneously. It wraps tmux (battle-tested session management) with a rich visual layer that makes 10 parallel AI processes *feel calm* rather than chaotic.

The core insight: when you have 8–12 AI agents running, the problem isn't computing power — it's *attention management*. You need to know which agent is stuck, which needs a decision, which is done. You need to navigate between them without touching a keyboard. You need to speak a direction and have it land on the right agent.

gmux solves all three: **see**, **navigate**, **speak**.

---

## The Three Pillars

### 1. Gesture Navigation
- **Right hand** = navigation (swipe left/right to switch windows, swipe up/down to scroll)
- **Left hand** = commands (point = toggle voice, three-fingers = jump to waiting agent, thumbs-up/down = approve/reject)
- MediaPipe HandLandmarker, 21 landmarks per hand, runs entirely on-device
- Detection: geometric rules (finger extension, tip distances) + motion (wrist velocity over 8 frames)
- Confirmation model: 3 frames same gesture → fire, 300ms cooldown after
- Two-hand mode: cross-hand pinch, wrist distance, angle — for advanced interactions

### 2. Voice Integration  
- Wake word: "kalarc" (configurable)  
- faster-whisper STT, ~400ms on-device  
- Speaks to whichever agent is currently selected/gestured-at  
- Toggle via left-hand POINT gesture, or push-to-talk  
- Phone PWA can also push voice from anywhere in the room

### 3. Agent State Visibility
Seven agent states, each with a colour:
- 🔴 **waiting** — agent is ready for your input, needs a prompt
- 🟢 **working** — agent is running tools/streaming
- 🟠 **permission** — main agent needs tool approval (`!`)
- 🟠 **sub_permission** — sub-agent waiting (`^!`)
- 🔵 **done** — just finished
- ❌ **error** — broken
- ⚫ **idle** — no AI in this pane

---

## The Extended Vision (from gmux.ai)

The website reveals the full product vision beyond the terminal:

### Layouts
- **Focus** — single agent fullscreen
- **Fleet** — all agents as equal cards (grid view)
- **Pair** — two agents side by side
- **Review** — one large + sidebar of others
- **Broadcast** — projector mode, large text, gesture-navigable from 3m away

### Use Cases
1. **Projector/TV** — cast on the wall, wave to switch agents from the couch
2. **On the go** — phone as remote (PWA at :8768), volume keys = cycle panels, PTT = voice
3. **Many agents** — fleet view, CPU/RAM/token usage visible per agent
4. **Shared screens** — two people can gesture at the same agent, both speak

### Gesture Playground (on gmux.ai)
The website has a *live gesture demo* in the browser — hand skeleton with labels (PINCH spawns glowing orbs, particle mycelium reaches toward fingertips). This is the interaction model we need to match and exceed in the standalone demos.

### Extended Canvas Layer
The gmux.ai site mentions an "extended canvas layer that keeps hands on screen better." This refers to:
- Expanding the detection zone beyond the camera frame
- Smooth interpolation at the edges (hands don't suddenly disappear)
- Depth-based gesture scaling (closer hand = larger effect)
- Motion prediction (short-term trajectory extrapolation)
- The parallax.js optional 3D depth effect in the overlay

---

## Why UI-First (Independent Build)

The problem so far: UI has been coupled to the backend (Tauri + Rust + PTY + live tmux state). This means:
1. Can't iterate fast — every UI change needs a full Tauri rebuild
2. Can't test gestures without the tmux stack running
3. Design decisions get blocked by plumbing concerns

**Solution:** Build all UI as pure HTML/CSS/JS demos first.  
- No Tauri, no Rust, no tmux required  
- Fast iteration (just refresh the browser)  
- Gesture engine + renderer already works standalone (just needs a webcam)  
- Mock the state data — agent cards with fake state transitions  
- When it looks and feels great, *then* wire it to the backend

---

## What We're Building Here

### Demo 1: Gesture Playground (`demos/01-gesture-playground/`)
A standalone beautiful gesture canvas demo:
- Full-screen camera + hand skeleton overlay
- Both hands tracked with the existing gesture-engine.js + gesture-renderer.js
- Real-time gesture label pills floating above each hand
- Particle/orb system triggered by pinch (like gmux.ai)
- Mycelium/network background that reacts to hands
- Gesture legend panel (toggleable, shown on OPEN_PALM)
- No backend — pure camera + ML + canvas

### Demo 2: Agent Fleet View (`demos/02-fleet-view/`)
The main UI screen — agent cards in different layout modes:
- Fleet grid (6, 9, 12 agents)
- Focus mode (one large card)
- Pair mode (two side by side)
- Animated state transitions (working → permission → done)
- RAM/CPU/token mock data
- Gesture navigation between layouts (swipe to switch)
- No camera required — keyboard-controlled mock

### Demo 3: Full Gesture UI (`demos/03-full-ui/`)
The combination — camera + gesture + agent fleet:
- Split layout: left = agent fleet, right = camera PiP
- Gesture controls the fleet (swipe = cycle agents, point = select)
- Voice indicator (mock) shows which agent is "listening"
- State HUD showing current gesture + confidence
- Beautiful visual feedback: glow on selected agent, trail on swipe

### Demo 4: Projector Mode (`demos/04-projector/`)
Large-format display for TV/wall:
- 2xl typography, high contrast
- Single agent at a time, full screen
- Gesture: swipe cycles agents
- Shows agent name, state, current tool, last few lines of output (mock)
- Minimal UI — designed to be readable from 3m

### Demo 5: Voice + Gesture Integration (`demos/05-voice-gesture/`)
The voice detection UI layer:
- Microphone waveform visualizer
- Voice status pill (idle / listening / processing / speaking)
- Shows transcribed text as it comes in (mock streaming)
- Which agent is targeted (highlighted card)
- Gesture selects target agent, POINT toggles listen

---

## Technology Choices

### Tauri (primary — `tauri-app/`)
- Rust backend gives us: PTY terminal, global shortcuts, native window management, file system access
- WebView frontend — same JS as demos, just wrapped
- v4l2loopback camera sharing already set up
- Best for: the actual shipped app

### Electron (research — `electron-app/`)
- Easier to package cross-platform
- Chromium gives broader web API access
- More npm ecosystem compatibility
- Heavier but faster to prototype
- Worth exploring for: packaging, distribution, broader device support

### Pure HTML/JS (demos — `demos/`)
- Zero build step, instant iteration
- Works in any browser
- Perfect for UI prototyping and gesture testing
- Ships to gmux.ai playground as-is

---

## Gesture-to-Voice Integration Points

The key UX moments where gesture and voice connect:

1. **Agent Selection** (gesture → voice target)
   - User swipes to a window tab → that agent becomes the voice target
   - Visual: selected agent glows, voice indicator shows agent name
   - UX: no keyboard needed, very natural "I'm looking at this one"

2. **Listen Toggle** (left hand POINT → voice on)
   - Raise index finger = start listening
   - Lower finger = stop
   - Glow + waveform appear on selected agent card
   - Mock: waveform animates, pill shows "listening..."

3. **Approval Flow** (gesture replaces keyboard)
   - Agent shows orange `!` = needs tool approval
   - Left hand THUMBS_UP = approve
   - Left hand THUMBS_DOWN = reject
   - Visual: quick green/red flash on the card, state transitions

4. **Jump to Red** (left hand THREE → jump to next waiting agent)
   - Immediately selects next `waiting` agent (red state)
   - Camera pan animation on the fleet grid
   - Most important for "passive oversight" mode

5. **Gesture HUD** (always visible when gesture mode on)
   - Bottom-left: current gesture name + confidence bar + hand role indicator
   - Bottom-right: camera PiP with skeleton
   - Top-center: action fired ("→ next window", "✋ voice on")
   - All can be toggled per settings

---

## Design Language

Based on the existing codebase + gmux.ai website aesthetic:

### Palette
```
bg:         #07090f    /* near-black space */
surface:    #0d1117    /* GitHub dark surface */
card:       #161b22    /* agent cards */
border:     #21262d    /* subtle dividers */
muted:      #6e7681    /* secondary text */
text:       #e6edf3    /* primary text */
accent:     #6c5ce7    /* purple — brand */
accent2:    #00d2ff    /* cyan — right hand */
accent3:    #ff6b35    /* orange — left hand */
waiting:    #ef4444    /* red — needs input */
working:    #22c55e    /* green — running */
permission: #f97316    /* orange — approval */
done:       #3b82f6    /* blue — finished */
```

### Typography
- Headlines: 700–800 weight, tight letter-spacing (-0.03em)
- Body: 'SF Pro Text', 'Inter', system-ui — 13px
- Labels: 11px, 600 weight, uppercase tracking
- Terminal: monospace, 13px
- Projector mode: 24–32px, ultra-high contrast

### Motion
- State transitions: 300ms ease
- Gesture confirmation: ripple expand from landmark
- Card state change: soft glow pulse (200ms)
- Swipe: smooth scroll with momentum (physics-based)
- Trail: 24-frame history, opacity fade
- Particle system: organic drift, ~60 FPS

### Layout Principles
- **Density over whitespace** — information-dense but calm
- **Colour does the heavy lifting** — status is always colour-coded
- **Edge of screen awareness** — hands should be detectable at edges
- **Ambient readability** — designed to be glanced at, not stared at
- **Progressive disclosure** — gesture HUD appears only when hands detected

---

## Next Steps

1. **Build Demo 1** — Gesture Playground (pure canvas, beautiful, standalone)
2. **Build Demo 2** — Fleet View with mock state
3. **Build Demo 3** — Combined gesture + fleet
4. **Scaffold Tauri app** in `tauri-app/` — port demos into Tauri shell
5. **Scaffold Electron** in `electron-app/` — parallel research
6. **Wire gesture events** — gesture-engine.js already event-driven, just connect handlers
7. **Wire voice mock** — animate waveform on POINT gesture
8. **Ship demos** — push to gmux.ai as embedded playground

---

## What "Beautiful" Means Here

The existing UI is functional but dark and dense. "Beautiful" here means:

- **Depth** — layers: background glow → particle system → UI cards → gesture overlay
- **Responsiveness** — UI reacts instantly to gesture events (no lag, no stutter)
- **Expressiveness** — gestures feel *satisfying* (ripples, trails, confirmations)
- **Calm** — state is communicated without alarm or noise (colour, not popups)
- **Polish** — micro-animations on every interaction (hover, click, state change)
- **Coherence** — every element uses the same design tokens, nothing feels bolted-on

This is the bar. Every demo should feel like it belongs to a serious, considered product.
