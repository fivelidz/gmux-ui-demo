#!/bin/bash
# gmux UI dev server
# Default port: 5550  (avoids conflict with 8080 which is used by other services)
# Usage:
#   ./serve.sh          → http://localhost:5550
#   ./serve.sh 5551     → http://localhost:5551

PORT=${1:-5550}
DIR="$(cd "$(dirname "$0")" && pwd)"

# Kill any existing server on this port
pkill -f "http.server $PORT" 2>/dev/null

echo ""
echo "  gmux UI  ·  http://localhost:$PORT"
echo "  ─────────────────────────────────────────"
echo "  DEMO (best single demo):"
echo "  http://localhost:$PORT/DEMO.html"
echo ""
echo "  Systems:"
echo "  http://localhost:$PORT/systems/A-ambient-glass/"
echo "  http://localhost:$PORT/systems/B-dense-terminal/"
echo "  http://localhost:$PORT/systems/C-projector-focus/"
echo "  http://localhost:$PORT/systems/D-command-grid/"
echo ""
echo "  Hub (all links):  http://localhost:$PORT/"
echo "  ─────────────────────────────────────────"
echo "  Ctrl+C to stop"
echo ""

cd "$DIR"
python3 -m http.server $PORT
