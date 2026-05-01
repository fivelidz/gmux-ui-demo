# Graph Report - RESEARCH_UI_DESIGN.md  (2026-04-24)

## Corpus Check
- 1 files · ~5,193 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 54 nodes · 75 edges · 10 communities detected
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.76)
- Token cost: 5,200 input · 3,400 output

## Community Hubs (Navigation)
- [[_COMMUNITY_CSS Glass & Backdrop-Filter|CSS Glass & Backdrop-Filter]]
- [[_COMMUNITY_Extended Canvas Hand Tracking|Extended Canvas Hand Tracking]]
- [[_COMMUNITY_Dashboard Density Patterns|Dashboard Density Patterns]]
- [[_COMMUNITY_gmux Design System|gmux Design System]]
- [[_COMMUNITY_Terminal Multiplexer UIs|Terminal Multiplexer UIs]]
- [[_COMMUNITY_Tauri v2 macOS Platform|Tauri v2 macOS Platform]]
- [[_COMMUNITY_Electron macOS Platform|Electron macOS Platform]]
- [[_COMMUNITY_Webcam + MediaPipe Access|Webcam + MediaPipe Access]]
- [[_COMMUNITY_tmux  Powerline Segments|tmux / Powerline Segments]]
- [[_COMMUNITY_Transparent Titlebar Chrome|Transparent Titlebar Chrome]]

## God Nodes (most connected - your core abstractions)
1. `CSS Glassmorphism — Premium vs Cheap` - 11 edges
2. `gmux Project — Gesture-First AI Agent Dashboard Terminal Multiplexer` - 9 edges
3. `Tauri v2 Native Vibrancy — setVibrancy API hits NSVisualEffectView directly` - 7 edges
4. `Electron vibrancy API — win.setVibrancy(type), NSVisualEffectView underneath` - 6 edges
5. `gmux Agent Card CSS — glass panel, grid-template-rows: 28px 1fr 28px, state glow box-shadow` - 6 edges
6. `gmux Full Design Token System — colours, glass, typography, layout, motion in :root` - 6 edges
7. `Pane Management Design Principles — 6 Rules for Terminal Multiplexer UIs` - 5 edges
8. `ExtendedTracker Class — Velocity extrapolation for 12 frames, quadratic fade-out, history buffer of 16` - 5 edges
9. `macOS Native Vibrancy (NSVisualEffectView)` - 4 edges
10. `Premium Glass CSS Formula — backdrop-filter: blur(12px) saturate(180%) brightness(1.05)` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Saturation Trick — saturate(180%) is the magic ingredient` --semantically_similar_to--> `iTerm2 Pane Dimming — Inactive Panes at 70% Brightness (filter: brightness(0.75) saturate(0.8))`  [INFERRED] [semantically similar]
  RESEARCH_UI_DESIGN.md → RESEARCH_UI_DESIGN.md  _Bridges community 0 → community 4_
- `Tauri v2 macOS Caveats — transparent+vibrancy together, hasShadow, resize handles, focus state` --conceptually_related_to--> `will-change: transform BREAKS backdrop-filter — creates new stacking context`  [INFERRED]
  RESEARCH_UI_DESIGN.md → RESEARCH_UI_DESIGN.md  _Bridges community 0 → community 5_
- `Raycast Dense+Calm Pattern — Monochrome + Single Accent, 4px Grid, Keyboard-First` --semantically_similar_to--> `Warp Terminal — Block-Based Output, Input Always at Bottom`  [INFERRED] [semantically similar]
  RESEARCH_UI_DESIGN.md → RESEARCH_UI_DESIGN.md  _Bridges community 4 → community 2_
- `Pane Management Design Principles — 6 Rules for Terminal Multiplexer UIs` --rationale_for--> `gmux Agent Card CSS — glass panel, grid-template-rows: 28px 1fr 28px, state glow box-shadow`  [INFERRED]
  RESEARCH_UI_DESIGN.md → RESEARCH_UI_DESIGN.md  _Bridges community 4 → community 3_
- `gmux Project — Gesture-First AI Agent Dashboard Terminal Multiplexer` --references--> `Warp Terminal — Block-Based Output, Input Always at Bottom`  [EXTRACTED]
  RESEARCH_UI_DESIGN.md → RESEARCH_UI_DESIGN.md  _Bridges community 5 → community 4_

## Hyperedges (group relationships)
- **CSS Glass System — premium formula, saturation trick, border trick, will-change caveat, backdrop requirement, blur reference, design tokens** — research_ui_design_premium_glass_formula, research_ui_design_saturation_trick, research_ui_design_border_trick, research_ui_design_will_change_caveat, research_ui_design_backdrop_filter_requirement, research_ui_design_blur_amount_reference, research_ui_design_glass_design_tokens [EXTRACTED 1.00]
- **Extended Canvas Hand Tracking System — virtual canvas extension, ExtendedTracker, extendedToScreen, wider crop, opacity fade, ExtendedGestureEngine** — research_ui_design_virtual_canvas_extension, research_ui_design_extended_tracker_class, research_ui_design_extended_to_screen_fn, research_ui_design_wider_camera_crop, research_ui_design_hand_opacity_fade, research_ui_design_extended_gesture_engine [EXTRACTED 1.00]
- **Platform Vibrancy Implementations — Tauri v2, Electron, macOS NSVisualEffectView** — research_ui_design_macos_vibrancy_native, research_ui_design_tauri_v2_vibrancy, research_ui_design_electron_vibrancy, research_ui_design_electron_vs_tauri [EXTRACTED 0.95]

## Communities

### Community 0 - "CSS Glass & Backdrop-Filter"
Cohesion: 0.31
Nodes (9): backdrop-filter Requirement — background scene must be z-index lower than glass panel, Blur Amount Reference — 2-4px frosted, 8-12px menu bar, 16-20px spotlight, 30px+ iOS, Glass Border Trick — 1px light edge catch simulates light reflecting off glass, CSS Glassmorphism — Premium vs Cheap, Glass Design Token Set — CSS custom properties for full glass system, gmux Dark Theme rgba Values — titlebar, agent cards, HUD, tooltip, modal backdrop, Premium Glass CSS Formula — backdrop-filter: blur(12px) saturate(180%) brightness(1.05), Saturation Trick — saturate(180%) is the magic ingredient (+1 more)

### Community 1 - "Extended Canvas Hand Tracking"
Cohesion: 0.32
Nodes (8): Edge Zone Indicator CSS — mask-image gradient fade at edges, dashed border outside PiP container, ExtendedGestureEngine — Wraps GestureEngine with ExtendedTracker, getExtendedPosition() method, extendedToScreen() Function — Maps [-EXTENSION, 1+EXTENSION] to [0, canvasWidth/Height], ExtendedTracker Class — Velocity extrapolation for 12 frames, quadratic fade-out, history buffer of 16, Hand Opacity Edge Fade — Proximity fade 5% from edge, quadratic fade during extrapolation, PiP Camera CSS — gesture-pip with ::after dashed ring 12px outside, edge-active pulse animation, Virtual Canvas Extension Technique — Track hands in canvas larger than video, EXTENSION=0.15 (15%), Wider Camera Crop Technique — Video 130% of container, overflow hidden, center crop displayed

### Community 2 - "Dashboard Density Patterns"
Cohesion: 0.33
Nodes (7): Dense-Feel-Calm Principles — 8 Rules: hierarchy via weight, status via colour, grid lock, max 3 text styles, Linear Dashboard — One Type of Information Per Visual Level, Optical Sizing, Raycast Command Item CSS — height 44px, border-radius 8px, selected at accent 20% opacity, Raycast Dense+Calm Pattern — Monochrome + Single Accent, 4px Grid, Keyboard-First, Status Badge CSS — 11px, weight 600, letter-spacing 0.04em, uppercase, rgba background at 12%, Vercel Data Row CSS — grid 1fr auto auto, min-height 52px, hover rgba(255,255,255,0.03), Vercel Dashboard Pattern — Generous Vertical Padding, Horizontal Info Layout, Muted Secondary Text

### Community 3 - "gmux Design System"
Cohesion: 0.33
Nodes (7): gmux Agent Card CSS — glass panel, grid-template-rows: 28px 1fr 28px, state glow box-shadow, gmux Agent State Colours — waiting:#ef4444, working:#22c55e, permission:#f97316, done:#3b82f6, error:#ef4444, gmux Colour System — bg:#07090f, surface:#0d1117, card:#161b22, border:#21262d, accent:#6c5ce7, gmux Full Design Token System — colours, glass, typography, layout, motion in :root, gmux Motion Tokens — fast:100ms ease, mid:200ms ease, slow:300ms cubic-bezier(0.4,0,0.2,1), gmux Typography — SF Pro Text/Inter UI, SF Mono/Menlo/Fira Code, sizes 11-16px, Working State Pulse Animation — box-shadow glow cycles rgba(34,197,94,0.2) to 0.4 over 2s

### Community 4 - "Terminal Multiplexer UIs"
Cohesion: 0.33
Nodes (6): iTerm2 Pane Dimming — Inactive Panes at 70% Brightness (filter: brightness(0.75) saturate(0.8)), Pane Dimming CSS — inactive: brightness(0.7) saturate(0.75) opacity(0.8), active: filter:none, gmux Pane Divider CSS — 1px border, hover expand to 2px, invisible thick hit area, Pane Management Design Principles — 6 Rules for Terminal Multiplexer UIs, Warp Terminal — Block-Based Output, Input Always at Bottom, Zellij — Mode-Aware Colouring, Pane Borders with Titles, Floating Panes

### Community 5 - "Tauri v2 macOS Platform"
Cohesion: 0.47
Nodes (6): Electron vs Tauri Comparison for gmux — vibrancy, CSS, webcam, bundle size, MediaPipe WASM, PTY, gmux Project — Gesture-First AI Agent Dashboard Terminal Multiplexer, macOS Native Vibrancy (NSVisualEffectView), Tauri v2 macOS Caveats — transparent+vibrancy together, hasShadow, resize handles, focus state, Tauri v2 Native Vibrancy — setVibrancy API hits NSVisualEffectView directly, Tauri Window Config JSON — transparent:true, titleBarStyle:Transparent, hiddenTitle:true, effects:underWindow

### Community 6 - "Electron macOS Platform"
Cohesion: 0.5
Nodes (4): Electron CSS Transparency — transparent:true, backgroundColor:'#00000000', CSS glass ON TOP of native vibrancy, Electron vibrancy API — win.setVibrancy(type), NSVisualEffectView underneath, Electron Vibrancy Types — titlebar, sidebar, under-window, hud, popover, tooltip, content, sheet, etc, Electron Windows 11 — setBackgroundMaterial('mica') for long-lived, 'acrylic' for transient

### Community 7 - "Webcam + MediaPipe Access"
Cohesion: 1.0
Nodes (3): Electron Webcam — Full Chromium access, systemPreferences.askForMediaAccess('camera') on macOS, Hand Tracking Edge Problem — MediaPipe coords [0,1], hand disappears at frame edge, abrupt gesture end, Tauri Webcam Access — WKWebView WebRTC works, needs NSCameraUsageDescription plist entry

### Community 8 - "tmux / Powerline Segments"
Cohesion: 1.0
Nodes (2): Powerline Segment CSS — clip-path polygon arrow connector, margin-right: -1px overlap, tmux + Powerline — Arrow Segment Anatomy, Colour Coding by Context

### Community 9 - "Transparent Titlebar Chrome"
Cohesion: 1.0
Nodes (2): Tauri Drag Region CSS — -webkit-app-region: drag, height: 28px, buttons use no-drag, Tauri v2 Transparent Titlebar — TitleBarStyle::Transparent + hidden_title(true)

## Knowledge Gaps
- **18 isolated node(s):** `Glass Border Trick — 1px light edge catch simulates light reflecting off glass`, `Blur Amount Reference — 2-4px frosted, 8-12px menu bar, 16-20px spotlight, 30px+ iOS`, `gmux Dark Theme rgba Values — titlebar, agent cards, HUD, tooltip, modal backdrop`, `Zellij — Mode-Aware Colouring, Pane Borders with Titles, Floating Panes`, `tmux + Powerline — Arrow Segment Anatomy, Colour Coding by Context` (+13 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `tmux / Powerline Segments`** (2 nodes): `Powerline Segment CSS — clip-path polygon arrow connector, margin-right: -1px overlap`, `tmux + Powerline — Arrow Segment Anatomy, Colour Coding by Context`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Transparent Titlebar Chrome`** (2 nodes): `Tauri Drag Region CSS — -webkit-app-region: drag, height: 28px, buttons use no-drag`, `Tauri v2 Transparent Titlebar — TitleBarStyle::Transparent + hidden_title(true)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `gmux Project — Gesture-First AI Agent Dashboard Terminal Multiplexer` connect `Tauri v2 macOS Platform` to `CSS Glass & Backdrop-Filter`, `Extended Canvas Hand Tracking`, `gmux Design System`, `Terminal Multiplexer UIs`, `Webcam + MediaPipe Access`?**
  _High betweenness centrality (0.521) - this node is a cross-community bridge._
- **Why does `gmux Agent Card CSS — glass panel, grid-template-rows: 28px 1fr 28px, state glow box-shadow` connect `gmux Design System` to `CSS Glass & Backdrop-Filter`, `Dashboard Density Patterns`, `Terminal Multiplexer UIs`, `Tauri v2 macOS Platform`?**
  _High betweenness centrality (0.269) - this node is a cross-community bridge._
- **Why does `CSS Glassmorphism — Premium vs Cheap` connect `CSS Glass & Backdrop-Filter` to `Tauri v2 macOS Platform`, `Electron macOS Platform`?**
  _High betweenness centrality (0.252) - this node is a cross-community bridge._
- **What connects `Glass Border Trick — 1px light edge catch simulates light reflecting off glass`, `Blur Amount Reference — 2-4px frosted, 8-12px menu bar, 16-20px spotlight, 30px+ iOS`, `gmux Dark Theme rgba Values — titlebar, agent cards, HUD, tooltip, modal backdrop` to the rest of the system?**
  _18 weakly-connected nodes found - possible documentation gaps or missing edges._