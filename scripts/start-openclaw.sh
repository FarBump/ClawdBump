#!/usr/bin/env bash
set -e

npm install -g openclaw@latest

openclaw onboard --install-daemon
openclaw dashboard --no-open
openclaw doctor --generate-gateway
# Railway provides PORT
export PORT="${PORT:-18789}"

# Batasi heap Node (MB); default 6144 (6GB) untuk plan 8GB Railway
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=6144}"


# Run Gateway via npx (openclaw installed locally in build)
# --allow-unconfigured: jalankan tanpa openclaw setup (env vars cukup untuk Railway)
# --bind lan: dengarkan di interface LAN agar Railway proxy bisa menjangkau (bukan 0.0.0.0)
exec npx openclaw gateway --port "$PORT" --bind lan --allow-unconfigured --verbose
