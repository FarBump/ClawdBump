#!/usr/bin/env bash
set -e

# Railway provides PORT
export PORT="${PORT:-18789}"

# Ensure openclaw is available (installed globally in build)
if ! command -v openclaw &> /dev/null; then
  npm install -g openclaw@latest
fi

# Run Gateway; bind to 0.0.0.0 so Railway can proxy
exec openclaw gateway --port "$PORT" --bind 0.0.0.0 --verbose
