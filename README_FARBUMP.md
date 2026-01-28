# 🤖 FarBump Telegram Bot

AI-powered Telegram bot untuk automated token swaps menggunakan Clawdbot, Privy authentication, dan FarBump API.

## 🌟 Features

- ✅ **Natural Language Swaps** - Chat seperti normal: "swap 0.1 ETH to USDC"
- 🔐 **Privy Authentication** - Secure smart account creation via Privy SDK
- 💰 **Balance Checking** - Real-time wallet balance monitoring
- 📊 **Transaction History** - Track all your swaps
- ⚙️ **Auto-Swap** - Schedule recurring swaps
- 🔔 **Smart Notifications** - Get notified for important events
- 🚀 **24/7 Uptime** - Deployed on Railway cloud

## 🎯 Quick Links

- **[Quick Start Guide](QUICK_START.md)** - Start dalam 5 menit
- **[Railway Deployment](RAILWAY_DEPLOYMENT.md)** - Deploy to production
- **[Backend API Spec](FARBUMP_BACKEND_API.md)** - API requirements untuk FarBump backend
- **[Integration Guide](FARBUMP_INTEGRATION.md)** - Detailed integration docs

## 📸 Screenshots

### Authentication Flow
```
User: /start
Bot: 🔐 Authentication Required
     [Login with Privy] 👈 Click here
     
→ User completes Privy auth in browser
→ Smart account automatically created
→ Ready to swap!
```

### Swap Flow
```
User: swap 0.1 ETH to USDC

Bot: 🔄 Swap Confirmation
     From: 0.1 ETH
     To: USDC (~$185)
     [✅ Confirm] [❌ Cancel]

User: [clicks Confirm]

Bot: ✅ Swap Successful!
     Received: 184.8 USDC
     TX: 0xabc123...
```

## 🏗️ Architecture

```
┌──────────────────────────────────────────────┐
│                                              │
│  Telegram Bot (Railway Cloud)                │
│  ┌────────────────────────────────────────┐ │
│  │  Clawdbot AI Agent                     │ │
│  │  - Natural language processing         │ │
│  │  - Intent recognition                  │ │
│  │  - Context management                  │ │
│  └─────────────┬──────────────────────────┘ │
│                │                              │
└────────────────┼──────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────┐
│  FarBump Backend                             │
│  ┌────────────────────────────────────────┐ │
│  │  Privy SDK Integration                 │ │
│  │  - User authentication                 │ │
│  │  - Smart account creation              │ │
│  │  - Session management                  │ │
│  └─────────────┬──────────────────────────┘ │
│                │                              │
│  ┌─────────────┴──────────────────────────┐ │
│  │  Swap Engine                           │ │
│  │  - Token swaps via Privy               │ │
│  │  - Balance tracking                    │ │
│  │  - Transaction history                 │ │
│  └────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

## 🚀 Getting Started

### Prerequisites

- Node.js 22+
- pnpm (or npm/yarn)
- Telegram bot token
- FarBump API credentials
- Anthropic/OpenAI API key

### Local Development

```bash
# 1. Install dependencies
pnpm install

# 2. Build project
pnpm build

# 3. Configure bot
cp .env.example .env
# Edit .env dengan credentials Anda

# 4. Start bot
pnpm clawdbot gateway run --port 18789 --verbose

# 5. Test di Telegram
# Cari bot Anda dan send /start
```

### Production Deployment (Railway)

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login dan initialize
railway login
railway init

# 3. Set environment variables
railway variables set TELEGRAM_BOT_TOKEN="..."
railway variables set FARBUMP_API_KEY="..."
railway variables set ANTHROPIC_API_KEY="..."

# 4. Deploy
railway up

# 5. Monitor
railway logs --follow
```

Detailed guide: [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md)

## 📁 Project Structure

```
moltbot-2026.1.24-2/
│
├── skills/farbump/              # FarBump integration
│   ├── SKILL.md                 # Skill documentation
│   ├── privy-auth.ts            # Privy authentication logic
│   ├── telegram-handlers.ts     # Bot command handlers
│   └── farbump-tools.ts         # FarBump API client
│
├── docs/                        # Documentation
│   ├── QUICK_START.md           # 5-minute setup guide
│   ├── RAILWAY_DEPLOYMENT.md    # Railway deployment guide
│   ├── FARBUMP_BACKEND_API.md   # Backend API requirements
│   └── FARBUMP_INTEGRATION.md   # Integration guide
│
├── src/                         # Clawdbot source code
│   ├── telegram/                # Telegram bot implementation
│   ├── gateway/                 # Gateway server
│   └── agents/                  # AI agent runtime
│
├── railway.json                 # Railway configuration
├── Procfile                     # Process file
├── .env.example                 # Environment template
└── package.json                 # Dependencies
```

## 🔑 Environment Variables

### Required

```bash
# Telegram
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHI...
TELEGRAM_BOT_USERNAME=farbump_bot

# FarBump
FARBUMP_API_URL=https://api.farbump.com
FARBUMP_API_KEY=your_api_key

# AI Model (choose one)
ANTHROPIC_API_KEY=sk-ant-...
# or
OPENAI_API_KEY=sk-...

# Environment
NODE_ENV=production
PORT=18789
```

### Optional (Recommended for Production)

```bash
# Session storage
REDIS_URL=redis://...

# Database
DATABASE_URL=postgresql://...

# Monitoring
LOG_LEVEL=info
```

## 🛠️ Bot Commands

### User Commands

- `/start` - Start bot dan authenticate
- `/balance` - Check wallet balance
- `/history` - View transaction history
- `/status` - Check authentication status
- `/logout` - Revoke authentication
- `/help` - Show help message

### Natural Language

Users dapat chat naturally:
- "swap 0.1 ETH to USDC"
- "what's my balance?"
- "show my recent transactions"
- "exchange 100 USDC for ETH"

## 🔒 Security

### Authentication
- **Privy SDK** - Industry-standard wallet authentication
- **Smart Accounts** - Non-custodial, user-controlled
- **JWT Tokens** - Secure API authentication
- **Session Management** - Auto-expire after 30 days

### Bot Security
- **Pairing Mode** - Users must be approved first
- **Rate Limiting** - Prevent abuse
- **Input Validation** - All inputs validated
- **Error Handling** - No sensitive data in error messages

### Best Practices
- ✅ Never commit API keys
- ✅ Use environment variables
- ✅ Enable 2FA on Railway
- ✅ Monitor logs regularly
- ✅ Keep dependencies updated

## 🧪 Testing

### Local Testing

```bash
# Run tests
pnpm test

# Test specific feature
pnpm test:unit

# Test with coverage
pnpm test:coverage
```

### Manual Testing Checklist

- [ ] `/start` shows authentication link
- [ ] Privy authentication completes successfully
- [ ] `/balance` returns correct balance
- [ ] Swap confirmation shows correct amounts
- [ ] Swap execution creates transaction
- [ ] Transaction history displays correctly
- [ ] `/logout` revokes session
- [ ] Error messages are user-friendly

## 📊 Monitoring

### Railway Dashboard
- View real-time logs
- Monitor resource usage
- Check deployment status
- Set up alerts

### Bot Analytics (Custom)
```typescript
// Track metrics in your code
analytics.track('swap_executed', {
  userId: telegramId,
  fromToken: 'ETH',
  toToken: 'USDC',
  amount: 0.1
});
```

## 🐛 Troubleshooting

### Common Issues

#### Bot not responding
```bash
# Check Railway logs
railway logs --tail 100

# Restart service
railway restart
```

#### Authentication failing
- Verify FARBUMP_API_URL is correct
- Check Privy webhook is configured
- Ensure backend endpoints are working

#### Swap not executing
- Check user has sufficient balance
- Verify FarBump API key is valid
- Check smart account has gas fees

More troubleshooting: [RAILWAY_DEPLOYMENT.md#troubleshooting](RAILWAY_DEPLOYMENT.md#troubleshooting)

## 💰 Cost Estimate

### Railway Hosting
- **Hobby**: $5/month (up to 100 users)
- **Pro**: $20/month (up to 1000 users)
- **Redis addon**: +$5-10/month

### API Costs
- **Anthropic API**: ~$0.015 per 1K tokens
- **FarBump API**: Based on swap volume
- **Privy**: Free tier available

**Total**: ~$10-30/month untuk start

## 🎓 Learning Resources

### Clawdbot
- [Official Docs](https://docs.clawd.bot)
- [GitHub](https://github.com/clawdbot/clawdbot)
- [Discord Community](https://discord.gg/clawd)

### Privy
- [Docs](https://docs.privy.io)
- [Quickstart](https://docs.privy.io/guide/quickstart)

### Railway
- [Docs](https://docs.railway.app)
- [Discord](https://discord.gg/railway)

### Telegram Bot API
- [Documentation](https://core.telegram.org/bots/api)
- [Best Practices](https://core.telegram.org/bots/best-practices)

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## 📝 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- **Clawdbot** - AI agent framework
- **Privy** - Authentication & smart accounts
- **Railway** - Cloud hosting
- **FarBump** - Swap infrastructure

## 📧 Support

### Issues & Questions
- GitHub Issues: [Open an issue]
- Telegram: @farbump_support
- Email: support@farbump.com

### Documentation
- [Quick Start](QUICK_START.md)
- [Railway Deployment](RAILWAY_DEPLOYMENT.md)
- [Backend API Spec](FARBUMP_BACKEND_API.md)
- [Integration Guide](FARBUMP_INTEGRATION.md)

---

## 🚀 Ready to Launch?

1. ✅ Read [QUICK_START.md](QUICK_START.md)
2. ✅ Follow [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md)
3. ✅ Implement backend endpoints from [FARBUMP_BACKEND_API.md](FARBUMP_BACKEND_API.md)
4. ✅ Test thoroughly
5. ✅ Deploy to Railway
6. ✅ Announce to users!

**Good luck! 🎉**

---

Made with ❤️ for the FarBump community
