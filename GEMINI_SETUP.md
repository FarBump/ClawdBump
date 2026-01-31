# Setup Gemini API (FREE!)

## Why Gemini?

- ✅ **FREE Tier**: 1,500 requests per day (RPD) gratis
- ✅ **Fast**: Gemini 2.0 Flash sangat cepat
- ✅ **Smart**: Comparable dengan GPT-4
- ✅ **No Credit Card**: Tidak perlu CC untuk free tier

## Get API Key (2 menit)

### Step 1: Go to Google AI Studio

https://aistudio.google.com/apikey

### Step 2: Create API Key

1. Click **"Get API Key"** atau **"Create API Key"**
2. Pilih **"Create API key in new project"** (recommended)
3. Copy API key yang muncul
4. **Save it!** (akan terlihat seperti: `AIzaSyB1234567890abcdefghijklmnopqrstuvw`)

### Step 3: Verify API Key Works

```bash
# Test API key
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=YOUR_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": [{
      "parts":[{"text": "Hello"}]
    }]
  }'
```

Expected: JSON response dengan text generation.

---

## Configure Clawdbot

### Local Setup

Edit `.env.local`:

```bash
GOOGLE_GENERATIVE_AI_API_KEY=AIzaSyB1234567890abcdefghijklmnopqrstuvw
```

### Railway Setup

```bash
railway variables set GOOGLE_GENERATIVE_AI_API_KEY="AIzaSyB1234567890abcdefghijklmnopqrstuvw"
```

---

## Gemini Models Available

Clawdbot supports these Gemini models:

### Recommended for Telegram Bot:

```json
"model": "google/gemini-1.5-flash"
```

**Best for:**
- Stable and reliable
- Higher quota limits (better for production)
- Fast responses
- Free tier friendly

### Alternative Models:

```json
// More capable, slower
"model": "google/gemini-1.5-pro"

// Experimental, newer models (may have stricter quotas)
"model": "google/gemini-3-flash-preview"
"model": "google/gemini-3-pro-preview"
```

---

## Free Tier Limits

### Gemini 1.5 Flash (Recommended)

- **Requests**: Higher quota limits than Gemini 3 Flash
- **Rate**: Better rate limits for production use
- **Context**: 1M tokens
- **Output**: 8k tokens max
- **Cost**: **FREE!**
- **Stability**: More stable and reliable for production

### What This Means for Your Bot:

**Daily usage:**
- 1,500 Telegram messages/day = **50 users × 30 messages each**
- More than enough untuk testing & small scale

**If you need more:**
- Upgrade to paid plan: ~$0.075 per 1M tokens (sangat murah!)
- Or use multiple API keys (rotate)

---

## Configuration Comparison

### Option 1: Gemini (Recommended - FREE!)

```json
{
  "agent": {
    "model": "google/gemini-1.5-flash"
  }
}
```

**Environment:**
```bash
GOOGLE_GENERATIVE_AI_API_KEY=AIzaSy...
```

**Cost:** $0/month (free tier)

### Option 2: Anthropic Claude

```json
{
  "agent": {
    "model": "anthropic/claude-opus-4-5"
  }
}
```

**Environment:**
```bash
ANTHROPIC_API_KEY=sk-ant-...
```

**Cost:** ~$15-50/month (pay as you go)

### Option 3: OpenAI GPT-4

```json
{
  "agent": {
    "model": "openai/gpt-4"
  }
}
```

**Environment:**
```bash
OPENAI_API_KEY=sk-...
```

**Cost:** ~$20-60/month (pay as you go)

---

## Performance Comparison

| Model | Speed | Quality | Cost/1M tokens | Free Tier |
|-------|-------|---------|----------------|-----------|
| Gemini 2.0 Flash | ⚡⚡⚡ | ⭐⭐⭐⭐ | $0.075 | ✅ 1500 RPD |
| Claude Opus 4.5 | ⚡⚡ | ⭐⭐⭐⭐⭐ | $15.00 | ❌ |
| GPT-4 Turbo | ⚡⚡ | ⭐⭐⭐⭐⭐ | $10.00 | ❌ |
| GPT-3.5 Turbo | ⚡⚡⚡ | ⭐⭐⭐ | $1.50 | ❌ |

**For Telegram bot: Gemini 2.0 Flash is perfect!**

---

## Test Your Setup

### Test Locally

```bash
cd /Users/macbookair2018/Downloads/moltbot-2026.1.24\ 2

# Set API key
export GOOGLE_GENERATIVE_AI_API_KEY="AIzaSy...your_key..."
export TELEGRAM_BOT_TOKEN="8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y"
export FARBUMP_API_URL="https://farbump.vercel.app"

# Start bot
pnpm clawdbot gateway run --port 18789 --verbose
```

### Test on Telegram

1. Open Telegram
2. Search: `@ClawdBumpbot`
3. Send: `/start`

Expected: Bot responds in **1-2 seconds** (super fast!)

---

## Monitoring Usage

### Check Quota

Go to: https://aistudio.google.com/apikey

You'll see:
- Requests today: X/1,500
- Rate limit: X/10 per minute

### If You Hit Limits

**Daily limit (1,500 requests):**
- Wait until midnight (resets daily)
- Or upgrade to paid tier
- Or create another API key (allowed)

**Rate limit (10 per minute):**
- Clawdbot handles this automatically
- Queues requests if needed
- No action needed!

---

## Troubleshooting

### Error: "API key not valid"

```bash
# Verify key format
echo $GOOGLE_GENERATIVE_AI_API_KEY
# Should be: AIzaSy...

# Test directly
curl "https://generativelanguage.googleapis.com/v1beta/models?key=$GOOGLE_GENERATIVE_AI_API_KEY"
```

### Error: "Resource exhausted"

You hit the daily limit (1,500 requests).

**Solutions:**
1. Wait until tomorrow (resets at midnight PST)
2. Upgrade to paid tier (very cheap!)
3. Use another Google account + API key

### Error: "Model not found"

Check model name in `clawdbot-config.json`:

```json
"model": "google/gemini-1.5-flash"
```

Must be exactly this format!

---

## Cost Savings

### Telegram Bot Usage Estimate

**Assumptions:**
- 100 users
- 10 messages per user per day
- Average 1,000 tokens per conversation

**Cost comparison:**

| Provider | Monthly Cost |
|----------|-------------|
| Gemini (free tier) | $0 🎉 |
| GPT-3.5 Turbo | ~$15/mo |
| GPT-4 Turbo | ~$100/mo |
| Claude Opus | ~$150/mo |

**Gemini saves you: $100-150/month!**

---

## Upgrade Path

**Start with Gemini free tier:**
- Perfect for development
- Good for small scale (~50 active users)

**When to upgrade:**

1. **Need more requests** (>1,500/day)
   → Upgrade to Gemini paid: ~$5-10/month
   
2. **Need better quality**
   → Switch to Claude/GPT-4
   
3. **Need specific features**
   → Use multiple models (Gemini for speed, Claude for quality)

---

## Summary

✅ **Best Choice for Starting:**

```bash
# Get key (free, no CC):
https://aistudio.google.com/apikey

# Set in .env.local:
GOOGLE_GENERATIVE_AI_API_KEY=AIzaSy...

# Config model:
"model": "google/gemini-1.5-flash"

# Deploy:
railway up
```

**Why:**
- ✅ Completely FREE
- ✅ 1,500 requests/day = plenty for testing
- ✅ Fast responses (1-2 seconds)
- ✅ Good quality (comparable to GPT-4)
- ✅ No credit card required
- ✅ Easy to upgrade later if needed

**Perfect untuk mulai! 🚀**
