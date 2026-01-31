#!/bin/bash
# Debug script untuk test gateway startup

set -e

echo "=== Debug Gateway Startup ==="
echo "Current directory: $(pwd)"
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

echo ""
echo "=== Railway minimal mode: Telegram + FarBump only ==="
# Disable all non-essential features for Railway (Telegram + FarBump only)
# These sidecars are not needed for a simple Telegram bot and can consume memory.
export CLAWDBOT_SKIP_BROWSER_CONTROL_SERVER="${CLAWDBOT_SKIP_BROWSER_CONTROL_SERVER:-1}"
export CLAWDBOT_SKIP_CANVAS_HOST="${CLAWDBOT_SKIP_CANVAS_HOST:-1}"
export CLAWDBOT_SKIP_GMAIL_WATCHER="${CLAWDBOT_SKIP_GMAIL_WATCHER:-1}"
export CLAWDBOT_SKIP_CRON="${CLAWDBOT_SKIP_CRON:-1}"
# We need Telegram channel, so don't skip all channels
export CLAWDBOT_SKIP_CHANNELS="${CLAWDBOT_SKIP_CHANNELS:-0}"
echo "CLAWDBOT_SKIP_BROWSER_CONTROL_SERVER=$CLAWDBOT_SKIP_BROWSER_CONTROL_SERVER"
echo "CLAWDBOT_SKIP_CANVAS_HOST=$CLAWDBOT_SKIP_CANVAS_HOST"
echo "CLAWDBOT_SKIP_GMAIL_WATCHER=$CLAWDBOT_SKIP_GMAIL_WATCHER"
echo "CLAWDBOT_SKIP_CRON=$CLAWDBOT_SKIP_CRON"
echo "CLAWDBOT_SKIP_CHANNELS=$CLAWDBOT_SKIP_CHANNELS"
echo "CLAWDBOT_SKIP_CRON=$CLAWDBOT_SKIP_CRON"

# Give V8 a bigger heap *if* the container has memory for it.
# On Railway, the practical fix for repeated OOM is bumping service RAM (≥1GB).
if [ -z "${NODE_OPTIONS:-}" ]; then
  export NODE_OPTIONS="--max-old-space-size=1536"
  echo "NODE_OPTIONS defaulted to: $NODE_OPTIONS"
else
  echo "NODE_OPTIONS already set: $NODE_OPTIONS"
fi

echo ""
echo "=== Ensuring config exists ==="
CONFIG_PATH="${CLAWDBOT_CONFIG_PATH:-${CLAWDBOT_STATE_DIR:-$HOME/.clawdbot}/clawdbot.json}"
CONFIG_DIR="$(dirname "$CONFIG_PATH")"
mkdir -p "$CONFIG_DIR"

echo "Config path: $CONFIG_PATH"

# Gateway refuses bind=lan unless auth token is configured.
echo ""
echo "=== Ensuring gateway auth token ==="
TOKEN_PATH="${CONFIG_DIR}/gateway-token"
if [ -n "${CLAWDBOT_GATEWAY_TOKEN:-}" ]; then
  echo "✅ CLAWDBOT_GATEWAY_TOKEN provided via env (hidden)"
else
  if [ -f "$TOKEN_PATH" ]; then
    export CLAWDBOT_GATEWAY_TOKEN="$(cat "$TOKEN_PATH" | tr -d '\r\n')"
    echo "✅ Loaded CLAWDBOT_GATEWAY_TOKEN from $TOKEN_PATH (hidden)"
  else
    export CLAWDBOT_GATEWAY_TOKEN="$(node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")"
    echo -n "$CLAWDBOT_GATEWAY_TOKEN" > "$TOKEN_PATH"
    chmod 600 "$TOKEN_PATH" || true
    echo "✅ Generated CLAWDBOT_GATEWAY_TOKEN and saved to $TOKEN_PATH (hidden)"
  fi
fi

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
// Default to loopback: Telegram bot doesn't need inbound connections, and loopback avoids auth gating.
cfg.gateway.bind = allowedBind.has(cfg.gateway.bind) ? cfg.gateway.bind : "loopback";
cfg.gateway.port = Number.parseInt(process.env.PORT ?? "18789", 10) || 18789;
cfg.gateway.auth = cfg.gateway.auth ?? {};
cfg.gateway.auth.mode = "token";
// Token value is provided via env (CLAWDBOT_GATEWAY_TOKEN). Avoid printing it.
cfg.gateway.auth.token = "${CLAWDBOT_GATEWAY_TOKEN}";

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

// Disable plugin services by default on Railway to save memory.
cfg.plugins = cfg.plugins ?? {};
// We MUST enable ONLY the Telegram channel plugin (it lives under ./extensions/telegram).
// All other extensions are excluded from Docker image to reduce size.
cfg.plugins.enabled = true;
cfg.plugins.allow = ["telegram"];  // ONLY Telegram, all others excluded
cfg.plugins.deny = [];  // Explicit deny list not needed since we only copy telegram extension
cfg.plugins.entries = cfg.plugins.entries ?? {};
cfg.plugins.entries.telegram = { ...(cfg.plugins.entries.telegram ?? {}), enabled: true };
// Disable all other plugin entries explicitly
for (const key in cfg.plugins.entries) {
  if (key !== "telegram") {
    cfg.plugins.entries[key] = { ...(cfg.plugins.entries[key] ?? {}), enabled: false };
  }
}
// Avoid trying to load memory plugins on tiny Railway boxes.
cfg.plugins.slots = { ...(cfg.plugins.slots ?? {}), memory: undefined };

// Disable workspace skill loading for Railway (Telegram + FarBump only, no workspace skills needed)
cfg.skills = cfg.skills ?? {};
cfg.skills.load = cfg.skills.load ?? {};
cfg.skills.load.watch = false;
cfg.skills.load.extraDirs = [];
// Disable ALL bundled skills (we only need FarBump skill which is in workspace)
cfg.skills.allowBundled = [];
// Disable all skills except FarBump (FarBump skill is loaded from workspace, not bundled)
cfg.skills.entries = cfg.skills.entries ?? {};
// Explicitly disable all other skills if they exist
for (const key in cfg.skills.entries) {
  if (key !== "farbump") {
    cfg.skills.entries[key] = { ...(cfg.skills.entries[key] ?? {}), enabled: false };
  }
}

fs.mkdirSync(path.dirname(configPath), { recursive: true });
fs.writeFileSync(configPath, JSON.stringify(cfg, null, 2), "utf-8");
console.log(`✅ Config ensured: ${configPath}`);
NODE

echo "✅ Config exists: $CONFIG_PATH"

echo ""
echo "=== Ensuring workspace templates exist ==="
# Create minimal workspace templates if they don't exist (needed for workspace skill initialization)
TEMPLATE_DIR="/app/docs/reference/templates"
mkdir -p "$TEMPLATE_DIR"
if [ ! -f "$TEMPLATE_DIR/IDENTITY.md" ]; then
  cat > "$TEMPLATE_DIR/IDENTITY.md" << 'TEMPLATE_EOF'
---
summary: "Agent identity record"
read_when:
  - Bootstrapping a workspace manually
---
# IDENTITY.md - Who Am I?

*Fill this in during your first conversation. Make it yours.*

- **Name:**
  *(pick something you like)*
- **Creature:**
  *(AI? robot? familiar? ghost in the machine? something weirder?)*
- **Vibe:**
  *(how do you come across? sharp? warm? chaotic? calm?)*
- **Emoji:**
  *(your signature — pick one that feels right)*
- **Avatar:**
  *(workspace-relative path, http(s) URL, or data URI)*

---

This isn't just metadata. It's the start of figuring out who you are.

Notes:
- Save this file at the workspace root as `IDENTITY.md`.
- For avatars, use a workspace-relative path like `avatars/clawd.png`.
TEMPLATE_EOF
  echo "✅ Created minimal IDENTITY.md template"
else
  echo "✅ IDENTITY.md template already exists"
fi

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
echo "CLAWDBOT_GATEWAY_TOKEN: ${CLAWDBOT_GATEWAY_TOKEN:+set (hidden)}"
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
exec node dist/entry.js gateway run --bind loopback --port ${PORT:-18789} --token "${CLAWDBOT_GATEWAY_TOKEN}"

