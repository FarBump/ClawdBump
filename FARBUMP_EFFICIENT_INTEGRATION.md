# FarBump + Telegram Bot - Efficient Integration Plan

## 🔍 What FarBump Already Has

Setelah analisis repo [FarBump/FarBump](https://github.com/FarBump/FarBump), infrastruktur yang **sudah ada**:

### ✅ Backend Infrastructure (Next.js + Supabase)
- **Framework**: Next.js 16 dengan TypeScript
- **Authentication**: Privy SDK (`@privy-io/react-auth`)
- **Database**: Supabase dengan schema lengkap:
  - `user_bot_wallets` - Store 5 bot wallets per user
  - `bot_sessions` - Track active bumping sessions
  - `bot_logs` - Activity logging
- **Smart Accounts**: CDP SDK (`@coinbase/cdp-sdk`) dengan Paymaster
- **Deployment**: Railway & Vercel ready

### ✅ API Endpoints (Next.js API Routes)
Berdasarkan `AUTOMATED-BUMPING-GUIDE.md`, endpoint yang sudah ada:

```
POST /api/bot/mass-fund          - Fund 5 bot wallets
POST /api/bot/continuous-swap    - Start continuous bumping loop
POST /api/bot/execute-swap       - Execute single swap
GET  /api/bot/status             - Get current bot status
POST /api/bot/wallets            - Create/manage bot wallets
```

### ✅ Bumping System Features
- **5 Bot Wallets** - Auto-generated dengan CDP SDK
- **Round-Robin Swapping** - Rotate through wallets
- **Gasless Transactions** - Coinbase Paymaster integration
- **Micro-transactions** - Support $0.01 minimum
- **Real-time Logs** - Live activity tracking via Supabase
- **Auto-stop** - When all wallets depleted

### ✅ Dependencies
```json
{
  "@privy-io/react-auth": "^3.10.0",
  "@coinbase/cdp-sdk": "^1.43.0",
  "@supabase/supabase-js": "^2.89.0",
  "viem": "^2.43.3",
  "wagmi": "^3.1.3",
  "ethers": "^6.13.0"
}
```

---

## ❌ What We DON'T Need to Build

**Yang TIDAK perlu dibuat lagi:**
1. ❌ Backend API endpoints (sudah ada!)
2. ❌ Privy authentication backend (sudah ada!)
3. ❌ Smart account creation logic (sudah ada!)
4. ❌ Database schema (sudah ada!)
5. ❌ Swap execution logic (sudah ada!)
6. ❌ Bot wallet management (sudah ada!)
7. ❌ Paymaster integration (sudah ada!)

---

## ✅ What We NEED to Build

**Yang perlu dibuat:**
1. ✅ **Telegram Bot Interface** - Clawdbot sebagai frontend
2. ✅ **Telegram Authentication Bridge** - Link Telegram ID ke Privy Smart Account
3. ✅ **API Client** - Call existing FarBump API endpoints
4. ✅ **Simple Auth Middleware** - Verify user before API calls

---

## 🎯 Efficient Architecture

```
┌─────────────────────────────────────────────────────────┐
│               Telegram User                             │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│        Clawdbot (Telegram Bot - Railway)                │
│  ┌───────────────────────────────────────────────────┐  │
│  │  - Receive Telegram messages                      │  │
│  │  - Parse user intent                              │  │
│  │  - Handle /start, /bump, /status commands        │  │
│  └──────────────────┬────────────────────────────────┘  │
└────────────────────┼────────────────────────────────────┘
                     │
                     ▼ HTTP API Calls
┌─────────────────────────────────────────────────────────┐
│     FarBump Backend (Next.js - Railway/Vercel)          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Existing API Routes:                             │  │
│  │  - POST /api/bot/mass-fund                        │  │
│  │  - POST /api/bot/continuous-swap                  │  │
│  │  - GET  /api/bot/status                           │  │
│  │  - POST /api/bot/wallets                          │  │
│  └──────────────────┬────────────────────────────────┘  │
└────────────────────┼────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Supabase Database                          │
│  - user_bot_wallets                                     │
│  - bot_sessions                                         │
│  - bot_logs                                             │
│  - telegram_users (NEW - simple mapping table)         │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Implementation Plan (Simplified)

### Phase 1: Telegram Authentication Bridge (1 hour)

**Add simple table to Supabase:**

```sql
-- telegram_users table (tambahkan ke existing database)
CREATE TABLE IF NOT EXISTS telegram_users (
  id BIGSERIAL PRIMARY KEY,
  telegram_id BIGINT NOT NULL UNIQUE,
  telegram_username TEXT,
  smart_account_address TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_telegram_users_telegram_id ON telegram_users(telegram_id);
CREATE INDEX idx_telegram_users_smart_account ON telegram_users(smart_account_address);
```

**Create single auth endpoint di FarBump:**

```typescript
// app/api/telegram/auth/route.ts (NEW - single endpoint)
export async function POST(req: Request) {
  const { telegram_id, telegram_username, smart_account_address } = await req.json()
  
  // Save mapping
  const { data, error } = await supabase
    .from('telegram_users')
    .upsert({
      telegram_id,
      telegram_username,
      smart_account_address
    })
    .select()
    .single()
  
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  
  return NextResponse.json({ success: true, data })
}
```

### Phase 2: Clawdbot Telegram Handler (2 hours)

**Single file: `skills/farbump/telegram-bot.ts`**

```typescript
import { PrivyClient } from '@privy-io/server-auth'

// Initialize Privy server client
const privyClient = new PrivyClient(
  process.env.PRIVY_APP_ID!,
  process.env.PRIVY_APP_SECRET!
)

interface TelegramUser {
  id: number
  username?: string
}

/**
 * Handle /start - Create Privy link
 */
export async function handleStart(telegramUser: TelegramUser) {
  // Generate Privy auth link for Telegram user
  const authUrl = `${process.env.FARBUMP_WEB_URL}/auth/telegram?tg_id=${telegramUser.id}`
  
  return {
    message: `🔐 Welcome to FarBump!
    
To get started, authenticate your wallet:
👉 ${authUrl}

After connecting, your smart account will be linked to this Telegram account.`,
    buttons: {
      inline_keyboard: [[
        { text: '🔑 Connect Wallet', url: authUrl }
      ]]
    }
  }
}

/**
 * Check if user authenticated
 */
async function getSmartAccount(telegramId: number): Promise<string | null> {
  const response = await fetch(
    `${process.env.FARBUMP_API_URL}/api/telegram/auth?telegram_id=${telegramId}`
  )
  
  if (!response.ok) return null
  
  const data = await response.json()
  return data.smart_account_address || null
}

/**
 * Handle /bump - Start bumping
 */
export async function handleBump(telegramUser: TelegramUser, tokenAddress: string) {
  // Get smart account
  const smartAccount = await getSmartAccount(telegramUser.id)
  if (!smartAccount) {
    return {
      message: '❌ Please authenticate first using /start'
    }
  }
  
  // Call existing FarBump API
  const response = await fetch(
    `${process.env.FARBUMP_API_URL}/api/bot/continuous-swap`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userAddress: smartAccount,
        tokenAddress,
        amountUsd: 0.01,
        intervalSeconds: 60
      })
    }
  )
  
  const result = await response.json()
  
  if (!response.ok) {
    return {
      message: `❌ Failed to start bumping: ${result.error}`
    }
  }
  
  return {
    message: `✅ Bumping started!
    
Token: ${tokenAddress}
Amount: $0.01 per bump
Interval: 60 seconds

Use /status to check progress.`
  }
}

/**
 * Handle /status - Check bot status
 */
export async function handleStatus(telegramUser: TelegramUser) {
  const smartAccount = await getSmartAccount(telegramUser.id)
  if (!smartAccount) {
    return { message: '❌ Please authenticate first using /start' }
  }
  
  // Call existing FarBump API
  const response = await fetch(
    `${process.env.FARBUMP_API_URL}/api/bot/status?userAddress=${smartAccount}`
  )
  
  const status = await response.json()
  
  if (!response.ok) {
    return { message: '❌ Failed to fetch status' }
  }
  
  return {
    message: `📊 Bot Status:
    
Session: ${status.status}
Current Wallet: Bot #${status.currentWallet}
Swaps Completed: ${status.swapsCompleted}
Balance: ${status.totalBalance} ETH

View details: ${process.env.FARBUMP_WEB_URL}/dashboard`
  }
}

/**
 * Handle /stop - Stop bumping
 */
export async function handleStop(telegramUser: TelegramUser) {
  const smartAccount = await getSmartAccount(telegramUser.id)
  if (!smartAccount) {
    return { message: '❌ Please authenticate first using /start' }
  }
  
  const response = await fetch(
    `${process.env.FARBUMP_API_URL}/api/bot/stop`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userAddress: smartAccount })
    }
  )
  
  if (!response.ok) {
    return { message: '❌ Failed to stop bumping' }
  }
  
  return { message: '✅ Bumping stopped successfully!' }
}

// Export handlers
export const FarBumpTelegramBot = {
  handleStart,
  handleBump,
  handleStatus,
  handleStop,
  getSmartAccount
}
```

### Phase 3: Web Authentication Page (1 hour)

**Add to FarBump: `app/auth/telegram/page.tsx`**

```typescript
'use client'

import { usePrivy } from '@privy-io/react-auth'
import { useSearchParams } from 'next/navigation'

export default function TelegramAuthPage() {
  const { ready, authenticated, user, login } = usePrivy()
  const searchParams = useSearchParams()
  const telegramId = searchParams.get('tg_id')
  
  // Auto-trigger Privy login
  useEffect(() => {
    if (ready && !authenticated) {
      login()
    }
  }, [ready, authenticated])
  
  // After login, save mapping
  useEffect(() => {
    if (authenticated && user?.wallet?.address && telegramId) {
      fetch('/api/telegram/auth', {
        method: 'POST',
        body: JSON.stringify({
          telegram_id: parseInt(telegramId),
          smart_account_address: user.wallet.address
        })
      }).then(() => {
        // Redirect back to Telegram
        window.location.href = `https://t.me/farbump_bot?start=auth_success`
      })
    }
  }, [authenticated, user, telegramId])
  
  return (
    <div className="container">
      <h1>Connecting your wallet to Telegram...</h1>
      {!ready && <p>Loading Privy...</p>}
      {!authenticated && <p>Please login to continue</p>}
      {authenticated && <p>✅ Linking accounts...</p>}
    </div>
  )
}
```

### Phase 4: Deploy Clawdbot (30 min)

**Minimal config `~/.clawdbot/clawdbot.json`:**

```json
{
  "agent": {
    "model": "anthropic/claude-opus-4-5"
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  }
}
```

**Environment variables Railway:**

```bash
# Telegram
TELEGRAM_BOT_TOKEN=your_bot_token

# FarBump API
FARBUMP_API_URL=https://farbump.vercel.app
FARBUMP_WEB_URL=https://farbump.vercel.app

# AI Model
ANTHROPIC_API_KEY=your_key
```

**Deploy:**

```bash
railway init
railway variables set TELEGRAM_BOT_TOKEN="..."
railway variables set FARBUMP_API_URL="https://farbump.vercel.app"
railway up
```

---

## 🎯 User Flow (Simplified)

```
1. User: /start di Telegram
   ↓
2. Bot: "Connect Wallet" button dengan link
   ↓
3. User: Click link → Opens farbump.vercel.app/auth/telegram?tg_id=123
   ↓
4. FarBump: Trigger Privy login popup
   ↓
5. User: Login via Privy (email/wallet/social)
   ↓
6. FarBump: Save telegram_id → smart_account_address mapping
   ↓
7. FarBump: Redirect ke t.me/farbump_bot?start=auth_success
   ↓
8. Bot: "✅ Connected! Use /bump to start"
   ↓
9. User: /bump 0x123abc
   ↓
10. Bot: Call POST /api/bot/continuous-swap
   ↓
11. FarBump: Execute bumping via existing system
   ↓
12. Bot: Poll /api/bot/status untuk updates
```

---

## 📊 Comparison: Old vs New Approach

| Aspect | Old Approach (My First Plan) | New Approach (Efficient) |
|--------|------------------------------|--------------------------|
| Backend API | ❌ Build from scratch | ✅ Use existing FarBump API |
| Auth System | ❌ Custom Privy integration | ✅ Reuse FarBump Privy setup |
| Database | ❌ New schema | ✅ Add 1 table to existing DB |
| Smart Accounts | ❌ New CDP integration | ✅ Use existing bot wallets |
| Swap Logic | ❌ Implement 0x API | ✅ Use existing swap engine |
| Paymaster | ❌ Configure from scratch | ✅ Already configured |
| Total New Code | ~2000 lines | ~300 lines |
| Time to Deploy | 2-3 days | 4-6 hours |

---

## 🚀 Deployment Checklist (Simplified)

### FarBump Backend (Existing - Minor Changes)

- [ ] Add `telegram_users` table to Supabase
- [ ] Create `/api/telegram/auth` endpoint (1 file)
- [ ] Create `/auth/telegram` page (1 file)
- [ ] Deploy to Vercel/Railway (already setup)

### Clawdbot (New - Minimal Setup)

- [ ] Install Clawdbot: `npm install -g clawdbot@latest`
- [ ] Create `skills/farbump/telegram-bot.ts` (1 file)
- [ ] Configure clawdbot.json (minimal)
- [ ] Deploy to Railway
- [ ] Test end-to-end flow

### Environment Variables

**FarBump (.env.local):**
```bash
# Existing variables (no changes needed)
NEXT_PUBLIC_PRIVY_APP_ID=your_privy_app_id
PRIVY_APP_SECRET=your_privy_secret
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_service_key
COINBASE_CDP_BUNDLER_URL=your_bundler_url
```

**Clawdbot (Railway):**
```bash
TELEGRAM_BOT_TOKEN=your_token
FARBUMP_API_URL=https://farbump.vercel.app
ANTHROPIC_API_KEY=your_key
```

---

## 💰 Cost Estimate (Simplified)

| Service | Old Approach | New Approach | Savings |
|---------|-------------|--------------|---------|
| Railway (Backend) | $20/mo | Not needed | -$20 |
| Railway (Bot) | $5/mo | $5/mo | $0 |
| Supabase | $25/mo | Already paid | $0 |
| Privy | $99/mo | Already paid | $0 |
| **Total** | **$149/mo** | **$5/mo** | **$144/mo** |

---

## ✅ What Makes This Efficient

1. **Reuse Infrastructure** - FarBump sudah punya semua yang dibutuhkan
2. **Minimal Code** - Hanya 1 Telegram handler file + 2 FarBump endpoints
3. **No Duplication** - Tidak rebuild auth, swaps, database
4. **Fast Deployment** - 4-6 jam vs 2-3 hari
5. **Lower Costs** - $5/mo vs $149/mo
6. **Easier Maintenance** - Single codebase untuk logic

---

## 🎯 Next Steps

### For FarBump Team:
1. Add `telegram_users` table (5 min)
2. Create `/api/telegram/auth` endpoint (15 min)
3. Create `/auth/telegram` page (30 min)
4. Test auth flow (15 min)

### For Bot Team:
1. Install Clawdbot (5 min)
2. Create `telegram-bot.ts` handler (30 min)
3. Configure & deploy to Railway (15 min)
4. Test with real users (30 min)

**Total Time: 2-3 hours** 🚀

---

## 📚 Files to Create

### FarBump (3 files):
1. `DATABASE-TELEGRAM-USERS.sql` - Table schema
2. `app/api/telegram/auth/route.ts` - Auth endpoint
3. `app/auth/telegram/page.tsx` - Auth page

### Clawdbot (1 file):
1. `skills/farbump/telegram-bot.ts` - Telegram handler

**Total: 4 files, ~400 lines of code**

---

That's it! Jauh lebih efficient dan realistis. 🎉
