# FarBump Backend - Required Additions

## What Needs to be Added to FarBump Backend

Only **3 small additions** needed to existing FarBump codebase:

---

## 1. Database Table (Supabase)

**File: Add to existing Supabase schema**

```sql
-- telegram_users.sql
-- Add this to your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS telegram_users (
  id BIGSERIAL PRIMARY KEY,
  telegram_id BIGINT NOT NULL UNIQUE,
  telegram_username TEXT,
  smart_account_address TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_telegram_users_telegram_id ON telegram_users(telegram_id);
CREATE INDEX idx_telegram_users_smart_account ON telegram_users(smart_account_address);

-- RLS Policy
ALTER TABLE telegram_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access"
  ON telegram_users
  FOR SELECT
  USING (true);

-- Trigger for updated_at
CREATE TRIGGER update_telegram_users_updated_at
  BEFORE UPDATE ON telegram_users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 2. Telegram Auth Endpoint

**File: `app/api/telegram/user/route.ts` (NEW)**

```typescript
import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

/**
 * GET /api/telegram/user?telegram_id=123
 * Get smart account for Telegram user
 */
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url)
  const telegramId = searchParams.get('telegram_id')
  
  if (!telegramId) {
    return NextResponse.json(
      { error: 'telegram_id required' },
      { status: 400 }
    )
  }
  
  const { data, error } = await supabase
    .from('telegram_users')
    .select('smart_account_address, telegram_username')
    .eq('telegram_id', parseInt(telegramId))
    .single()
  
  if (error || !data) {
    return NextResponse.json(
      { smart_account_address: null },
      { status: 200 }
    )
  }
  
  return NextResponse.json({
    smart_account_address: data.smart_account_address,
    telegram_username: data.telegram_username
  })
}

/**
 * POST /api/telegram/user
 * Link Telegram user to smart account
 */
export async function POST(req: Request) {
  const body = await req.json()
  const { telegram_id, telegram_username, smart_account_address } = body
  
  if (!telegram_id || !smart_account_address) {
    return NextResponse.json(
      { error: 'telegram_id and smart_account_address required' },
      { status: 400 }
    )
  }
  
  const { data, error } = await supabase
    .from('telegram_users')
    .upsert({
      telegram_id: parseInt(telegram_id),
      telegram_username,
      smart_account_address: smart_account_address.toLowerCase()
    }, {
      onConflict: 'telegram_id'
    })
    .select()
    .single()
  
  if (error) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
  
  return NextResponse.json({
    success: true,
    data
  })
}
```

---

## 3. Telegram Auth Page

**File: `app/auth/telegram/page.tsx` (NEW)**

```typescript
'use client'

import { usePrivy } from '@privy-io/react-auth'
import { useSearchParams } from 'next/navigation'
import { useEffect, useState } from 'react'

export default function TelegramAuthPage() {
  const { ready, authenticated, user, login } = usePrivy()
  const searchParams = useSearchParams()
  const telegramId = searchParams.get('tg_id')
  const telegramUsername = searchParams.get('tg_username')
  
  const [status, setStatus] = useState<'loading' | 'authenticating' | 'linking' | 'success' | 'error'>('loading')
  const [error, setError] = useState<string>('')
  
  // Auto-trigger Privy login if not authenticated
  useEffect(() => {
    if (ready && !authenticated) {
      setStatus('authenticating')
      login()
    }
  }, [ready, authenticated, login])
  
  // After Privy auth, link to Telegram
  useEffect(() => {
    async function linkAccounts() {
      if (!authenticated || !user?.wallet?.address || !telegramId) return
      
      setStatus('linking')
      
      try {
        const response = await fetch('/api/telegram/user', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            telegram_id: parseInt(telegramId),
            telegram_username: telegramUsername || '',
            smart_account_address: user.wallet.address
          })
        })
        
        const result = await response.json()
        
        if (!response.ok) {
          throw new Error(result.error || 'Failed to link accounts')
        }
        
        setStatus('success')
        
        // Redirect back to Telegram after 2 seconds
        setTimeout(() => {
          window.location.href = `https://t.me/farbump_bot?start=auth_success`
        }, 2000)
        
      } catch (err) {
        setStatus('error')
        setError(err instanceof Error ? err.message : 'Unknown error')
      }
    }
    
    linkAccounts()
  }, [authenticated, user, telegramId, telegramUsername])
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-500 to-purple-600">
      <div className="bg-white rounded-lg shadow-xl p-8 max-w-md w-full">
        <div className="text-center">
          {status === 'loading' && (
            <>
              <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <h1 className="text-2xl font-bold mb-2">Loading...</h1>
              <p className="text-gray-600">Initializing authentication</p>
            </>
          )}
          
          {status === 'authenticating' && (
            <>
              <div className="text-6xl mb-4">🔐</div>
              <h1 className="text-2xl font-bold mb-2">Authenticate with Privy</h1>
              <p className="text-gray-600">Please complete the login process</p>
            </>
          )}
          
          {status === 'linking' && (
            <>
              <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-green-500 mx-auto mb-4"></div>
              <h1 className="text-2xl font-bold mb-2">Linking Accounts</h1>
              <p className="text-gray-600">Connecting your wallet to Telegram...</p>
            </>
          )}
          
          {status === 'success' && (
            <>
              <div className="text-6xl mb-4">✅</div>
              <h1 className="text-2xl font-bold mb-2 text-green-600">Success!</h1>
              <p className="text-gray-600 mb-4">
                Your wallet is now linked to Telegram
              </p>
              <p className="text-sm text-gray-500">
                Redirecting back to Telegram bot...
              </p>
            </>
          )}
          
          {status === 'error' && (
            <>
              <div className="text-6xl mb-4">❌</div>
              <h1 className="text-2xl font-bold mb-2 text-red-600">Error</h1>
              <p className="text-gray-600 mb-4">{error}</p>
              <button
                onClick={() => window.location.reload()}
                className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
              >
                Try Again
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
```

---

## 4. Add Stop Endpoint (Optional)

**File: `app/api/bot/stop/route.ts` (NEW)**

```typescript
import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

/**
 * POST /api/bot/stop
 * Stop active bumping session
 */
export async function POST(req: Request) {
  const { userAddress } = await req.json()
  
  if (!userAddress) {
    return NextResponse.json(
      { error: 'userAddress required' },
      { status: 400 }
    )
  }
  
  const normalizedAddress = userAddress.toLowerCase()
  
  // Update session status to stopped
  const { error } = await supabase
    .from('bot_sessions')
    .update({ status: 'stopped', stopped_at: new Date().toISOString() })
    .eq('user_address', normalizedAddress)
    .eq('status', 'running')
  
  if (error) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
  
  // Log stop action
  await supabase.from('bot_logs').insert({
    user_address: normalizedAddress,
    wallet_address: normalizedAddress,
    token_address: '',
    amount_wei: '0',
    status: 'success',
    message: '[System] Bumping manually stopped via Telegram bot'
  })
  
  return NextResponse.json({ success: true })
}
```

---

## 5. Add Balances Endpoint (Optional)

**File: `app/api/bot/balances/route.ts` (NEW)**

```typescript
import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'
import { createPublicClient, http, formatEther } from 'viem'
import { base } from 'viem/chains'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

const publicClient = createPublicClient({
  chain: base,
  transport: http(process.env.NEXT_PUBLIC_BASE_RPC_URL)
})

/**
 * GET /api/bot/balances?userAddress=0x...
 * Get all bot wallet balances
 */
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url)
  const userAddress = searchParams.get('userAddress')
  
  if (!userAddress) {
    return NextResponse.json(
      { error: 'userAddress required' },
      { status: 400 }
    )
  }
  
  // Fetch ETH price
  const ethPriceResponse = await fetch(
    'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd',
    { headers: { 'x-cg-api-key': process.env.COINGECKO_API_KEY! } }
  )
  const ethPriceData = await ethPriceResponse.json()
  const ethPrice = ethPriceData.ethereum.usd
  
  // Get bot wallets
  const { data: botWallets } = await supabase
    .from('user_bot_wallets')
    .select('wallets_data')
    .eq('user_address', userAddress.toLowerCase())
    .single()
  
  if (!botWallets) {
    return NextResponse.json(
      { error: 'No bot wallets found' },
      { status: 404 }
    )
  }
  
  const wallets = JSON.parse(botWallets.wallets_data)
  
  // Fetch balances for all wallets
  const balances = await Promise.all(
    wallets.map(async (wallet: any, index: number) => {
      const balance = await publicClient.getBalance({
        address: wallet.smart_account_address
      })
      
      const ethBalance = formatEther(balance)
      const usdValue = (parseFloat(ethBalance) * ethPrice).toFixed(2)
      
      return {
        index: index + 1,
        address: wallet.smart_account_address,
        balance: parseFloat(ethBalance).toFixed(4),
        usd: usdValue
      }
    })
  )
  
  const totalEth = balances.reduce((sum, w) => sum + parseFloat(w.balance), 0)
  const totalUsd = (totalEth * ethPrice).toFixed(2)
  
  return NextResponse.json({
    wallets: balances,
    total: totalEth.toFixed(4),
    totalUsd
  })
}
```

---

## Summary

**Files to add to FarBump:**

1. ✅ `telegram_users.sql` - Database table
2. ✅ `app/api/telegram/user/route.ts` - Auth endpoint
3. ✅ `app/auth/telegram/page.tsx` - Auth UI
4. ✅ `app/api/bot/stop/route.ts` - Stop endpoint (optional)
5. ✅ `app/api/bot/balances/route.ts` - Balances endpoint (optional)

**Total: 3 required files + 2 optional = ~300 lines of code**

**Testing:**

```bash
# Test GET user
curl "https://farbump.vercel.app/api/telegram/user?telegram_id=123456"

# Test POST user (link account)
curl -X POST https://farbump.vercel.app/api/telegram/user \
  -H "Content-Type: application/json" \
  -d '{
    "telegram_id": 123456,
    "telegram_username": "testuser",
    "smart_account_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
  }'

# Test stop
curl -X POST https://farbump.vercel.app/api/bot/stop \
  -H "Content-Type: application/json" \
  -d '{"userAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"}'
```

**Deploy:**

```bash
# Commit changes
git add .
git commit -m "Add Telegram bot integration endpoints"

# Deploy to Vercel (auto-deploy if connected to GitHub)
# Or manual: vercel deploy --prod
```

That's it! Super simple additions. 🚀
