# FarBump Integration Guide

## Overview
This guide explains how to integrate Clawdbot with FarBump API and deploy to Railway.

## Architecture
```
Telegram User → Clawdbot Bot → FarBump API
                     ↓
              Railway Cloud Server
```

## Quick Setup (5 minutes)

### 1. Create Telegram Bot
1. Chat with @BotFather on Telegram
2. Send `/newbot`
3. Follow prompts to create bot
4. Copy the bot token (looks like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Get FarBump API Credentials
- API URL: `https://api.farbump.com` (or your actual API endpoint)
- API Key: Get from FarBump dashboard

### 3. Local Testing

```bash
# Install dependencies
pnpm install

# Create config file
cat > ~/.clawdbot/clawdbot.json << 'EOF'
{
  "agent": {
    "model": "anthropic/claude-opus-4-5"
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN_HERE",
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "0.0.0.0",
    "port": 18789
  }
}
EOF

# Set environment variables
export FARBUMP_API_URL="https://api.farbump.com"
export FARBUMP_API_KEY="your_api_key_here"
export TELEGRAM_BOT_TOKEN="your_telegram_bot_token"

# Start gateway
pnpm clawdbot gateway run --port 18789
```

### 4. Deploy to Railway

```bash
# Login to Railway
railway login

# Initialize project
railway init

# Add environment variables in Railway dashboard:
# - TELEGRAM_BOT_TOKEN
# - FARBUMP_API_URL
# - FARBUMP_API_KEY
# - ANTHROPIC_API_KEY (or your model provider)

# Deploy
git add .
git commit -m "Deploy FarBump bot"
git push railway main
```

## Custom Tools

The bot includes these FarBump-specific tools:

### 1. Swap Token
Trigger a token swap through FarBump API.
```
User: "Swap 0.1 ETH to USDC"
Bot: ✅ Swap initiated! TX: 0x123...
```

### 2. Check Status
Check swap status or account balance.
```
User: "What's my balance?"
Bot: Your balance: 1.5 ETH, 1000 USDC
```

### 3. Auto-Swap Schedule
Set up automated swaps.
```
User: "Auto-swap 0.01 ETH to USDC every day"
Bot: ✅ Auto-swap scheduled!
```

## User Flow

1. User sends `/start` to bot
2. Bot responds with welcome and instructions
3. User can:
   - Ask natural language questions: "Swap 0.1 ETH to USDC"
   - Use commands: `/swap 0.1 ETH USDC`
   - Check status: `/balance`
   - Set automation: `/autoswap enable`

## Monitoring

```bash
# View logs on Railway
railway logs

# Or locally
clawdbot logs --follow

# Check bot status
clawdbot channels status --probe
```

## Security Notes

1. **API Keys**: Never commit to git, use Railway environment variables
2. **User Access**: Configure `dmPolicy` and `allowFrom` for production
3. **Rate Limiting**: Implement in FarBump API tools
4. **Error Handling**: All tools include try-catch and user-friendly errors

## Troubleshooting

### Bot not responding
```bash
# Check if gateway is running
railway ps

# Check logs for errors
railway logs
```

### API calls failing
- Verify FARBUMP_API_KEY is set correctly
- Check API endpoint URL
- Ensure FarBump API is accessible from Railway

### Out of memory on Railway
- Upgrade Railway plan
- Or optimize by disabling unused features in config

## Cost Estimates

- Railway Hobby: $5/month (512MB RAM)
- Railway Pro: $20/month (8GB RAM) - recommended for production
- API calls: Based on FarBump pricing

## Next Steps

1. Test locally first
2. Deploy to Railway
3. Test with real users
4. Monitor and optimize
5. Add more features as needed
