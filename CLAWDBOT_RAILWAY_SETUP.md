# ClawdBot Railway Deployment - Setup Guide

## ✅ Pertanyaan Anda

### 1. Apakah boleh menggunakan 1 GitHub tapi repository berbeda?
**YA, sangat direkomendasikan!** 

Ini adalah best practice:
- ✅ 1 akun GitHub → Multiple repositories ✓
- ✅ Contoh:
  - `yourusername/farbump-bot` (untuk FarBump)
  - `yourusername/clawdbot` (untuk ClawdBot ini)
- ✅ Setiap project punya repository sendiri → lebih terorganisir
- ✅ Deployment Railway bisa connect ke repository mana saja

### 2. Menggunakan Railway yang sama tapi berbeda service?
**YA, ini cara yang benar!**

Dalam 1 Railway account/project:
- ✅ Service 1: FarBump Bot
- ✅ Service 2: ClawdBot (bot ini)
- ✅ (Optional) Service 3: Redis (shared atau terpisah)
- ✅ (Optional) Service 4: PostgreSQL (jika perlu)

Keuntungan:
- Billing terpusat
- Easier management
- Bisa share resources (Redis, DB)
- Environment variables terpisah per service

---

## 🔒 Security First!

⚠️ **NEVER commit credentials to git!**

See `SECURITY_SETUP.md` for complete security guide.

---

## 📋 Langkah Persiapan

### Step 1: Environment Variables untuk Railway

Anda perlu set di Railway dashboard untuk service ClawdBot:

```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y

# Gemini API (SUDAH DIKONFIGURASI)
GOOGLE_API_KEY=AIzaSyDTUY1VUF0GnY9EG784oxEP3LNO5ZKpVEY

# Node Environment
NODE_ENV=production
PORT=18789

# Gateway Mode
CLAWDBOT_GATEWAY_MODE=local
CLAWDBOT_GATEWAY_BIND=0.0.0.0
CLAWDBOT_GATEWAY_PORT=18789

# Log Level (optional)
LOG_LEVEL=info
```

### Step 2: Repository GitHub (Baru)

Buat repository baru untuk ClawdBot:

```bash
# 1. Create repo di GitHub
# Nama contoh: clawdbot-telegram
# Visibility: Private atau Public (terserah Anda)

# 2. Di folder project ini:
cd "c:\moltbot-2026.1.24 2"

# 3. Initialize git jika belum
git init

# 4. Add remote
git remote add origin https://github.com/yourusername/clawdbot-telegram.git

# 5. Commit semua files
git add .
git commit -m "Initial commit: ClawdBot with Gemini integration"

# 6. Push ke GitHub
git branch -M main
git push -u origin main
```

### Step 3: Railway Service Setup

#### A. Via Railway Dashboard:

1. **Login** ke https://railway.app
2. **Pilih project** yang sama dengan FarBump (atau buat baru)
3. **Click "New"** → **"GitHub Repo"**
4. **Pilih repository** ClawdBot yang baru dibuat
5. **Railway auto-detect** Node.js project

#### B. Configure Build Settings:

Railway akan gunakan `railway.json` yang sudah ada:
```json
{
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "pnpm install && pnpm build"
  },
  "deploy": {
    "startCommand": "node dist/entry.js gateway run --port ${PORT:-18789}",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### Step 4: Set Environment Variables di Railway

1. Klik service ClawdBot di Railway
2. Go to **"Variables"** tab
3. Add semua variables dari Step 1 di atas
4. **Save** → Railway akan auto-redeploy

### Step 5: Deploy & Test

```bash
# Railway akan auto-deploy setelah:
# 1. Connect repository ✓
# 2. Set environment variables ✓

# Monitor deployment:
# 1. Check "Deployments" tab di Railway
# 2. View logs real-time
# 3. Wait for "Success" status
```

### Step 6: Test Bot di Telegram

1. Buka Telegram
2. Search bot Anda (cek username di @BotFather)
3. Send `/start`
4. Bot should respond!

---

## 🔧 Configuration Files Ready

### ✅ clawdbot-config.json (UPDATED)
```json
{
  "agent": {
    "model": "google/gemini-2.0-flash-exp",
    "workspace": "~/.clawdbot/workspace"
  },
  "providers": {
    "google": {
      "apiKey": "AIzaSyDTUY1VUF0GnY9EG784oxEP3LNO5ZKpVEY"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y",
      "dmPolicy": "open",
      "allowFrom": ["*"],
      "textChunkLimit": 4000,
      "capabilities": {
        "inlineButtons": "all"
      }
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "0.0.0.0",
    "port": 18789
  }
}
```

### ✅ railway.json (ALREADY EXISTS)
Sudah optimal untuk deployment!

### ✅ package.json (CHECK)
Pastikan dependencies sudah lengkap (should be OK).

---

## 📊 Railway Architecture

```
Railway Project (Your Account)
├── Service 1: FarBump Bot
│   ├── GitHub: yourusername/farbump-bot
│   ├── Env vars: FARBUMP_*, TELEGRAM_*, ANTHROPIC_*
│   └── Port: 18789
│
├── Service 2: ClawdBot (NEW!)
│   ├── GitHub: yourusername/clawdbot-telegram
│   ├── Env vars: TELEGRAM_*, GOOGLE_API_KEY
│   └── Port: 18789
│
└── (Optional) Service 3: Redis
    └── Shared atau terpisah untuk each service
```

---

## 🚀 Deployment Checklist

- [x] Gemini API key dikonfigurasi di `clawdbot-config.json`
- [x] Telegram bot token sudah ada
- [x] `railway.json` build config ready
- [ ] Buat repository GitHub baru untuk ClawdBot
- [ ] Push code ke GitHub
- [ ] Connect repository ke Railway (new service)
- [ ] Set environment variables di Railway
- [ ] Deploy & wait for success
- [ ] Test bot di Telegram dengan `/start`
- [ ] Test AI responses (chat dengan bot)
- [ ] Monitor logs untuk errors

---

## 🔍 Monitoring & Troubleshooting

### View Logs di Railway:
1. Click service "ClawdBot"
2. Go to "Deployments" tab
3. Click latest deployment
4. View real-time logs

### Common Issues:

#### ❌ "Bot not responding"
```bash
# Check:
1. TELEGRAM_BOT_TOKEN is correct
2. Bot is started (@BotFather)
3. Service is running (Railway dashboard)
4. Logs show no errors
```

#### ❌ "API key invalid"
```bash
# Check:
1. GOOGLE_API_KEY matches your Gemini key
2. API key has correct permissions
3. Billing enabled on Google Cloud (if required)
```

#### ❌ "Build failed"
```bash
# Check:
1. pnpm-lock.yaml exists
2. package.json dependencies are valid
3. Railway build logs for specific error
```

---

## 💰 Cost Estimate

### Railway Costs:
- **Hobby Plan**: $5/month
  - 512MB RAM, 1GB storage
  - Good for: testing, low traffic
  
- **Pro Plan**: $20/month
  - 8GB RAM, 100GB storage
  - Good for: production, medium traffic

### With 2 Services (FarBump + ClawdBot):
- Both dapat run di Hobby plan ($5 total)
- Jika traffic tinggi, upgrade ke Pro ($20)

### API Costs:
- **Gemini API**: Free tier available
  - Check: https://ai.google.dev/pricing
- **Telegram**: Free (no API costs)

---

## 📞 Support

**Railway:**
- Dashboard: https://railway.app
- Docs: https://docs.railway.app
- Discord: https://discord.gg/railway

**Gemini API:**
- Console: https://makersuite.google.com/app/apikey
- Docs: https://ai.google.dev/docs

**Telegram Bots:**
- @BotFather untuk manage bot
- Docs: https://core.telegram.org/bots/api

---

## ✅ Ready to Deploy!

Semua persiapan sudah selesai:
1. ✅ Gemini API key configured
2. ✅ Telegram bot token configured
3. ✅ Build config ready (`railway.json`)
4. ✅ Config file ready (`clawdbot-config.json`)

**Next Steps:**
1. Buat repository GitHub baru
2. Push code
3. Connect ke Railway
4. Deploy! 🚀

Setelah deploy, test dengan chat ke bot Anda di Telegram!

