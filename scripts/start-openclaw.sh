#!/usr/bin/env bash
set -e

# Railway provides PORT
export PORT="${PORT:-18789}"

# Batasi heap Node (MB); default 6144 (6GB) untuk plan 8GB Railway
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=6144}"

# Run Gateway via npx (openclaw installed locally in build)
exec npx openclaw gateway --port "$PORT" --bind 0.0.0.0 --verbose
