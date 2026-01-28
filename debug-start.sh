#!/bin/bash
# Debug script untuk test gateway startup

set -e

echo "=== Debug Gateway Startup ==="
echo "Current directory: $(pwd)"
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

echo ""
echo "=== Checking files ==="
if [ -f "dist/entry.js" ]; then
  echo "✅ dist/entry.js exists"
  ls -lh dist/entry.js
else
  echo "❌ dist/entry.js NOT FOUND!"
  echo "Contents of dist/:"
  ls -la dist/ || echo "dist/ directory does not exist"
  exit 1
fi

echo ""
echo "=== Checking environment variables ==="
echo "PORT: ${PORT:-not set}"
echo "TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:+set (hidden)}"
echo "GEMINI_API_KEY: ${GEMINI_API_KEY:+set (hidden)}"
echo "NODE_ENV: ${NODE_ENV:-not set}"
echo "CLAWDBOT_STATE_DIR: ${CLAWDBOT_STATE_DIR:-not set}"
echo "CLAWDBOT_WORKSPACE_DIR: ${CLAWDBOT_WORKSPACE_DIR:-not set}"

echo ""
echo "=== Testing entry point ==="
if node dist/entry.js --help > /dev/null 2>&1; then
  echo "✅ Entry point is executable"
else
  echo "❌ Entry point failed"
  node dist/entry.js --help
fi

echo ""
echo "=== Starting gateway ==="
exec node dist/entry.js gateway run --bind 0.0.0.0 --port ${PORT:-18789}

