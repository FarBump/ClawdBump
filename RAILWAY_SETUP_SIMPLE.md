# ClawdBump Railway Deployment - Simple Guide

## ✅ **New Approach: Install from npm (Proven!)**

Based on successful [clawdbot-railway-template](https://github.com/vignesh07/clawdbot-railway-template) with **1387+ active deployments**.

### **Key Changes:**
- ✅ Install `clawdbot@latest` from npm (not build from source)
- ✅ **Much faster** Docker build (~3-5 min vs 15+ min)
- ✅ **More reliable** - proven approach
- ✅ Smaller Docker image
- ✅ Railway Volume for persistent storage

---

## 📋 **Railway Setup Steps**

### **Step 1: Create Service from GitHub** (2 min)

1. Login https://railway.app
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Choose: **FarBump/ClawdBump**
5. Railway will auto-detect Dockerfile

### **Step 2: Add Railway Volume** (1 min)

⚠️ **IMPORTANT**: Volume needed untuk persistent storage!

1. In Railway service, click **"Settings"** tab
2. Scroll to **"Volumes"**
3. Click **"+ New Volume"**
4. Mount path: `/data`
5. Click **"Add"**

### **Step 3: Set Environment Variables** (2 min)

Go to **"Variables"** tab:

```
TELEGRAM_BOT_TOKEN = ••••••••••
GOOGLE_API_KEY = ••••••••••
NODE_ENV = production
LOG_LEVEL = info
```

**Note**: Railway auto-injects `PORT` variable.

### **Step 4: Deploy!** (3-5 min)

Railway will auto-deploy after volume + variables are set.

**Monitor**: Deployments tab → View logs

**Expected logs:**
```
✓ Pulling node:20-slim
✓ Installing clawdbot@latest from npm
✓ Setting up directories
✓ Container starting
✓ Gateway listening on port $PORT
✓ Deployment successful
```

---

## 🎯 **What This Does:**

```dockerfile
FROM node:20-slim

# Install clawdbot globally from npm
RUN npm install -g clawdbot@latest

# Use Railway Volume for persistent data
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV CLAWDBOT_WORKSPACE_DIR=/data/workspace

# Start gateway
CMD clawdbot gateway run --port ${PORT} --bind 0.0.0.0
```

**Benefits:**
- ✅ No complex build process
- ✅ Uses stable npm release
- ✅ Fast builds (< 5 minutes)
- ✅ Proven approach (1387+ deployments)
- ✅ Easy to update (just redeploy)

---

## 📊 **File Structure:**

```
Railway Container:
├── /usr/local/lib/node_modules/clawdbot/  (npm package)
└── /data/  (Railway Volume - PERSISTENT)
    ├── .clawdbot/  (state, sessions, credentials)
    │   ├── sessions/
    │   ├── credentials/
    │   └── moltbot.json  (config)
    └── workspace/  (agent workspace)
```

**Important**: `/data` survives redeploys! Config and sessions persist.

---

## ⚙️ **Configuration:**

Bot akan auto-create config di `/data/.clawdbot/moltbot.json` saat first run.

Environment variables akan override config file:
- `TELEGRAM_BOT_TOKEN` → Telegram bot
- `GOOGLE_API_KEY` → Gemini API
- `NODE_ENV` → production
- `PORT` → Railway assigns this

---

## 🔍 **Troubleshooting:**

### **Build Errors:**

**Check logs di Railway → Deployments → Build logs**

Common issues:
- ❌ No volume → Add `/data` volume
- ❌ npm install timeout → Redeploy (Railway servers busy)
- ❌ Node version → Already handled (node:20-slim)

### **Runtime Errors:**

**Check logs di Railway → Deployments → Deploy logs**

Common issues:
- ❌ Bot not responding → Check `TELEGRAM_BOT_TOKEN` is set
- ❌ AI errors → Check `GOOGLE_API_KEY` is set
- ❌ Port binding → Railway auto-injects PORT (should work)

### **Test Bot:**

1. Open Telegram
2. Search your bot
3. Send `/start`
4. Send message: "Hello!"
5. Bot should respond with Gemini AI

---

## 📈 **Railway Volume Benefits:**

With Railway Volume at `/data`:

✅ **Sessions persist** across deploys  
✅ **Credentials saved** (no re-login)  
✅ **Config survives** redeploys  
✅ **Agent workspace** preserved  
✅ **Easy backups** (download volume)  
✅ **Migration ready** (export and move)

---

## 💰 **Cost Estimate:**

**Railway Hobby Plan**: $5/month
- 512MB RAM (enough for bot)
- 1GB storage
- Good for personal use + testing

**Railway Pro Plan**: $20/month
- 8GB RAM
- 100GB storage
- Good for production + multiple users

**Volume**: ~$0.25/GB/month (usually < $1/month)

**Total**: ~$5-6/month for personal bot

---

## ✅ **Success Checklist:**

- [ ] Railway service created from GitHub
- [ ] Railway Volume added at `/data`
- [ ] Environment variables set (TELEGRAM_BOT_TOKEN, GOOGLE_API_KEY)
- [ ] Deploy triggered and completed
- [ ] Logs show "Gateway listening"
- [ ] Bot responds in Telegram

---

## 🚀 **Next Steps After Success:**

1. **Test bot** di Telegram → Send messages
2. **Monitor logs** → Railway Deployments tab
3. **Check metrics** → Railway Metrics tab
4. **Setup backups** (optional) → Download volume periodically

---

## 📖 **Template Credit:**

Approach berdasarkan:
- [clawdbot-railway-template](https://github.com/vignesh07/clawdbot-railway-template) by @vignesh07
- [Railway Template](https://railway.com/deploy/clawdbot-railway-template)
- **1387+ active deployments** ← Proven to work!

---

## 🎉 **You're Ready!**

Semua konfigurasi sudah di-push ke GitHub. Railway akan:

1. ✅ Pull latest code
2. ✅ Build Docker image (npm install approach)
3. ✅ Mount `/data` volume
4. ✅ Load environment variables
5. ✅ Start gateway
6. ✅ Bot online! 🤖

**Repository**: https://github.com/FarBump/ClawdBump  
**Railway**: https://railway.app

Deploy sekarang! 🚀

