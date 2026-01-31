# Setup Groq API (FREE!)

## Why Groq?

- ✅ **FREE Tier**: High quota limits, no quota issues
- ✅ **Fast**: Ultra-fast inference with Groq's LPU technology
- ✅ **Reliable**: Stable for production use
- ✅ **No Credit Card**: Free tier available

## Get API Key (2 minutes)

### Step 1: Go to Groq Console

https://console.groq.com/

### Step 2: Create API Key

1. Sign up or log in to Groq Console
2. Navigate to **API Keys** section
3. Click **"Create API Key"**
4. Copy the API key (starts with `gsk_...`)

### Step 3: Verify API Key Works

```bash
# Test API key
curl https://api.groq.com/openai/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Expected: JSON response with available models.

---

## Configure Clawdbot

### Railway Setup

Add environment variable in Railway dashboard:

```
GROQ_API_KEY=gsk_your_api_key_here
```

### Local Setup

```bash
export GROQ_API_KEY="gsk_your_api_key_here"
```

---

## Groq Models Available

Clawdbot supports these Groq models:

### Recommended for Telegram Bot:

```json
"model": "groq/llama-3.3-70b-versatile"
```

**Best for:**
- High performance
- Fast responses
- High quota limits
- Production stability

### Alternative Models:

```json
// Faster, smaller model
"model": "groq/llama-3.1-8b-instant"

// More capable
"model": "groq/llama-3.1-70b-versatile"

// Mixtral model
"model": "groq/mixtral-8x7b-32768"
```

---

## Free Tier Limits

### Groq (Recommended)

- **Requests**: High rate limits (much better than Gemini)
- **Rate**: Generous rate limits for production use
- **Context**: 128k tokens
- **Output**: 8k tokens max
- **Cost**: **FREE!**
- **Stability**: More stable and reliable for production

### What This Means for Your Bot:

**Daily usage:**
- High throughput without quota issues
- Better reliability than Gemini free tier
- Suitable for production deployments

**If you need more:**
- Groq offers paid plans with even higher limits
- Or use multiple API keys (rotate)

---

## Configuration

### Option 1: Groq (Recommended - FREE!)

```json
{
  "agent": {
    "model": "groq/llama-3.3-70b-versatile"
  }
}
```

**Environment:**
```bash
GROQ_API_KEY=gsk_...
```

**Cost:** $0/month (free tier)

---

## Model Format

The model format in Clawdbot is: `groq/model-name`

Examples:
- `groq/llama-3.3-70b-versatile` ✅
- `groq/llama-3.1-70b-versatile` ✅
- `groq/llama-3.1-8b-instant` ✅
- `groq/mixtral-8x7b-32768` ✅

---

## Troubleshooting

### Bot not responding?

Check model name in `clawdbot-config.json`:

```json
"model": "groq/llama-3.3-70b-versatile"
```

Must be exactly this format!

---

## Cost Savings

### Telegram Bot Usage Estimate

**Assumptions:**
- 100 users
- 10 messages per user per day
- Average 1,000 tokens per conversation

**Groq Free Tier:**
- More than enough for this usage
- No quota issues
- Stable performance

---

## Quick Start

```bash
# Set in .env.local:
GROQ_API_KEY=gsk_...

# Config model:
"model": "groq/llama-3.3-70b-versatile"

# Deploy:
railway up
```

---

## Why Switch from Gemini?

- **Higher Quota Limits**: Groq provides much better free tier quotas
- **No Quota Issues**: Avoid 429 errors that plague Gemini free tier
- **Faster**: Groq's LPU technology provides ultra-fast inference
- **More Reliable**: Better stability for production deployments
- **Same Quality**: Llama 3.3 70B is comparable to Gemini models

---

## Migration from Gemini

If you're switching from Gemini:

1. Get Groq API key from https://console.groq.com/
2. Set `GROQ_API_KEY` in Railway (replace `GEMINI_API_KEY`)
3. Update model to `groq/llama-3.3-70b-versatile`
4. Redeploy

The bot will automatically use Groq instead of Gemini.

