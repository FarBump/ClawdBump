#!/usr/bin/env bash
set -e

npm install -g openclaw@latest
export PORT="${PORT:-18789}"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=6144}"
openclaw gateway --port "$PORT" --bind lan --allow-unconfigured --verbose
openclaw onboard --install-daemon
openclaw dashboard --no-open
openclaw doctor --fix



