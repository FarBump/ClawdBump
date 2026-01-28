# Railway Deployment Guide - FarBump Telegram Bot

## Prerequisites

- [ ] Railway account (https://railway.app)
- [ ] Telegram bot token dari @BotFather
- [ ] FarBump API URL dan API key
- [ ] Anthropic/OpenAI API key untuk AI model
- [ ] GitHub repository (optional, bisa deploy langsung)

## Deployment Steps

### 1. Prepare Repository

```bash
cd /path/to/moltbot-2026.1.24-2

# Initialize git if not already
git init
git add .
git commit -m "Initial commit: FarBump Telegram bot"

# Push to GitHub (optional)
git remote add origin https://github.com/yourusername/farbump-bot.git
git push -u origin main
```

### 2. Create Railway Project

**Option A: Deploy from GitHub**
1. Go to https://railway.app/new
2. Click "Deploy from GitHub repo"
3. Select your repository
4. Railway will auto-detect Node.js project

**Option B: Deploy using Railway CLI**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to new project
railway init

# Deploy
railway up
```

### 3. Configure Environment Variables

In Railway dashboard, go to Variables tab dan tambahkan:

#### Required Variables:
```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_BOT_USERNAME=farbump_bot

# FarBump API
FARBUMP_API_URL=https://api.farbump.com
FARBUMP_API_KEY=your_farbump_api_key

# AI Model (pilih salah satu)
ANTHROPIC_API_KEY=sk-ant-api03-...
# atau
OPENAI_API_KEY=sk-...

# Node Environment
NODE_ENV=production
PORT=18789
```

#### Optional but Recommended:
```bash
# Redis for session storage (Railway addon)
REDIS_URL=redis://default:password@redis.railway.internal:6379

# Monitoring
LOG_LEVEL=info
```

### 4. Add Railway Addons (Optional)

**Redis** (recommended untuk production):
1. In Railway dashboard, click "New"
2. Select "Database" → "Add Redis"
3. Redis URL akan otomatis ditambahkan ke environment variables

**PostgreSQL** (jika perlu persistent storage):
1. Click "New" → "Database" → "Add PostgreSQL"
2. DATABASE_URL akan otomatis ter-set

### 5. Configure Build Settings

Railway akan auto-detect, tapi bisa di-customize:

**Build Command:**
```bash
pnpm install && pnpm build
```

**Start Command:**
```bash
node dist/entry.js gateway run --bind 0.0.0.0 --port $PORT
```

Atau edit `railway.json` (sudah disediakan):
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

### 6. Deploy and Monitor

```bash
# Deploy via CLI
railway up

# Or push to GitHub (if connected)
git push origin main

# Watch logs
railway logs
```

### 7. Test the Bot

1. Open Telegram dan cari bot Anda (contoh: @farbump_bot)
2. Send `/start`
3. Bot should respond dengan authentication link
4. Complete authentication flow
5. Try swap command: "swap 0.1 ETH to USDC"

### 8. Custom Domain (Optional)

1. In Railway dashboard, go to Settings
2. Click "Networking" → "Public Networking"
3. Generate domain atau add custom domain
4. Useful untuk webhook mode (opsional)

---

## Configuration Files

### clawdbot.json (Production)

Create di root project atau Railway akan read dari `~/.clawdbot/`:

```json
{
  "agent": {
    "model": "anthropic/claude-opus-4-5",
    "workspace": "/app/.clawdbot/workspace"
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "textChunkLimit": 4000,
      "capabilities": {
        "inlineButtons": "allowlist"
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

---

## Monitoring & Maintenance

### View Logs
```bash
# Real-time logs
railway logs --follow

# Filter by level
railway logs --filter "error"
```

### Check Bot Status
```bash
# SSH into Railway container
railway shell

# Check gateway status
clawdbot channels status --probe
```

### Restart Service
In Railway dashboard:
- Click on service
- Click "..." menu
- Select "Restart"

Atau via CLI:
```bash
railway restart
```

---

## Scaling & Performance

### Railway Plans:
- **Hobby**: $5/month, 512MB RAM, 1GB storage
  - Good for: <100 active users
- **Pro**: $20/month, 8GB RAM, 100GB storage
  - Good for: <1000 active users
- **Team**: Custom pricing
  - Good for: Production scale

### Optimize Performance:

1. **Enable Redis** untuk session storage
2. **Increase timeout** di config jika needed
3. **Add health checks**
4. **Monitor memory usage** in Railway dashboard

---

## Troubleshooting

### Bot Not Responding

**Check logs:**
```bash
railway logs --tail 100
```

**Common issues:**
- ❌ `TELEGRAM_BOT_TOKEN` not set → Check environment variables
- ❌ `FARBUMP_API_KEY` invalid → Verify API key
- ❌ Port binding error → Railway auto-assigns PORT, should work
- ❌ Build failed → Check `pnpm install` logs

### High Memory Usage

```bash
# Check current usage in Railway dashboard
# If > 80%, consider:
# 1. Upgrade plan
# 2. Optimize config
# 3. Clear old sessions
```

### API Timeouts

```json
// Increase timeout in clawdbot.json
{
  "channels": {
    "telegram": {
      "timeoutSeconds": 500
    }
  }
}
```

### Database Connection Issues

```bash
# If using PostgreSQL, check connection
railway variables

# Verify DATABASE_URL is set
# Format: postgresql://user:pass@host:port/db
```

---

## CI/CD Setup (Advanced)

### Automatic Deployment on Git Push

Railway akan otomatis deploy ketika push ke `main` branch.

**GitHub Actions example** (`.github/workflows/deploy.yml`):
```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Railway CLI
        run: npm install -g @railway/cli
      
      - name: Deploy to Railway
        run: railway up --ci
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

---

## Health Checks

Add health check endpoint (optional):

```typescript
// In your bot code
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});
```

Configure in Railway:
- Settings → Health Checks
- Path: `/health`
- Interval: 60s

---

## Backup & Disaster Recovery

### Session Data Backup
```bash
# If using Redis, setup periodic backup
railway run -- redis-cli --rdb /backups/dump.rdb
```

### Config Backup
```bash
# Backup environment variables
railway variables > .env.backup

# Store securely (NOT in git!)
```

### Rollback Deployment
```bash
# View deployment history
railway deployments

# Rollback to previous
railway rollback <deployment-id>
```

---

## Cost Optimization

### Tips untuk reduce costs:

1. **Use Hobby plan** untuk development/testing
2. **Upgrade to Pro** only when needed
3. **Monitor usage** di Railway dashboard
4. **Clean up old deployments**
5. **Use Redis** instead of database untuk sessions (cheaper)

### Estimated Monthly Costs:

| Users | RAM | Storage | Plan | Cost |
|-------|-----|---------|------|------|
| 1-50  | 512MB | 1GB | Hobby | $5 |
| 50-500 | 2GB | 10GB | Pro | $20 |
| 500-2000 | 4GB | 50GB | Pro | $40 |
| 2000+ | 8GB+ | 100GB+ | Team | Custom |

Plus:
- Redis addon: ~$5-10/month
- Postgres addon: ~$5-15/month (if needed)
- API calls to FarBump: Based on usage

---

## Production Checklist

Before going live:

- [ ] All environment variables set
- [ ] Telegram bot tested end-to-end
- [ ] FarBump API endpoints working
- [ ] Privy authentication flow tested
- [ ] Error handling in place
- [ ] Logging configured
- [ ] Redis enabled for sessions (recommended)
- [ ] Health checks configured
- [ ] Monitoring alerts setup
- [ ] Backup strategy defined
- [ ] Rate limiting configured (in FarBump API)
- [ ] Terms of service ready
- [ ] Support channel created

---

## Support

**Railway:**
- Docs: https://docs.railway.app
- Discord: https://discord.gg/railway
- Status: https://railway.app/status

**Clawdbot:**
- GitHub: https://github.com/clawdbot/clawdbot
- Docs: https://docs.clawd.bot

**FarBump:**
- Support: @farbump_support (Telegram)
- Documentation: [Your docs]

---

## Next Steps

1. ✅ Deploy to Railway
2. ✅ Test authentication flow
3. ✅ Test swap functionality
4. 📊 Setup monitoring & alerts
5. 👥 Invite beta testers
6. 📈 Scale based on usage
7. 🚀 Launch to public!
