# gmux UI Demo

Gesture-based UI demo for **gmux** — an AI-agent terminal multiplexer. **Live at [gmux.ai/demo](https://gmux.ai/demo)**.

This is the standalone front-end exploration: every screen runs entirely on mock data with zero backend requirements — no Rust, no tmux, no Python. Animations are self-driven, so the whole UX (sessions, agents, gestures, split panes) can be evaluated before wiring anything live.

## Run locally

```bash
./serve.sh
# open http://localhost:5550
```

or serve the folder with any static file server. The hub page links to all demos and systems.

## Going live later

`initDataSource()` in each system auto-detects a Tauri environment and, if present, subscribes to real `gmux-state` events instead of mocks — the same files work standalone or embedded. See [`BACKEND_INTEGRATION.md`](BACKEND_INTEGRATION.md).

## Docs

| File | Contents |
|---|---|
| [`RUNNING.md`](RUNNING.md) | How to run every demo |
| [`DEMO_GUIDE.html`](DEMO_GUIDE.html) | Guided tour |
| [`SCOPE.md`](SCOPE.md) · [`FEATURE_NOTES.md`](FEATURE_NOTES.md) | What's in the demo and why |
| [`RESEARCH_UI_DESIGN.md`](RESEARCH_UI_DESIGN.md) | Design research behind the UI |
| [`STATUS_AND_RECOMMENDATIONS.md`](STATUS_AND_RECOMMENDATIONS.md) | Honest status + next steps |

## License

MIT — see [LICENSE](LICENSE).
