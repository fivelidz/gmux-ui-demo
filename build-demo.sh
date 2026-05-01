#!/bin/bash
# build-demo.sh — Generate gmux-demo.html (single-file embeddable demo)
# from v2/index.html + shared/*.js
#
# Why: gmux.ai/demo and Webflow/Framer embeds need ONE file with no relative imports.
# Run:  ./build-demo.sh
# Output: gmux-demo.html in repo root

set -e
cd "$(dirname "$0")"

export SRC="v2/index.html"
export OUT="gmux-demo.html"

# Read the source HTML and emit a build header + replace imports with inlined modules
python3 <<'PYEOF'
import re, sys, os, datetime

SRC = os.environ['SRC']
OUT = os.environ['OUT']

with open(SRC, "r") as f:
    html = f.read()

with open("shared/mock-data.js","r") as f:        mock = f.read()
with open("shared/gesture-engine.js","r") as f:   eng  = f.read()
with open("shared/gesture-renderer.js","r") as f: ren  = f.read()

# Strip ES module export keyword (inlined modules don't need them)
def strip_exports(s):
    s = re.sub(r'^export\s+(const|let|var|function|class|async)', r'\1', s, flags=re.MULTILINE)
    s = re.sub(r'^export\s+default\s+', r'', s, flags=re.MULTILINE)
    return s

inlined = (
    "// ─── INLINED: shared/mock-data.js ───\n"        + strip_exports(mock) + "\n\n" +
    "// ─── INLINED: shared/gesture-engine.js ───\n"   + strip_exports(eng)  + "\n\n" +
    "// ─── INLINED: shared/gesture-renderer.js ───\n" + strip_exports(ren)  + "\n"
)

# Replace the three import lines with the inlined code.
# Original v2/index.html has:
#   import { MOCK_PANES, ... } from '../shared/mock-data.js';
#   import { GestureEngine }   from '../shared/gesture-engine.js';
#   import { GestureRenderer } from '../shared/gesture-renderer.js';
import_block_pattern = re.compile(
    r"import \{[^}]*\}\s+from '\.\./shared/mock-data\.js';[ \t]*\n"
    r"import \{[^}]*\}\s+from '\.\./shared/gesture-engine\.js';[ \t]*\n"
    r"import \{[^}]*\}\s+from '\.\./shared/gesture-renderer\.js';",
    re.MULTILINE
)

if not import_block_pattern.search(html):
    sys.stderr.write(f"ERROR: Could not find expected import block in {SRC}\n")
    sys.exit(1)

html = import_block_pattern.sub(inlined, html)

# Add a build banner near the top of the file
banner = (
    "<!--\n"
    "  gmux-demo.html — single-file embeddable demo\n"
    f"  Built: {datetime.datetime.now().isoformat(timespec='seconds')}\n"
    "  Source: v2/index.html + shared/*.js (inlined)\n"
    "  Run via http(s):// — file:// will fail because of MediaPipe WASM\n"
    "-->\n"
)
html = banner + html

# Force the demo banner ON for this build (it's a demo, after all)
html = html.replace(
    "(function setupDemoBanner(){",
    "(function setupDemoBanner(){\n  // single-file demo build: always show banner\n  document.getElementById('demo-banner').classList.add('on');\n  return;",
    1
)

# Update the title so it's clearly the demo
html = html.replace("<title>gmux v2.4</title>", "<title>gmux · live demo</title>", 1)

with open(OUT,"w") as f:
    f.write(html)

size_kb = os.path.getsize(OUT) / 1024
print(f"\u2713 Built {OUT} ({size_kb:.1f} KB)")
PYEOF

echo ""
echo "  Test locally:  http://localhost:5550/$OUT"
echo "  Embed:         <iframe src=\"https://gmux.ai/demo\" width=\"100%\" height=\"720\" allow=\"camera; microphone\"></iframe>"
