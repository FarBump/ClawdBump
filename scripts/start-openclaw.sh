#!/usr/bin/env bash
set -e

# Railway provides PORT
export PORT="${PORT:-18789}"

# Run Gateway via npx (openclaw installed locally in build)
exec npx openclaw gateway --port "$PORT" --bind 0.0.0.0 --verbose
