# gmux UI Design Research
**Compiled:** April 2026  
**Purpose:** Concrete CSS/design patterns, technical approaches, and exact values for the gmux terminal multiplexer / AI agent dashboard UI

---

## 1. macOS Vibrancy / Frosted Glass — Exact CSS Patterns

### The Real macOS Vibrancy (Native, not CSS)
macOS vibrancy is `NSVisualEffectView` — it blurs the **actual OS desktop** behind the window, not just page content. You cannot replicate this perfectly in CSS because CSS `backdrop-filter` only blurs content *within* the web page. For a true vibrancy effect, you need OS-level access (Tauri or Electron APIs, see section 3/4).

### CSS Glassmorphism — Premium vs Cheap

**The difference between premium and cheap glass:**
- **Cheap**: White at 20% opacity, no saturation boost, heavy blur (>30px), no border
- **Premium**: Slight tint matching ambient context, `saturate()` boost, moderate blur (8–16px), subtle 1px border at 15–20% opacity, multi-layer shadow

#### The Premium Formula

```css
/* ── PREMIUM GLASS PANEL ── */
.glass-panel {
  /* The blur amount: 12px = macOS menu bar style, 20px = window chrome style */
  backdrop-filter: blur(12px) saturate(180%) brightness(1.05);
  -webkit-backdrop-filter: blur(12px) saturate(180%) brightness(1.05);

  /* Background: very low opacity + slight hue — NOT pure white/black */
  /* Dark theme (gmux): */
  background: rgba(13, 17, 23, 0.72);
  /* Light theme: background: rgba(255, 255, 255, 0.72); */

  /* Border: always use a light-on-dark or dark-on-light 1px border */
  border: 1px solid rgba(255, 255, 255, 0.08);
  /* For the top/left edge (catch the light): */
  /* box-shadow inset top: */

  /* Shadow: layered = depth, not flat */
  box-shadow:
    0 0 0 1px rgba(255, 255, 255, 0.04) inset,  /* inner edge catch */
    0 4px 6px -1px rgba(0, 0, 0, 0.3),           /* close shadow */
    0 10px 15px -3px rgba(0, 0, 0, 0.2),          /* mid shadow */
    0 20px 40px -10px rgba(0, 0, 0, 0.4);         /* ambient shadow */

  border-radius: 12px;
}
```

#### Exact rgba Values for gmux's Dark Theme

| Use case | background | blur | saturate |
|---|---|---|---|
| Titlebar / chrome | `rgba(7, 9, 15, 0.85)` | `blur(20px)` | `saturate(160%)` |
| Agent cards | `rgba(13, 17, 23, 0.70)` | `blur(12px)` | `saturate(180%)` |
| HUD overlays | `rgba(22, 27, 34, 0.60)` | `blur(16px)` | `saturate(200%)` |
| Tooltip/popover | `rgba(13, 17, 23, 0.90)` | `blur(8px)` | `saturate(120%)` |
| Modal backdrop | `rgba(0, 0, 0, 0.50)` | `blur(4px)` | `saturate(100%)` |

#### The Saturation Trick (Most Important)
`saturate(180%)` is what makes glass look premium. It boosts the colours behind the element, making the content above it pop. Without this, blurred backgrounds look grey and muddy.

```css
/* Cheap — looks washed out */
.cheap-glass {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(30px);
}

/* Premium — colours sing through */
.premium-glass {
  background: rgba(13, 17, 23, 0.65);
  backdrop-filter: blur(12px) saturate(180%) brightness(1.02);
  -webkit-backdrop-filter: blur(12px) saturate(180%) brightness(1.02);
}
```

#### The Border Trick
Premium glass has a **light edge catch** — 1px border on top/left that simulates light reflecting off glass:

```css
.glass-premium {
  border: 1px solid rgba(255, 255, 255, 0.10);
  /* OR: only top+left */
  border-top: 1px solid rgba(255, 255, 255, 0.15);
  border-left: 1px solid rgba(255, 255, 255, 0.10);
  border-right: 1px solid rgba(255, 255, 255, 0.04);
  border-bottom: 1px solid rgba(255, 255, 255, 0.04);
}
```

#### For the Background to Blur (Critical!)
`backdrop-filter` **only works if there is something behind the element to blur**. For your agent dashboard:
1. The background must be a rich scene (gradient, particles, live content) — not a flat colour
2. The glass element must have `position: relative/absolute/fixed` and not be the deepest layer
3. **The background scene must be `z-index` lower than the glass panel**

```css
/* Required setup */
.scene-background {
  position: fixed;
  inset: 0;
  z-index: 0;
  /* Your gradient/particle canvas goes here */
  background: radial-gradient(ellipse at 20% 50%, #1a0a2e 0%, #07090f 60%);
}

.glass-panel {
  position: relative;
  z-index: 10;
  backdrop-filter: blur(12px) saturate(180%);
  -webkit-backdrop-filter: blur(12px) saturate(180%);
  /* Must NOT have will-change: transform — that creates new stacking context
     and breaks backdrop-filter in some browsers */
}
```

#### Performance: `will-change` Caveat
`will-change: transform` creates a new stacking context, which **breaks backdrop-filter** in Firefox and causes visual artifacts in Chrome. Avoid it on glass elements. Use `transform: translateZ(0)` only if you must, and only for GPU compositing, not on the blur layer itself.

```css
/* BREAKS backdrop-filter: */
.broken { will-change: transform; backdrop-filter: blur(12px); }

/* SAFE for GPU hints elsewhere: */
.background-scene { will-change: transform; } /* on the background, not the glass */
.glass-panel { backdrop-filter: blur(12px); } /* no will-change here */
```

#### Blur Amount Reference (What Each Value Looks Like)
- `blur(2–4px)` — frosted window pane, text behind still readable
- `blur(8–12px)` — macOS menu bar, content shapes visible, text unreadable
- `blur(16–20px)` — macOS Spotlight / window chrome, fully opaque feel
- `blur(30px+)` — iOS Control Center, almost solid, very expensive GPU
- **Recommendation for gmux**: 12px for cards, 16px for HUD, 20px for titlebar

#### Full Design Token Set

```css
:root {
  /* Glass layers */
  --glass-bg-dark:    rgba(13, 17, 23, 0.72);
  --glass-bg-mid:     rgba(22, 27, 34, 0.65);
  --glass-bg-light:   rgba(33, 38, 45, 0.55);

  --glass-blur-sm:    blur(8px) saturate(160%);
  --glass-blur-md:    blur(12px) saturate(180%);
  --glass-blur-lg:    blur(20px) saturate(160%) brightness(1.03);

  --glass-border:     1px solid rgba(255, 255, 255, 0.08);
  --glass-border-top: 1px solid rgba(255, 255, 255, 0.14);

  --glass-shadow-sm:
    0 1px 2px rgba(0,0,0,0.3),
    0 4px 8px rgba(0,0,0,0.2);
  --glass-shadow-md:
    0 0 0 1px rgba(255,255,255,0.04) inset,
    0 4px 6px rgba(0,0,0,0.3),
    0 10px 20px rgba(0,0,0,0.2);
  --glass-shadow-lg:
    0 0 0 1px rgba(255,255,255,0.05) inset,
    0 4px 6px rgba(0,0,0,0.4),
    0 12px 24px rgba(0,0,0,0.3),
    0 24px 48px rgba(0,0,0,0.2);
}
```

---

## 2. Terminal Multiplexer UIs — Design Analysis

### Warp Terminal
**Key design decisions:**
- **Block-based output** — each command is a visual "block" with clear start/end boundaries. This is revolutionary for navigability. The block has its own copy, search, and share affordance.
- **Two-panel layout** — left sidebar shows command history/favourites; main area is the terminal. Navigation is spatial, not scroll-based.
- **Input at the bottom always** — never scrolls away. This prevents the "where am I typing" problem in tmux.
- **Status bar with git/env info** — bottom strip shows branch, time, exit code. Persistent context.
- **Font**: custom `Hack` variant at 13–14px, 1.4 line height. Not tight.
- **Colour**: Deep navy (`#1a1b26`) background, not pure black. Reduces eye strain.

**What makes Warp premium**: Clear separation between *navigation* (block selection) and *content* (terminal output). Every block has a visual boundary. You always know where you are.

### Zellij
**Key design decisions:**
- **Status bar strips at top and bottom** — top shows pane info + mode, bottom shows keybinding hints. Never hidden.
- **Pane borders with titles** — each pane has a 1-cell Unicode border (`─┬─`) with the pane name/command centered in it. This is the key spatial orientation tool.
- **Mode-aware colouring** — the status bar changes colour based on mode (Normal=blue, Pane=green, Tab=yellow, Scroll=orange). You always know what keys do.
- **Tab bar as first-class UI** — tabs are displayed inline in the pane border area, not a separate bar. Very compact.
- **Floating pane system** — panes can float over others. This is the key innovation over tmux.

**What makes Zellij work for dense layouts**: The combination of always-visible key hints + colour-coded mode + named pane borders means you never have to memorize anything. The UI teaches itself.

### tmux + Powerline
**Key design decisions:**
- The Powerline status bar uses **Powerline glyphs** (U+E0B0 ``) to create connected "arrow" segments. This creates depth through overlap/flow.
- Segment anatomy: `[left-filler] [icon + content] [right-filler]` — each segment is a foreground-background pair
- **Colour coding by context**: window index (white), active window (accent colour), session name (muted), time (right-aligned)
- **Window name truncation**: always show at least the process name (e.g. `nvim`, `zsh`, `cargo`), max 20 chars

**CSS equivalent of Powerline segments:**
```css
/* The "arrow" connector pattern */
.segment {
  display: flex;
  align-items: center;
  height: 24px;
  background: var(--segment-bg);
  color: var(--segment-fg);
  padding: 0 12px 0 8px;
  clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 50%, calc(100% - 8px) 100%, 0 100%);
  margin-right: -1px; /* overlap for seamless join */
}
.segment-active {
  background: #6c5ce7; /* your accent */
  color: white;
}
```

### iTerm2 Split Panes
**Key design decisions:**
- **Dimming inactive panes** — non-focused panes are drawn at ~70% brightness. This is huge for focus. The eye naturally goes to the brightest pane.
- **Minimal split handles** — the split divider is 1px, no visual affordance until hover. On hover it shows a drag handle.
- **Per-pane titles in the frame** — title bar shows the running command. When you zoom a pane, it gets the full title bar.
- **Broadcast input** — visual indicator (lightning bolt icon) when keystrokes go to all panes.

**The Dimming Pattern (CSS)**:
```css
.pane { transition: opacity 150ms ease; }
.pane:not(.active) {
  opacity: 0.65;
  filter: brightness(0.75) saturate(0.8);
}
.pane.active {
  opacity: 1;
  filter: none;
  box-shadow: 0 0 0 1px var(--accent), 0 0 12px rgba(108, 92, 231, 0.3);
}
```

### Key Design Principles for Pane Management UIs

1. **Active pane must be visually unmistakable** — bright border, undimmed, or glow
2. **Pane borders are navigation UI** — they need hit targets (drag to resize), labels, and close/split affordances
3. **Always show the running command** — "bash" is useless; "nvim src/main.rs" is actionable
4. **Status bars earn their pixels** — every character in the status bar should carry information density. No decoration.
5. **Split handles: invisible until needed** — hover reveal is the right UX. Don't clutter the display.
6. **Tab bars: show count + active indicator** — "3/8 agents waiting" is more useful than just names

### CSS for Pane Dividers (gmux-style)
```css
/* Horizontal divider */
.pane-divider-h {
  height: 1px;
  background: var(--border); /* #21262d */
  cursor: row-resize;
  position: relative;
  transition: background 150ms;
}
.pane-divider-h:hover {
  background: var(--accent);
  height: 2px;
}
.pane-divider-h::after {
  /* Invisible thick hit area */
  content: '';
  position: absolute;
  inset: -4px 0;
  cursor: row-resize;
}

/* Pane title bar */
.pane-header {
  height: 28px;
  display: flex;
  align-items: center;
  padding: 0 10px;
  gap: 8px;
  background: var(--surface); /* #0d1117 */
  border-bottom: 1px solid var(--border);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.02em;
  color: var(--muted);
  user-select: none;
}
.pane-header .state-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
  /* colour set by JS based on agent state */
}
.pane-header .pane-title {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.pane.active .pane-header {
  color: var(--text);
  border-bottom-color: var(--accent);
}
```

---

## 3. Tauri v2 macOS Support

### Native Vibrancy (The Real Deal)
Tauri v2 **does support native macOS vibrancy** through the `setVibrancy` API. This hits `NSVisualEffectView` directly — you get the actual OS blur-behind-window effect.

```rust
// In src-tauri/src/lib.rs
use tauri::Manager;

tauri::Builder::default()
  .setup(|app| {
    let window = app.get_webview_window("main").unwrap();
    
    // Apply native vibrancy — options:
    // "under-window" = full window vibrancy (like Terminal.app)
    // "sidebar" = sidebar vibrancy (like Finder)
    // "fullscreen-ui" = full-screen chrome
    // "hud" = HUD vibrancy (slightly lighter)
    window.set_effects(tauri::window::WindowEffectsConfig {
      effects: vec![tauri::window::WindowEffect::UnderWindow],
      state: None,
      radius: None,
      color: None,
    })?;
    
    Ok(())
  })
```

```json
// tauri.conf.json — window section
{
  "tauri": {
    "windows": [{
      "transparent": true,
      "decorations": false,
      "titleBarStyle": "Transparent",
      "hiddenTitle": true,
      "effects": {
        "effects": ["underWindow"],
        "state": "active"
      }
    }]
  }
}
```

### Transparent Titlebar with macOS Traffic Lights
The killer Tauri v2 pattern for macOS is **transparent titlebar + native traffic lights**:

```rust
// Tauri v2 Rust side
let win_builder = WebviewWindowBuilder::new(app, "main", WebviewUrl::default())
  .title_bar_style(TitleBarStyle::Transparent)  // Glass titlebar
  .hidden_title(true)                             // No title text
  .inner_size(1400.0, 900.0)
  .transparent(true);
```

```css
/* CSS: push content below the traffic lights */
body {
  padding-top: 28px; /* macOS titlebar height = 28px (non-retina) */
}

/* The draggable titlebar region */
.titlebar-drag-region {
  -webkit-app-region: drag;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 28px;
  z-index: 1000;
}

/* Buttons in the drag region must opt OUT of dragging */
.titlebar-drag-region button,
.titlebar-drag-region a {
  -webkit-app-region: no-drag;
}
```

### Webcam Access in Tauri
Tauri uses the system WebView (WKWebView on macOS). WebRTC camera access **works** but requires:

1. **Privacy permission in `tauri.conf.json`**:
```json
{
  "tauri": {
    "bundle": {
      "macOS": {
        "usageDescription": {
          "NSCameraUsageDescription": "gmux uses your camera for hand gesture recognition"
        }
      }
    }
  }
}
```

2. **The permission popup will appear** on first run — standard macOS camera permission dialog
3. **No extra code** — `navigator.mediaDevices.getUserMedia({ video: true })` works as-is in the webview
4. **v4l2loopback** (Linux) — you've already set this up; Tauri will see the virtual camera as a normal device

### Tauri v2 Caveats on macOS
- **`backdrop-filter` in CSS works** through WKWebView — the webkit prefix is handled automatically
- **Vibrancy + `transparent: true`** must be used together; transparent windows are required for the blur to show through
- **Window shadow**: set `hasShadow: true` in config or `window.set_shadow(true)` — without this, transparent windows look flat
- **Resize handles**: transparent windows lose native resize grippers. Add `data-tauri-drag-region` to your custom handle areas and handle resize manually or use `resizable: true` in config
- **Focus state**: `NSVisualEffectView` has active/inactive states — the vibrancy dimly blurs when window loses focus. This is native behaviour, looks correct.

---

## 4. Electron macOS Support

### Vibrancy API
Electron has `win.setVibrancy(type)` — same underlying `NSVisualEffectView`:

```javascript
// main.js
const { BrowserWindow } = require('electron');

const win = new BrowserWindow({
  width: 1400,
  height: 900,
  transparent: true,
  titleBarStyle: 'hidden',         // Native traffic lights, no title
  // OR: 'hiddenInset' — traffic lights inset into content area
  trafficLightPosition: { x: 16, y: 16 },  // Custom position
  vibrancy: 'under-window',        // Native macOS blur
  visualEffectState: 'active',     // Always show active vibrancy (even unfocused)
  backgroundColor: '#00000000',    // Fully transparent bg (needed!)
  frame: false,
  hasShadow: true,
});
```

**Vibrancy type options for Electron macOS:**
| Type | Use case |
|---|---|
| `titlebar` | Titlebar area only |
| `selection` | Selected text highlight style |
| `menu` | Drop-down menus |
| `popover` | Popover panels |
| `sidebar` | Sidebar panels |
| `under-window` | **Entire window** — most dramatic |
| `under-page` | Document content area |
| `hud` | HUD overlay (slightly lighter) |
| `fullscreen-ui` | Fullscreen toolbar |
| `tooltip` | Tooltips |
| `content` | Content regions |
| `header` | Headers |
| `sheet` | Modal sheets |

### Windows Equivalent (Electron)
On Windows 11, use `setBackgroundMaterial`:
```javascript
win.setBackgroundMaterial('mica');    // Long-lived window (like Settings app)
// OR
win.setBackgroundMaterial('acrylic'); // Transient window (like Start menu)
```

### Electron CSS Transparency
```javascript
// For CSS backdrop-filter to show OS desktop through the window:
const win = new BrowserWindow({
  transparent: true,
  backgroundColor: '#00000000',
  hasShadow: true,
  // webPreferences: { backgroundThrottling: false } // keep rendering when hidden
});
```

Then in CSS — the `background: transparent` lets the OS vibrancy show through:
```css
html, body {
  background: transparent !important;
}

.app-shell {
  background: transparent; /* Shows native vibrancy */
}

.glass-card {
  /* CSS glass ON TOP of native vibrancy — layered effect */
  background: rgba(13, 17, 23, 0.40); /* Lower opacity than usual — native blur underneath */
  backdrop-filter: saturate(180%); /* Don't add blur — native already blurs */
}
```

### Electron Webcam Access
Electron has **full Chromium webcam access** — works out of the box, no special config needed. On macOS, it uses the system permission dialog automatically. For production apps:

```javascript
// main.js — grant media permissions to the app itself
app.on('ready', () => {
  // macOS: request camera permission before any webContents try to use it
  systemPreferences.askForMediaAccess('camera').then((granted) => {
    if (granted) createWindow();
  });
});
```

### Electron vs Tauri for gmux

| Feature | Electron | Tauri v2 |
|---|---|---|
| vibrancy/blur | ✅ Full API | ✅ Full API |
| CSS backdrop-filter | ✅ Chrome | ✅ WKWebView (Safari engine) |
| Webcam | ✅ No config | ✅ Needs plist entry |
| Bundle size | ~150MB | ~5MB |
| MediaPipe (WASM) | ✅ Full Chrome WASM | ⚠️ Safari WebAssembly — generally works but check simd support |
| Native macOS menus | ✅ | ✅ |
| Traffic lights position | ✅ `trafficLightPosition` | ✅ `setWindowButtonPosition` |
| PTY / terminal | ⚠️ Needs `node-pty` | ✅ Native Rust PTY |

**Recommendation**: For the demos, use pure HTML. For the app, Tauri gives better PTY/terminal integration (your existing stack). Electron is better if you hit Safari WebView compatibility issues with MediaPipe WASM.

---

## 5. Dashboard UI Patterns — Density vs Calm

### Linear's Approach
Linear's key technique: **one type of information per visual level**:
- Level 1 (sidebar): navigation — project/team hierarchy
- Level 2 (list): item enumeration — issues, sorted by priority
- Level 3 (detail): full content — description, comments, attachments

Each level has different information density. You never see level 3 content at level 1 scale.

**CSS technique — optical sizing by level:**
```css
/* Level 1: sidebar items */
.nav-item { font-size: 13px; line-height: 20px; padding: 4px 8px; }

/* Level 2: list items (dense) */
.list-item { font-size: 13px; line-height: 16px; padding: 6px 12px; }

/* Level 3: detail text */
.detail-text { font-size: 14px; line-height: 22px; }

/* Key: consistent vertical rhythm */
:root { --row-height: 32px; }
.list-item, .nav-item { height: var(--row-height); }
```

**Status indicators** — Linear uses small coloured dots + text in uppercase micro-labels:
```css
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  padding: 2px 7px;
  border-radius: 4px;
  background: rgba(var(--status-rgb), 0.12);
  color: rgb(var(--status-rgb));
}
```

### Vercel Dashboard Pattern
Vercel's calm density comes from:
1. **Generous vertical padding on rows** (16px top+bottom) — even with small text
2. **Horizontal information layout** — key info left, meta info right (like email clients)
3. **Muted secondary text** — timestamps, IDs in `#6e7681`; primary content in `#e6edf3`
4. **Borderless tables with alternating hover** — rows have no borders; hover shows `rgba(255,255,255,0.04)` background

```css
/* The Vercel table pattern */
.data-row {
  display: grid;
  grid-template-columns: 1fr auto auto;  /* name | status | time */
  align-items: center;
  padding: 12px 16px;
  min-height: 52px;
  border-bottom: 1px solid rgba(255,255,255,0.06);
  transition: background 100ms;
}
.data-row:hover { background: rgba(255, 255, 255, 0.03); }

.row-primary   { font-size: 14px; font-weight: 500; color: #e6edf3; }
.row-secondary { font-size: 12px; color: #6e7681; margin-top: 2px; }
.row-meta      { font-size: 12px; color: #6e7681; text-align: right; }
```

### Raycast's Pattern
Raycast is the gold standard for **dense + calm** search/command UI:
1. **Keyboard-first with visual echoes** — every keyboard action has a visible ripple
2. **Monochrome + single accent** — everything is grey, ONE colour for active/selected
3. **Icon + text alignment** — 16px icons, 13px text, exactly aligned to a 4px grid
4. **Subtle separator lines** — `rgba(255,255,255,0.06)` — barely visible, but structural

```css
/* Raycast-style list item */
.command-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 12px;
  height: 44px;
  border-radius: 8px;
  cursor: default;
}
.command-item:hover,
.command-item.selected {
  background: rgba(108, 92, 231, 0.15); /* accent at 15% */
}
.command-item.selected {
  background: rgba(108, 92, 231, 0.20);
}
.command-item .icon {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255,255,255,0.08);
  font-size: 14px;
  flex-shrink: 0;
}
.command-item .label {
  font-size: 13px;
  font-weight: 500;
  color: #e6edf3;
  flex: 1;
}
.command-item .shortcut {
  font-size: 11px;
  color: #6e7681;
  font-family: 'SF Mono', monospace;
}
```

### What Makes Dense Feel Calm (The Principles)

1. **Hierarchy through weight, not size** — use `font-weight: 400 vs 600` more than font-size variation
2. **Status via colour, not text** — a coloured dot says "working" faster than the word "working"
3. **Grid lock** — everything aligns to an 8px or 4px grid. Misalignment = visual noise
4. **Neutral background, accented foreground** — the background should recede; only action items get colour
5. **Consistent padding within a level** — rows in the same level all have identical height
6. **Max 3 text styles per screen** — primary (14px/500), secondary (12px/400), micro (11px/600 caps)
7. **Group with space, separate with lines** — prefer whitespace grouping; add 1px dividers only as last resort
8. **Motion is reserved for state changes** — nothing moves unless something *changed*

### gmux-Specific Application

```css
/* Agent card — information hierarchy */
.agent-card {
  background: rgba(22, 27, 34, 0.80);
  backdrop-filter: blur(12px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 10px;
  padding: 12px;
  display: grid;
  grid-template-rows: 28px 1fr 28px;
  gap: 8px;
}

/* Top row: status + name + actions */
.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 28px;
}
.state-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  animation: pulse-glow 2s ease infinite;  /* only for 'working' state */
}
.agent-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--text);
  flex: 1;
}
.agent-index {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.05em;
  color: var(--muted);
  font-family: 'SF Mono', monospace;
}

/* Middle: terminal output snippet */
.card-output {
  font-family: 'SF Mono', 'Menlo', monospace;
  font-size: 11px;
  line-height: 1.5;
  color: var(--muted);
  overflow: hidden;
  mask-image: linear-gradient(to top, transparent, black 30%);
}

/* Bottom: metrics */
.card-footer {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 11px;
  color: var(--muted);
  border-top: 1px solid rgba(255,255,255,0.05);
  padding-top: 8px;
}
.metric { display: flex; align-items: center; gap: 4px; }

/* State glow — this is what makes waiting visible at a glance */
.agent-card[data-state="waiting"]  { box-shadow: 0 0 0 1px rgba(239,68,68,0.3), 0 0 16px rgba(239,68,68,0.1); }
.agent-card[data-state="working"]  { box-shadow: 0 0 0 1px rgba(34,197,94,0.2), 0 0 12px rgba(34,197,94,0.08); }
.agent-card[data-state="permission"] { box-shadow: 0 0 0 1px rgba(249,115,22,0.4), 0 0 16px rgba(249,115,22,0.15); }
.agent-card[data-state="done"]     { box-shadow: 0 0 0 1px rgba(59,130,246,0.2); }
.agent-card[data-state="error"]    { box-shadow: 0 0 0 1px rgba(239,68,68,0.5), 0 0 20px rgba(239,68,68,0.2); }
```

---

## 6. Extended Canvas / Hand Tracking Edge Zones

### The Problem
MediaPipe HandLandmarker gives normalized coordinates `[0,1]` relative to the video stream resolution. When a hand moves to the edge of the camera frame, it disappears — the last known position is at the edge. This causes:
- Abrupt gesture end events when hand is at screen edge
- "Sticky" cursor behaviour
- Missed gesture completions (user finishes swipe off-screen)

### The Technique: Virtual Canvas Extension

The core idea: **track hands in a canvas that is *larger* than the video feed**, then map the extended coordinates to screen space. When hands exit the video boundary, you extrapolate from the last known trajectory.

#### Step 1: Oversized Detection Canvas

```javascript
// Config
const EXTENSION = 0.15; // 15% extension on all sides
// Virtual canvas: [−EXTENSION, 1+EXTENSION] in both axes
// Visible screen: [0, 1]

function extendedToScreen(normX, normY, canvasWidth, canvasHeight) {
  // Map from [−EXTENSION, 1+EXTENSION] to [0, canvasWidth/Height]
  const totalWidth  = 1 + EXTENSION * 2;
  const totalHeight = 1 + EXTENSION * 2;
  return {
    x: ((normX + EXTENSION) / totalWidth)  * canvasWidth,
    y: ((normY + EXTENSION) / totalHeight) * canvasHeight,
  };
}
```

#### Step 2: Edge Detection and Velocity Extrapolation

```javascript
class ExtendedTracker {
  constructor() {
    this.EXTENSION = 0.15;
    this.EXTRAPOLATION_FRAMES = 12;  // How many frames to keep extrapolating
    this.hands = {
      Left:  { history: [], extrapolating: false, extrapolateCount: 0 },
      Right: { history: [], extrapolating: false, extrapolateCount: 0 },
    };
  }

  update(mediapipeHandsData) {
    const detected = new Set();

    if (mediapipeHandsData?.multiHandLandmarks) {
      for (let i = 0; i < mediapipeHandsData.multiHandLandmarks.length; i++) {
        const lm = mediapipeHandsData.multiHandLandmarks[i];
        const label = mediapipeHandsData.multiHandedness[i].label === 'Left' ? 'Right' : 'Left';
        detected.add(label);

        const wrist = lm[0];
        const state = this.hands[label];

        state.extrapolating = false;
        state.extrapolateCount = 0;

        // Clamp to [-EXTENSION, 1+EXTENSION] virtual space
        const vx = Math.max(-this.EXTENSION, Math.min(1 + this.EXTENSION, wrist.x));
        const vy = Math.max(-this.EXTENSION, Math.min(1 + this.EXTENSION, wrist.y));

        state.history.push({ x: vx, y: vy, t: performance.now() });
        if (state.history.length > 16) state.history.shift();
      }
    }

    // Extrapolate for hands that just left the frame
    for (const [label, state] of Object.entries(this.hands)) {
      if (!detected.has(label) && state.history.length >= 4) {
        if (state.extrapolateCount < this.EXTRAPOLATION_FRAMES) {
          state.extrapolating = true;
          state.extrapolateCount++;

          // Velocity from last 4 frames
          const recent = state.history.slice(-4);
          const dt = (recent[3].t - recent[0].t) / 1000 || 0.016;
          const vx = (recent[3].x - recent[0].x) / dt;
          const vy = (recent[3].y - recent[0].y) / dt;

          // Apply velocity with decay
          const decay = 1 - (state.extrapolateCount / this.EXTRAPOLATION_FRAMES);
          const last = state.history[state.history.length - 1];
          const frameTime = 0.016; // ~60fps

          const predictedX = last.x + vx * frameTime * decay;
          const predictedY = last.y + vy * frameTime * decay;

          state.history.push({
            x: Math.max(-this.EXTENSION * 2, Math.min(1 + this.EXTENSION * 2, predictedX)),
            y: Math.max(-this.EXTENSION * 2, Math.min(1 + this.EXTENSION * 2, predictedY)),
            t: performance.now(),
            extrapolated: true,
          });
        } else {
          // Extrapolation exhausted — clear state
          state.history = [];
          state.extrapolating = false;
          state.extrapolateCount = 0;
        }
      }
    }

    return this.hands;
  }

  /** Get current position in screen coordinates */
  getScreenPosition(label, canvasWidth, canvasHeight) {
    const state = this.hands[label];
    if (!state.history.length) return null;
    const last = state.history[state.history.length - 1];

    return {
      x: ((last.x + this.EXTENSION) / (1 + this.EXTENSION * 2)) * canvasWidth,
      y: ((last.y + this.EXTENSION) / (1 + this.EXTENSION * 2)) * canvasHeight,
      extrapolated: last.extrapolated ?? false,
      offscreen: last.x < 0 || last.x > 1 || last.y < 0 || last.y > 1,
    };
  }
}
```

#### Step 3: Wider Camera Crop + Virtual Zone Rendering

The other technique: **make the webcam preview smaller than the detection canvas**, so the camera feeds into a larger virtual space:

```javascript
// In the MediaPipe setup:
// Capture at higher resolution, use only center crop for display
// but pass full frame to detection

async function setupCamera(videoElement) {
  const stream = await navigator.mediaDevices.getUserMedia({
    video: {
      width: { ideal: 1280 },   // Full width for detection
      height: { ideal: 720 },
      facingMode: 'user',
    }
  });
  videoElement.srcObject = stream;

  // The video element is positioned outside the visible frame
  // e.g., video is 1280px wide but the PiP window shows only 960px (75%)
  // This means hands 12.5% into each edge are still detected but not shown
  return new Promise(resolve => {
    videoElement.onloadedmetadata = () => {
      videoElement.play();
      resolve(videoElement);
    };
  });
}
```

```css
/* Camera container with edge extension */
.camera-container {
  position: relative;
  width: 320px;   /* Visible PiP size */
  height: 180px;
  overflow: hidden;
  border-radius: 12px;
}

.camera-video {
  /* Video is 15% wider/taller than the container on each side */
  position: absolute;
  width: calc(100% * (1 + 0.15 * 2)); /* = 130% */
  height: calc(100% * (1 + 0.15 * 2));
  left: -15%;
  top: -15%;
  object-fit: cover;
  transform: scaleX(-1); /* mirror */
}

/* The edge zone indicator — shows user the extended detection area */
.edge-indicator {
  position: absolute;
  inset: 0;
  border: 2px solid rgba(108, 92, 231, 0.3);
  border-radius: 12px;
  pointer-events: none;
  /* Gradient fade at edges to suggest detection continues */
  mask-image:
    linear-gradient(to right, transparent 2px, black 8px, black calc(100% - 8px), transparent calc(100% - 2px)),
    linear-gradient(to bottom, transparent 2px, black 8px, black calc(100% - 8px), transparent calc(100% - 2px));
  mask-composite: intersect;
}
```

#### Step 4: Smooth Fade-Out at Edges (Visual Polish)

When a hand leaves the frame, instead of abruptly disappearing, fade the skeleton rendering:

```javascript
// In gesture-renderer.js — modify drawHand to accept opacity
function drawHand(ctx, landmarks, handedness, alpha = 1.0) {
  ctx.globalAlpha = alpha;
  // ... draw skeleton ...
  ctx.globalAlpha = 1.0;
}

// In your render loop:
function getHandOpacity(label, tracker) {
  const state = tracker.hands[label];
  if (!state.history.length) return 0;

  const last = state.history[state.history.length - 1];

  if (!state.extrapolating && !last.extrapolated) {
    // Normal: calculate edge proximity fade
    const edgeDist = Math.min(last.x, 1 - last.x, last.y, 1 - last.y);
    const fadeStart = 0.05; // Start fading 5% from edge
    if (edgeDist < fadeStart) {
      return edgeDist / fadeStart; // 0 at edge, 1 at fadeStart distance
    }
    return 1.0;
  } else if (state.extrapolating) {
    // Extrapolating: fade out over the extrapolation window
    const t = state.extrapolateCount / tracker.EXTRAPOLATION_FRAMES;
    return Math.max(0, 1 - t * t); // quadratic fade
  }

  return 0;
}
```

#### Step 5: Integration with Your Existing gesture-engine.js

Your `GestureEngine` already uses normalized `[0,1]` coordinates. To integrate extended canvas:

```javascript
// Wrap gesture engine with extended tracker
class ExtendedGestureEngine extends GestureEngine {
  constructor(config = {}) {
    super(config);
    this.extendedTracker = new ExtendedTracker();
  }

  update(handsData) {
    // Update extended tracker first
    this.extendedTracker.update(handsData);
    // Then update gesture engine normally
    super.update(handsData);
  }

  // Override toLandmarkPosition to use extended coordinates when off-screen
  getExtendedPosition(handLabel, canvasWidth, canvasHeight) {
    return this.extendedTracker.getScreenPosition(handLabel, canvasWidth, canvasHeight);
  }
}
```

### The Edge Zone CSS for gmux's PiP Camera

```css
/* Floating camera PiP with extended detection zones */
.gesture-pip {
  position: fixed;
  bottom: 20px;
  right: 20px;
  width: 200px;
  height: 112px; /* 16:9 */
  border-radius: 12px;
  overflow: visible; /* important! Don't clip the edge zone indicators */
  z-index: 500;
}

/* The inner clip area */
.gesture-pip-inner {
  width: 100%;
  height: 100%;
  border-radius: 12px;
  overflow: hidden;
  position: relative;
  backdrop-filter: blur(4px);
  border: 1px solid rgba(255,255,255,0.1);
}

/* Extended zone indicator — a subtle glow ring outside the frame */
.gesture-pip::after {
  content: '';
  position: absolute;
  inset: -12px; /* 12px extension on all sides ≈ 6% of 200px */
  border-radius: 16px;
  border: 1px dashed rgba(108, 92, 231, 0.25);
  pointer-events: none;
  /* This shows the user that detection continues into this ring */
}

/* When hand is near the edge, pulse the border */
.gesture-pip.edge-active::after {
  border-color: rgba(108, 92, 231, 0.6);
  animation: edge-pulse 0.5s ease;
}

@keyframes edge-pulse {
  0%   { opacity: 0.3; transform: scale(0.98); }
  50%  { opacity: 1.0; transform: scale(1.02); }
  100% { opacity: 0.6; transform: scale(1.00); }
}
```

---

## Summary: Design Tokens for gmux

```css
:root {
  /* ── Colour System ── */
  --bg:         #07090f;
  --surface:    #0d1117;
  --card:       #161b22;
  --border:     #21262d;
  --border-glow: rgba(255,255,255,0.08);
  --muted:      #6e7681;
  --text:       #e6edf3;

  /* Accent */
  --accent:     #6c5ce7;
  --accent-rgb: 108, 92, 231;
  --cyan:       #00d2ff;
  --orange:     #ff6b35;

  /* Agent States */
  --waiting:    #ef4444;
  --working:    #22c55e;
  --permission: #f97316;
  --done:       #3b82f6;
  --error:      #ef4444;
  --idle:       #4b5563;

  /* ── Glass System ── */
  --glass-bg:        rgba(13, 17, 23, 0.72);
  --glass-blur:      blur(12px) saturate(180%);
  --glass-blur-sm:   blur(8px) saturate(160%);
  --glass-blur-lg:   blur(20px) saturate(160%) brightness(1.03);
  --glass-border:    1px solid rgba(255, 255, 255, 0.08);
  --glass-shadow:
    0 0 0 1px rgba(255,255,255,0.04) inset,
    0 4px 12px rgba(0,0,0,0.4),
    0 12px 32px rgba(0,0,0,0.3);

  /* ── Typography ── */
  --font-ui:    'SF Pro Text', 'Inter', system-ui, sans-serif;
  --font-mono:  'SF Mono', 'Menlo', 'Fira Code', monospace;

  --text-xs:    11px;
  --text-sm:    12px;
  --text-base:  13px;
  --text-md:    14px;
  --text-lg:    16px;

  /* ── Layout ── */
  --row-height:     32px;
  --card-radius:    10px;
  --panel-radius:   12px;
  --gap-sm:         8px;
  --gap-md:         12px;
  --gap-lg:         20px;

  /* ── Motion ── */
  --transition-fast: 100ms ease;
  --transition-mid:  200ms ease;
  --transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);
}
```

---

## Quick Reference: Copy-Paste Snippets

### macOS vibrancy HTML app (Tauri v2 Rust)
```rust
let win = WebviewWindowBuilder::new(app, "main", WebviewUrl::default())
  .title_bar_style(TitleBarStyle::Transparent)
  .hidden_title(true)
  .transparent(true)
  .inner_size(1400.0, 900.0)
  .decorations(false)
  .build()?;
```

### Electron vibrancy (main.js)
```js
new BrowserWindow({
  transparent: true,
  backgroundColor: '#00000000',
  vibrancy: 'under-window',
  visualEffectState: 'active',
  titleBarStyle: 'hiddenInset',
  trafficLightPosition: { x: 16, y: 16 },
  hasShadow: true,
})
```

### Best glass card for dark dashboard
```css
.card {
  background: rgba(13, 17, 23, 0.72);
  backdrop-filter: blur(12px) saturate(180%);
  -webkit-backdrop-filter: blur(12px) saturate(180%);
  border: 1px solid rgba(255,255,255,0.08);
  border-top: 1px solid rgba(255,255,255,0.14);
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.04) inset,
    0 4px 12px rgba(0,0,0,0.4),
    0 12px 32px rgba(0,0,0,0.25);
  border-radius: 10px;
}
```

### Working agent state glow animation
```css
@keyframes working-pulse {
  0%, 100% { box-shadow: 0 0 0 1px rgba(34,197,94,0.2); }
  50%       { box-shadow: 0 0 0 1px rgba(34,197,94,0.4), 0 0 16px rgba(34,197,94,0.15); }
}
.agent-card[data-state="working"] {
  animation: working-pulse 2s ease-in-out infinite;
}
```

### Pane dimming (active/inactive)
```css
.pane { transition: filter 150ms ease, opacity 150ms ease; }
.pane:not(.focused) { filter: brightness(0.7) saturate(0.75); opacity: 0.8; }
.pane.focused { filter: none; opacity: 1; }
```
