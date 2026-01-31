# ClawdBot - Quick Start Railway Deployment

## 🎯 Ringkasan Cepat

### ✅ Yang Sudah Siap:
1. **Gemini API Key**: Sudah dikonfigurasi di `clawdbot-config.json`
2. **Telegram Bot Token**: Sudah dikonfigurasi
3. **Build Config**: `railway.json` sudah optimal
4. **Gateway Config**: Sudah set untuk Railway deployment

### ⚠️ SECURITY FIRST!

**IMPORTANT**: Never commit credentials to git!  
See `SECURITY_SETUP.md` for detailed security guide.

### 📝 Yang Perlu Dilakukan:

#### 1. Setup Credentials Securely (5 menit)

```bash
# Copy example config
cp clawdbot-config.example.json clawdbot-config.json

# Edit clawdbot-config.json and add your credentials
# This file is gitignored - safe to add keys here

# OR use environment variables (recommended for Railway)
```

**Get your credentials:**
- Telegram: @BotFather → `/newbot` → copy token
- Gemini: https://aistudio.google.com/apikey → Create API Key

#### 2. Buat GitHub Repository Baru (5 menit)
```bash
# Di GitHub:
# - Buat repo baru (contoh: clawdbot-telegram)
# - Private atau Public (terserah)

# Di terminal:
cd "c:\moltbot-2026.1.24 2"
git init
git remote add origin https://github.com/YOUR_USERNAME/clawdbot-telegram.git
git add .
git commit -m "Initial commit: ClawdBot with Gemini"
git push -u origin main
```

#### 2. Deploy ke Railway (10 menit)
1. Login https://railway.app
2. Pilih/buat project (bisa sama dengan FarBump)
3. Klik "New" → "GitHub Repo"
4. Pilih repository ClawdBot
5. Railway akan auto-detect dan start build

#### 3. Set Environment Variables di Railway
Go to service → "Variables" tab → Add:
```
TELEGRAM_BOT_TOKEN = 8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y
GOOGLE_API_KEY = AIzaSyDTUY1VUF0GnY9EG784oxEP3LNO5ZKpVEY
NODE_ENV = production
LOG_LEVEL = info
```

#### 4. Test Bot (2 menit)
1. Buka Telegram
2. Cari bot Anda
3. Send `/start`
4. Chat dengan bot!

---

## 🔍 Jawaban Pertanyaan Anda:

### Q: Apakah tidak masalah 1 GitHub tapi repository berbeda?
**A: TIDAK MASALAH! Ini justru best practice!**
- ✅ 1 akun GitHub → banyak repository ✓
- ✅ Setiap project = 1 repository
- ✅ Lebih terorganisir dan mudah di-manage

### Q: Railway yang sama tapi berbeda service?
**A: YA, ini cara yang BENAR!**
```
Railway Project Anda
├── Service 1: FarBump Bot
├── Service 2: ClawdBot (yang ini!)
└── Service 3: Redis (optional, bisa shared)
```

Keuntungan:
- ✅ Billing terpusat
- ✅ Easy management
- ✅ Bisa share resources
- ✅ Environment variables terpisah

---

## 📊 Cost Estimate

**Railway Hobby Plan**: $5/month
- Cukup untuk run 2 services (FarBump + ClawdBot)
- 512MB RAM each
- Good untuk testing & low-medium traffic

**Gemini API**: Free tier available
- Check quota di Google AI Studio

**Telegram**: Gratis selamanya

**Total**: ~$5-10/month (tergantung usage)

---

## 🚀 Architecture

```
┌─────────────────────────────────────┐
│      Railway Project (Anda)         │
├─────────────────────────────────────┤
│                                     │
│  [Service: FarBump]                 │
│   - Port: 18789                     │
│   - Repo: farbump-bot               │
│                                     │
│  [Service: ClawdBot] ← NEW!         │
│   - Port: 18789                     │
│   - Repo: clawdbot-telegram         │
│   - Model: Gemini 1.5 Flash         │
│                                     │
│  [Service: Redis] (Optional)        │
│   - Shared storage                  │
│                                     │
└─────────────────────────────────────┘
```

---

## 📞 Monitoring

**Railway Dashboard**:
- View logs: Service → Deployments → Latest
- Check metrics: CPU, Memory, Network
- Restart: Service → Settings → Restart

**Telegram**:
- Test bot langsung via chat
- Check response time
- Verify AI responses

---

## ✅ Checklist

- [x] Gemini API key configured
- [x] Telegram bot token configured
- [x] Build config ready
- [ ] **GitHub repo created** ← DO THIS
- [ ] **Code pushed to GitHub** ← DO THIS
- [ ] **Railway service created** ← DO THIS
- [ ] **Environment variables set** ← DO THIS
- [ ] **Bot tested in Telegram** ← DO THIS

---

## 📖 Full Guide

Lihat `CLAWDBOT_RAILWAY_SETUP.md` untuk:
- Detailed step-by-step
- Troubleshooting tips
- Advanced configuration
- Monitoring & maintenance

---

## 🎉 Siap Deploy!

Semua konfigurasi sudah selesai. Tinggal:
1. Push ke GitHub
2. Connect ke Railway
3. Set env vars
4. Deploy! 🚀

Total waktu: ~20 menit

