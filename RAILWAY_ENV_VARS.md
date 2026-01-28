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

### 2. Google Gemini API Key
**Variable:** `GEMINI_API_KEY`  
**Value:** Your Gemini API key (format: `AIzaSy...`)  
**Source:** Get from [Google AI Studio](https://aistudio.google.com/app/apikey)

**How to get:**
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the API key (format: `AIzaSy...`)

**Reference:** [Gemini API Quickstart](https://ai.google.dev/gemini-api/docs/quickstart)

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
   - `GEMINI_API_KEY` = `your-gemini-api-key`
6. Click **Deploy** to apply changes

---

## Verification

After setting variables, check Railway logs:
- Should see: `Telegram: configured`
- Should see: `Google provider: configured`
- No errors about missing tokens/keys

---

## Security Notes

⚠️ **Never commit these values to Git!**
- Use Railway environment variables only
- Don't add to `clawdbot-config.json` in the repo
- Use `.env.example` for documentation only

