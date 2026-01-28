# 🚀 Quick Start Guide - FarBump Telegram Bot

## 5-Minute Setup

### Step 1: Clone & Install (2 min)

```bash
cd moltbot-2026.1.24-2
pnpm install
pnpm build
```

### Step 2: Create Telegram Bot (1 min)

1. Open Telegram, cari **@BotFather**
2. Send `/newbot`
3. Ikuti instruksi (nama bot + username)
4. Copy bot token: `123456789:ABCdefGHI...`

### Step 3: Configure (1 min)

Buat file `~/.clawdbot/clawdbot.json`:

```json
{
  "agent": {
    "model": "anthropic/claude-opus-4-5"
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "PASTE_YOUR_BOT_TOKEN_HERE",
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  }
}
```

Set environment variables:
```bash
export TELEGRAM_BOT_TOKEN="your_bot_token"
export FARBUMP_API_URL="https://api.farbump.com"
export FARBUMP_API_KEY="your_farbump_api_key"
export ANTHROPIC_API_KEY="your_anthropic_key"
```

### Step 4: Test Locally (1 min)

```bash
# Start bot
pnpm clawdbot gateway run --port 18789 --verbose

# Open Telegram dan chat dengan bot Anda
# Send: /start
```

---

## Deploy to Railway (10 menit)

### Prerequisites
- Railway account (free): https://railway.app/new
- GitHub account (optional)

### Deploy Steps

#### 1. Install Railway CLI
```bash
npm install -g @railway/cli
railway login
```

#### 2. Initialize Project
```bash
cd moltbot-2026.1.24-2
railway init
# Pilih "Create new project"
# Beri nama: "farbump-telegram-bot"
```

#### 3. Set Environment Variables
```bash
# Set all required variables
railway variables set TELEGRAM_BOT_TOKEN="your_bot_token"
railway variables set FARBUMP_API_URL="https://api.farbump.com"
railway variables set FARBUMP_API_KEY="your_api_key"
railway variables set ANTHROPIC_API_KEY="your_anthropic_key"
railway variables set NODE_ENV="production"
```

#### 4. Deploy
```bash
railway up
```

#### 5. Monitor
```bash
# View logs
railway logs --follow

# Check status
railway status
```

### Done! 🎉

Bot Anda sekarang running 24/7 di Railway cloud!

---

## Verify Deployment

### Test Flow:

1. **Start Bot**
   ```
   User: /start
   Bot: 🔐 Authentication Required
        [Login with Privy] button
   ```

2. **Authenticate** (click button, complete Privy auth)
   
3. **Check Balance**
   ```
   User: /balance
   Bot: 💰 Your FarBump Balance:
        ETH: 1.5
        USDC: 1000
   ```

4. **Perform Swap**
   ```
   User: swap 0.1 ETH to USDC
   Bot: 🔄 Swap Confirmation
        [Confirm] [Cancel]
   
   User: [clicks Confirm]
   Bot: ✅ Swap Successful!
        TX Hash: 0xabc...
   ```

---

## Common Issues & Fixes

### ❌ Bot not responding
```bash
# Check logs
railway logs

# Restart bot
railway restart
```

### ❌ "TELEGRAM_BOT_TOKEN not set"
```bash
# Verify variables
railway variables

# Set again if missing
railway variables set TELEGRAM_BOT_TOKEN="your_token"
```

### ❌ "Failed to connect to FarBump API"
```bash
# Check API URL
railway variables get FARBUMP_API_URL

# Test API manually
curl https://api.farbump.com/health
```

### ❌ Build failed
```bash
# Check build logs
railway logs --build

# Common fix: clear cache
railway restart --clear-cache
```

---

## Architecture Overview

```
┌─────────────────┐
│  Telegram User  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Telegram Bot   │ ← Bot receives messages
│   (Railway)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Clawdbot      │ ← AI processes intent
│  (AI Agent)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  FarBump API    │ ← Executes swaps via Privy
└─────────────────┘
```

---

## What Happens When User Sends Message?

### Example: "swap 0.1 ETH to USDC"

```
1. Telegram → Bot receives message
2. Bot → Checks if user authenticated
3. If not → Sends Privy auth link
4. If yes → Parses swap intent:
   - From: ETH
   - To: USDC  
   - Amount: 0.1
5. Bot → Sends confirmation with buttons
6. User → Clicks [Confirm]
7. Bot → Calls FarBump API:
   POST /api/v1/swap
   {
     "from_token": "ETH",
     "to_token": "USDC",
     "amount": 0.1,
     "wallet": "0x742d35..."
   }
8. FarBump → Executes swap via Privy smart account
9. FarBump → Returns tx_hash
10. Bot → Shows success message to user
```

---

## File Structure

```
moltbot-2026.1.24-2/
├── skills/farbump/
│   ├── SKILL.md                  # Skill documentation
│   ├── privy-auth.ts            # Privy authentication
│   ├── telegram-handlers.ts      # Bot command handlers
│   └── farbump-tools.ts         # FarBump API calls
├── FARBUMP_INTEGRATION.md        # Integration guide
├── FARBUMP_BACKEND_API.md        # Backend API spec
├── RAILWAY_DEPLOYMENT.md         # Railway deployment guide
├── QUICK_START.md                # This file
├── railway.json                  # Railway config
├── Procfile                      # Process file
└── .env.example                  # Environment template
```

---

## Production Checklist

Before launching to users:

### Backend (FarBump)
- [ ] Implement auth endpoints (see FARBUMP_BACKEND_API.md)
- [ ] Setup Privy SDK integration
- [ ] Test smart account creation
- [ ] Configure webhook for Privy callbacks
- [ ] Setup Redis for session storage
- [ ] Add rate limiting
- [ ] Configure monitoring

### Bot (Railway)
- [ ] Deploy to Railway successfully
- [ ] All environment variables set
- [ ] Test /start command
- [ ] Test authentication flow end-to-end
- [ ] Test swap functionality
- [ ] Test error scenarios
- [ ] Configure logging
- [ ] Setup alerts (optional)

### Testing
- [ ] Test with real Telegram user
- [ ] Test Privy authentication
- [ ] Test balance check
- [ ] Test swap execution
- [ ] Test transaction history
- [ ] Test logout/revoke
- [ ] Test error messages
- [ ] Load testing (optional)

### Documentation
- [ ] User guide ready
- [ ] FAQ prepared
- [ ] Support channel created
- [ ] Terms of service (if needed)

---

## Support & Resources

### Documentation
- Clawdbot: https://docs.clawd.bot
- Railway: https://docs.railway.app
- Privy: https://docs.privy.io
- Telegram Bot API: https://core.telegram.org/bots/api

### Community
- Clawdbot Discord: https://discord.gg/clawd
- Railway Discord: https://discord.gg/railway

### Contact
- FarBump Support: @farbump_support (Telegram)
- Issues: Open on GitHub

---

## Next Steps

1. ✅ Complete this quick start
2. 📖 Read FARBUMP_BACKEND_API.md for backend requirements
3. 🔧 Implement backend auth endpoints
4. 🧪 Test integration thoroughly
5. 🚀 Deploy to production
6. 📢 Announce to users!

---

## Tips for Success

1. **Start Simple**: Get basic auth + balance working first
2. **Test Early**: Test each feature as you implement
3. **Monitor Logs**: Railway logs are your friend
4. **Use Redis**: For production, enable Redis addon
5. **Rate Limit**: Implement rate limiting in FarBump API
6. **Document**: Keep API docs updated
7. **Iterate**: Launch MVP, gather feedback, improve

---

Good luck! 🚀

If you encounter issues, check:
1. Railway logs: `railway logs`
2. FarBump API logs
3. Telegram bot logs in Railway dashboard
4. FARBUMP_INTEGRATION.md for troubleshooting
