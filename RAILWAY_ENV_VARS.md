# Railway Environment Variables

## Required Environment Variables

### 1. Telegram Bot Token
**Variable:** `TELEGRAM_BOT_TOKEN`  
**Value:** Your Telegram bot token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)  
**Source:** Get from [@BotFather](https://t.me/botfather) on Telegram

**How to get:**
1. Open Telegram and search for `@BotFather`
2. Send `/newbot` command
3. Follow instructions to create a bot
4. Copy the token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

**Reference:** [Telegram Bot API](https://core.telegram.org/bots/api)

---

### 2. Groq API Key
**Variable:** `GROQ_API_KEY`  
**Value:** Your Groq API key (format: `gsk_...`)  
**Source:** Get from [Groq Console](https://console.groq.com/)

**How to get:**
1. Go to [Groq Console](https://console.groq.com/)
2. Sign up or log in with your account
3. Navigate to **API Keys** section
4. Click "Create API Key"
5. Copy the API key (format: `gsk_...`)

**Reference:** [Groq API Documentation](https://console.groq.com/docs)

**Why Groq?**
- Higher quota limits than Gemini
- No quota issues (429 errors)
- Fast inference with LPU technology
- Stable for production use

---

## Optional Environment Variables

### Port (Auto-set by Railway)
**Variable:** `PORT`  
**Default:** `18789`  
**Note:** Railway automatically sets this. Don't override unless needed.

### State Directory
**Variable:** `CLAWDBOT_STATE_DIR`  
**Default:** `/data/.clawdbot`  
**Note:** Should match Railway Volume mount point.

### Workspace Directory
**Variable:** `CLAWDBOT_WORKSPACE_DIR`  
**Default:** `/data/workspace`  
**Note:** Should match Railway Volume mount point.

---

## Setting Variables in Railway

1. Go to your Railway project dashboard
2. Select your service (ClawdBump)
3. Click **Variables** tab
4. Click **+ New Variable**
5. Add each variable:
   - `TELEGRAM_BOT_TOKEN` = `your-telegram-token`
   - `GROQ_API_KEY` = `your-groq-api-key`
   - `FARBUMP_API_URL` = `https://farbump.vercel.app/` (optional, has default)
   - `FARBUMP_API_KEY` = `your-farbump-api-key` (if using FarBump API)
6. Click **Deploy** to apply changes

---

## Verification

After setting variables, check Railway logs:
- Should see: `Telegram: configured`
- Should see: `Groq provider: configured` (or model provider status)
- No errors about missing tokens/keys

---

## Security Notes

⚠️ **Never commit these values to Git!**
- Use Railway environment variables only
- Don't add to `clawdbot-config.json` in the repo
- Use `.env.example` for documentation only


