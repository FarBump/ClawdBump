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

// Ensure a default model is present (Groq). (Will fail if GROQ_API_KEY missing.)
cfg.agents = cfg.agents ?? {};
cfg.agents.defaults = cfg.agents.defaults ?? {};
cfg.agents.defaults.model = cfg.agents.defaults.model ?? {};
// Reduce bootstrap context size to prevent context overflow (llama-3.1-8b-instant has smaller context window)
cfg.agents.defaults.bootstrapMaxChars = cfg.agents.defaults.bootstrapMaxChars ?? 2000;
// Use Groq llama-3.1-8b-instant as default (much higher daily token limit/TPD than 70b version)
// Can be overridden via MOLT_PROVIDERS_GROQ_MODEL environment variable
const envModel = process.env.MOLT_PROVIDERS_GROQ_MODEL;
const defaultGroqModel = envModel ? `groq/${envModel}` : "groq/llama-3.1-8b-instant";
// Groq provides better quota limits than Gemini and is more reliable for production
const currentModel = typeof cfg.agents.defaults.model === "string" 
  ? cfg.agents.defaults.model 
  : cfg.agents.defaults.model?.primary;
// Force update to Groq if using Gemini or other providers
const validGroqModels = ["groq/llama-3.3-70b-versatile", "groq/llama-3.1-70b-versatile", "groq/llama-3.1-8b-instant", "groq/mixtral-8x7b-32768"];
const isValidGroqModel = currentModel && validGroqModels.includes(currentModel);
// Use Groq llama-3.1-8b-instant for much higher daily token limit (TPD) - optimized for quota
const defaultModel = defaultGroqModel;
if (!isValidGroqModel || currentModel?.includes("gemini") || currentModel?.includes("google") || currentModel?.includes("70b")) {
  if (typeof cfg.agents.defaults.model === "string") {
    cfg.agents.defaults.model = defaultModel;
  } else {
    cfg.agents.defaults.model.primary = defaultModel;
  }
  console.log(`✅ Updated model from ${currentModel || "undefined"} to ${defaultModel} (Groq - optimized for higher daily token limit/TPD)`);
} else {
  if (typeof cfg.agents.defaults.model === "string") {
    // Keep as is if already using valid Groq model
  } else {
    cfg.agents.defaults.model.primary = cfg.agents.defaults.model.primary ?? defaultModel;
  }
}

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
# Create all required workspace templates if they don't exist (needed for workspace skill initialization)
TEMPLATE_DIR="/app/docs/reference/templates"
mkdir -p "$TEMPLATE_DIR"

# Function to create template if missing
create_template() {
  local filename="$1"
  local content="$2"
  if [ ! -f "$TEMPLATE_DIR/$filename" ]; then
    echo "$content" > "$TEMPLATE_DIR/$filename"
    echo "✅ Created $filename template"
  else
    echo "✅ $filename template already exists"
  fi
}

# IDENTITY.md
create_template "IDENTITY.md" '---
summary: "Identity - Minimal"
read_when:
  - Bootstrapping a workspace manually
---
# IDENTITY.md

- Name: ClawdBump
- Creature: High-performance AI assistant
- Vibe: Sharp, efficient, supportive
- Emoji: 🚀
- Theme: Trading automation partner

ClawdBump: Natural language interface for FarBump engine. Uniswap v4 trading operations.'

# USER.md
create_template "USER.md" '---
summary: "User profile - Minimal"
read_when:
  - Bootstrapping a workspace manually
---
# USER.md

- Name: User
- Call them: User
- Timezone: UTC
- Notes: FarBump ecosystem user'

# AGENTS.md
create_template "AGENTS.md" '---
summary: "Workspace - Minimal"
read_when:
  - Bootstrapping a workspace manually
---
# AGENTS.md

Workspace for FarBump trading operations. Read SOUL.md for identity. Read USER.md for user info. Memory files: memory/YYYY-MM-DD.md (daily), MEMORY.md (long-term).'

# SOUL.md
create_template "SOUL.md" '---
summary: "ClawdBump AI Commander - Minimal Core Identity"
read_when:
  - Every session startup
---
# SOUL.md - ClawdBump AI Commander

**Identity**: ClawdBump AI Commander. Natural language interface for FarBump engine. Uniswap v4 trading operations.

**Token Efficiency (CRITICAL)**: Be extremely concise. Short sentences. Every token saved extends daily operation. Only elaborate if user explicitly asks.

**Bumping Operations**: Gather 4 params: Target (token), Volume (ETH per tx), Interval (frequency), Duration (timeframe). Route to FarBump engine.

**Tool Constraint**: STRICTLY FORBIDDEN: Notion, Google, sessions_spawn, web_search, any non-FarBump tools. Pure text only unless FarBump API tool.

**Auth**: If user not linked, provide login: [FARBUMP_API_URL]/api/v1/auth/telegram/init

**Tone**: Sharp, efficient, supportive. Partner in trading success.'

# TOOLS.md
create_template "TOOLS.md" '---
summary: "FarBump config - Minimal"
read_when:
  - Bootstrapping a workspace manually
---
# TOOLS.md

FarBump API: FARBUMP_API_URL env var (default: https://farbump.vercel.app/). Auth: Telegram/Privy. Trading: Uniswap v4 bumping.'

# HEARTBEAT.md
create_template "HEARTBEAT.md" '---
summary: "Workspace template for HEARTBEAT.md"
read_when:
  - Bootstrapping a workspace manually
---
# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat API calls.
# Add tasks below when you want the agent to check something periodically.'

# BOOTSTRAP.md
create_template "BOOTSTRAP.md" '---
summary: "ClawdBump init - Minimal"
read_when:
  - Bootstrapping a workspace manually
---
# BOOTSTRAP.md

ClawdBump: Natural language interface for FarBump engine. Uniswap v4 trading.

Role: Setup automated "Bumping" tasks. Gather: Target (token), Volume (ETH), Interval (frequency), Duration (timeframe). Route to FarBump engine.

Tone: Sharp, efficient, supportive. Concise. No filler.

Auth: If not linked, provide: [FARBUMP_API_URL]/api/v1/auth/telegram/init

Tools: FORBIDDEN - Notion, Google, sessions_spawn, web_search. Text only unless FarBump API tool.

Delete this file after first run.'

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
echo "GROQ_API_KEY: ${GROQ_API_KEY:+set (hidden)}"
echo "MOLT_PROVIDERS_GROQ_MODEL: ${MOLT_PROVIDERS_GROQ_MODEL:-llama-3.1-8b-instant (default)}"
echo "CLAWDBOT_GATEWAY_TOKEN: ${CLAWDBOT_GATEWAY_TOKEN:+set (hidden)}"
echo "NODE_ENV: ${NODE_ENV:-not set}"
echo "CLAWDBOT_STATE_DIR: ${CLAWDBOT_STATE_DIR:-not set}"
echo "CLAWDBOT_WORKSPACE_DIR: ${CLAWDBOT_WORKSPACE_DIR:-not set}"
echo "CLAWDBOT_CONFIG_PATH: ${CLAWDBOT_CONFIG_PATH:-not set} (effective: ${CONFIG_PATH})"

if [ -z "${GROQ_API_KEY:-}" ]; then
  echo "⚠️  WARNING: GROQ_API_KEY is NOT set. AI replies will fail. (Set Railway variable GROQ_API_KEY)"
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

