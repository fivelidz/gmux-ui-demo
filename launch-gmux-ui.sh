#!/bin/bash
# gmux UI launcher — starts HTTP server and opens browser
# Usage: ./launch-gmux-ui.sh [port]
PORT=${1:-5550}
DIR="$(cd "$(dirname "$0")" && pwd)"

# Kill any old server on this port
pkill -f "http.server $PORT" 2>/dev/null
sleep 0.3

echo "Starting gmux UI server on port $PORT..."
cd "$DIR"
python3 -m http.server $PORT &>/tmp/gmux-ui-server.log &
SERVER_PID=$!
echo "Server PID: $SERVER_PID (log: /tmp/gmux-ui-server.log)"

sleep 1

# Open the v3 UI
URL="http://localhost:$PORT/v2/index.html"
echo "Opening: $URL"
xdg-open "$URL" 2>/dev/null || \
  firefox "$URL" 2>/dev/null || \
  chromium "$URL" 2>/dev/null || \
  google-chrome "$URL" 2>/dev/null || \
  echo "Open manually: $URL"

echo ""
echo "gmux UI running at: $URL"
echo "Demo build:         http://localhost:$PORT/gmux-v3.html"
echo "All systems:        http://localhost:$PORT/"
echo ""
echo "Press Ctrl+C to stop server"
wait $SERVER_PID
