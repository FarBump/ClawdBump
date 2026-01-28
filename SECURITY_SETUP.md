# 🔒 Security Setup Guide - ClawdBump Bot

## ⚠️ IMPORTANT: Never Commit Credentials!

**NEVER** commit these to git:
- ❌ API Keys (Google Gemini, OpenAI, Anthropic)
- ❌ Bot Tokens (Telegram, Discord, etc)
- ❌ Database credentials
- ❌ Any secret keys or passwords

---

## 📝 Configuration Setup

### Step 1: Copy Example Config

```bash
cp clawdbot-config.example.json clawdbot-config.json
```

### Step 2: Set Environment Variables

#### For Local Development:

Create `.env` file (already in .gitignore):

```bash
# .env file (NEVER commit this!)

# Telegram Bot
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Google Gemini API
GOOGLE_API_KEY=your_gemini_api_key_here

# Node Environment
NODE_ENV=development
LOG_LEVEL=info
```

#### For Railway Deployment:

Set in Railway Dashboard → Service → **Variables** tab:

```
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
GOOGLE_API_KEY=your_gemini_api_key_here
NODE_ENV=production
LOG_LEVEL=info
```

### Step 3: Load Environment Variables

ClawdBot akan otomatis load environment variables. Config priority:

1. **Environment variables** (highest priority)
2. **Config file** (`clawdbot-config.json`)
3. **Default values** (lowest priority)

---

## 🔑 How to Get API Keys

### 1. Telegram Bot Token

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Follow instructions to create bot
4. Copy the token (format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Google Gemini API Key

1. Go to https://aistudio.google.com/apikey
2. Click **"Create API Key"**
3. Copy the key (format: `AIzaSy...`)
4. Free tier: 60 requests/minute

---

## 🚨 If You Exposed Credentials (Accident!)

### Immediate Actions:

#### 1. **Revoke Telegram Bot Token**

```bash
# Talk to @BotFather in Telegram:
/token
# Select your bot
# Click "Revoke current token"
# Get new token
```

#### 2. **Revoke Google API Key**

1. Go to https://console.cloud.google.com/apis/credentials
2. Find your API key
3. Click **"Delete"** or **"Regenerate"**
4. Create new key

#### 3. **Remove from Git History**

```bash
# Install git-filter-repo (if not installed)
# pip install git-filter-repo

# Remove sensitive file from history
git filter-repo --path clawdbot-config.json --invert-paths

# Force push (ONLY if repository is private or just created)
git push origin main --force
```

**OR** easier way:

```bash
# Delete GitHub repository
# Create new repository
# Push fresh code (without credentials)
```

---

## ✅ Security Checklist

Before deploying:

- [ ] All API keys stored in environment variables (NOT in code)
- [ ] `.env` file in `.gitignore`
- [ ] `clawdbot-config.json` in `.gitignore` (with credentials)
- [ ] Only `clawdbot-config.example.json` in git (no real credentials)
- [ ] No hardcoded tokens in any `.sh`, `.js`, `.ts` files
- [ ] Railway environment variables set
- [ ] GitHub repository checked for exposed secrets

---

## 📖 Best Practices

### ✅ DO:
- Store credentials in environment variables
- Use `.env` file for local development (gitignored)
- Use Railway Variables for production
- Keep `clawdbot-config.example.json` as template
- Revoke tokens immediately if exposed

### ❌ DON'T:
- Commit `.env` files
- Hardcode API keys in code
- Share credentials via chat/email
- Push credentials to public repositories
- Use same tokens for dev and production

---

## 🔐 Environment Variable Names

ClawdBot recognizes these environment variables:

```bash
# Bot Tokens
TELEGRAM_BOT_TOKEN          # Telegram bot token
DISCORD_BOT_TOKEN           # Discord bot token (if using Discord)

# AI Provider Keys
GOOGLE_API_KEY              # Google Gemini API
ANTHROPIC_API_KEY           # Anthropic Claude API
OPENAI_API_KEY              # OpenAI API

# FarBump Integration
FARBUMP_API_URL             # FarBump API endpoint
FARBUMP_API_KEY             # FarBump API key (if needed)

# Gateway Config
CLAWDBOT_GATEWAY_MODE       # Gateway mode (local/remote)
CLAWDBOT_GATEWAY_BIND       # Bind address (0.0.0.0 for Railway)
CLAWDBOT_GATEWAY_PORT       # Port (Railway auto-assigns)

# Application
NODE_ENV                    # Environment (production/development)
PORT                        # Server port (Railway auto-assigns)
LOG_LEVEL                   # Log level (info/debug/error)
```

---

## 💡 Tips

### Local Development

```bash
# Install dotenv for easy env loading
npm install dotenv

# Or use direnv for auto-loading
# https://direnv.net
```

### Railway Deployment

Railway automatically injects environment variables into your app. No additional setup needed!

### Multiple Environments

```bash
# Development
.env.development

# Staging
.env.staging

# Production (Railway Variables)
```

---

## 📞 Support

**Security Issues:**
- Report to: security@your-domain.com
- Or create private security advisory on GitHub

**Questions:**
- Check documentation: See `QUICK_START_RAILWAY.md`
- Railway docs: https://docs.railway.app/guides/variables

---

## ✅ You're Secure!

Follow this guide and your credentials will stay safe. 🔒

Remember:
- **Environment variables** = ✅ Safe
- **Hardcoded in code** = ❌ Dangerous

