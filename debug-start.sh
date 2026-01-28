#!/bin/bash
# Debug script untuk test gateway startup

set -e

echo "=== Debug Gateway Startup ==="
echo "Current directory: $(pwd)"
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

echo ""
echo "=== Ensuring config exists ==="
CONFIG_PATH="${CLAWDBOT_CONFIG_PATH:-${CLAWDBOT_STATE_DIR:-$HOME/.clawdbot}/clawdbot.json}"
CONFIG_DIR="$(dirname "$CONFIG_PATH")"
mkdir -p "$CONFIG_DIR"

echo "Config path: $CONFIG_PATH"

# Ensure config exists AND is sane. We repair in-place because the volume may
# already contain an old/bad config from previous runs.
echo "=== Validating/repairing config ==="
node - <<'NODE'
import fs from "node:fs";
import path from "node:path";

const configPath =
  process.env.CLAWDBOT_CONFIG_PATH ??
  path.join(process.env.CLAWDBOT_STATE_DIR ?? `${process.env.HOME}/.clawdbot`, "clawdbot.json");

const allowedBind = new Set(["loopback", "lan", "tailnet", "auto", "custom"]);

let cfg: any = {};
if (fs.existsSync(configPath)) {
  try {
    cfg = JSON.parse(fs.readFileSync(configPath, "utf-8"));
  } catch {
    cfg = {};
  }
}

// Ensure minimal gateway config.
cfg.gateway = cfg.gateway ?? {};
cfg.gateway.mode = "local";
cfg.gateway.bind = allowedBind.has(cfg.gateway.bind) ? cfg.gateway.bind : "lan";
cfg.gateway.port = Number.parseInt(process.env.PORT ?? "18789", 10) || 18789;

// Ensure telegram enabled; token remains in env.
cfg.channels = cfg.channels ?? {};
cfg.channels.telegram = cfg.channels.telegram ?? {};
cfg.channels.telegram.enabled = true;
cfg.channels.telegram.dmPolicy = cfg.channels.telegram.dmPolicy ?? "open";
cfg.channels.telegram.allowFrom = cfg.channels.telegram.allowFrom ?? ["*"];

// Ensure a default model is present (Gemini). (Will fail if GEMINI_API_KEY missing.)
cfg.agents = cfg.agents ?? {};
cfg.agents.defaults = cfg.agents.defaults ?? {};
cfg.agents.defaults.model = cfg.agents.defaults.model ?? {};
cfg.agents.defaults.model.primary = cfg.agents.defaults.model.primary ?? "google/gemini-2.0-flash-exp";

fs.mkdirSync(path.dirname(configPath), { recursive: true });
fs.writeFileSync(configPath, JSON.stringify(cfg, null, 2), "utf-8");
console.log(`✅ Config ensured: ${configPath}`);
NODE

echo "✅ Config exists: $CONFIG_PATH"

echo ""
echo "=== Ensuring required state dirs + permissions ==="
# Required dirs mentioned by doctor output:
mkdir -p /data/.clawdbot/agents/main/sessions
mkdir -p /data/.clawdbot/credentials

# Tighten permissions (best-effort; Railway may still run as root)
chmod 700 /data/.clawdbot || true
chmod 600 "${CONFIG_PATH}" || true

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
echo "CLAWDBOT_CONFIG_PATH: ${CLAWDBOT_CONFIG_PATH:-not set} (effective: ${CONFIG_PATH})"

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "⚠️  WARNING: GEMINI_API_KEY is NOT set. AI replies will fail. (Set Railway variable GEMINI_API_KEY)"
fi

echo ""
echo "=== Checking for pnpm (should not exist) ==="
if command -v pnpm > /dev/null 2>&1; then
  echo "❌ WARNING: pnpm is still installed!"
  which pnpm
else
  echo "✅ pnpm is not in PATH (good)"
fi

# Hard-remove pnpm if it exists (some environments may keep it around).
rm -f /usr/local/bin/pnpm /usr/local/bin/pnpx || true

echo ""
echo "=== Checking package.json ==="
if [ -f "package.json" ]; then
  if grep -q '"packageManager"' package.json; then
    echo "❌ WARNING: packageManager field still exists in package.json"
  else
    echo "✅ packageManager field removed (good)"
  fi
  if grep -q '"pnpm"' package.json; then
    echo "❌ WARNING: pnpm field still exists in package.json"
  else
    echo "✅ pnpm field removed (good)"
  fi
fi

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
# gateway --bind expects a bind MODE (not an IP)
exec node dist/entry.js gateway run --bind lan --port ${PORT:-18789}

