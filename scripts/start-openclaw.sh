#!/usr/bin/env bash
set -e

# Railway provides PORT
export PORT="${PORT:-18789}"

# Batasi heap Node agar tidak OOM di container Railway (default 512MB)
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=460}"

# Run Gateway via npx (openclaw installed locally in build)
exec npx openclaw gateway --port "$PORT" --bind 0.0.0.0 --verbose
