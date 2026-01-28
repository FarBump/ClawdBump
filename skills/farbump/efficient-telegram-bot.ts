/**
 * FarBump Telegram Bot - Efficient Integration
 * 
 * This bot simply calls existing FarBump API endpoints.
 * No complex logic needed - FarBump backend handles everything!
 */

const FARBUMP_API_URL = process.env.FARBUMP_API_URL || 'https://farbump.vercel.app'
const FARBUMP_WEB_URL = process.env.FARBUMP_WEB_URL || 'https://farbump.vercel.app'

interface TelegramUser {
  id: number
  username?: string
  firstName?: string
}

/**
 * Get smart account address for Telegram user
 */
async function getSmartAccount(telegramId: number): Promise<string | null> {
  try {
    const response = await fetch(
      `${FARBUMP_API_URL}/api/telegram/user?telegram_id=${telegramId}`
    )
    
    if (!response.ok) return null
    
    const data = await response.json()
    return data.smart_account_address || null
  } catch (error) {
    console.error('Failed to get smart account:', error)
    return null
  }
}

/**
 * /start - Generate auth link
 */
export async function handleStart(user: TelegramUser) {
  // Check if already authenticated
  const existingAccount = await getSmartAccount(user.id)
  
  if (existingAccount) {
    return {
      message: `✅ Already connected!

Smart Account: \`${existingAccount}\`

Commands:
/bump <token_address> - Start bumping
/status - Check bot status
/stop - Stop bumping
/balance - Check bot wallet balances
/help - Show help

Example:
/bump 0x1234567890abcdef...`,
      parseMode: 'Markdown'
    }
  }
  
  // Generate auth link
  const authUrl = `${FARBUMP_WEB_URL}/auth/telegram?tg_id=${user.id}&tg_username=${user.username || ''}`
  
  return {
    message: `🦞 **Welcome to FarBump Bot!**

To get started, connect your wallet:

1. Click "Connect Wallet" below
2. Login via Privy (email/wallet/social)
3. Your smart account will be linked to Telegram
4. Start bumping tokens!

Your bot wallets will be automatically created.`,
    buttons: {
      inline_keyboard: [
        [{ text: '🔑 Connect Wallet', url: authUrl }],
        [{ text: '❓ What is FarBump?', url: 'https://farbump.vercel.app' }]
      ]
    },
    parseMode: 'Markdown'
  }
}

/**
 * /bump <token_address> - Start bumping
 */
export async function handleBump(user: TelegramUser, tokenAddress?: string) {
  // Verify authentication
  const smartAccount = await getSmartAccount(user.id)
  if (!smartAccount) {
    return {
      message: '🔐 Please authenticate first using /start',
      parseMode: 'Markdown'
    }
  }
  
  // Validate token address
  if (!tokenAddress || !tokenAddress.startsWith('0x')) {
    return {
      message: `❌ Invalid token address

Usage: /bump <token_address>

Example:
/bump 0x1234567890abcdef1234567890abcdef12345678`,
      parseMode: 'Markdown'
    }
  }
  
  // Call FarBump API to start continuous swap
  try {
    const response = await fetch(`${FARBUMP_API_URL}/api/bot/continuous-swap`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userAddress: smartAccount,
        tokenAddress: tokenAddress,
        amountUsd: 0.01, // $0.01 per bump
        intervalSeconds: 60 // 1 minute between bumps
      })
    })
    
    const result = await response.json()
    
    if (!response.ok) {
      return {
        message: `❌ Failed to start bumping

Error: ${result.error || 'Unknown error'}

Make sure you have:
1. Bot wallets generated
2. Sufficient ETH balance
3. Valid token address`,
        parseMode: 'Markdown'
      }
    }
    
    return {
      message: `🚀 **Bumping Started!**

Token: \`${tokenAddress}\`
Amount: $0.01 per bump
Interval: 60 seconds
Strategy: Round-robin (5 bot wallets)

Your bots will swap continuously until balance depleted.

Commands:
/status - Check progress
/stop - Stop bumping
/balance - Check bot balances

View live activity:
${FARBUMP_WEB_URL}/dashboard`,
      parseMode: 'Markdown'
    }
  } catch (error) {
    return {
      message: `❌ Network error

Failed to connect to FarBump API. Please try again.`,
      parseMode: 'Markdown'
    }
  }
}

/**
 * /status - Get bot status
 */
export async function handleStatus(user: TelegramUser) {
  const smartAccount = await getSmartAccount(user.id)
  if (!smartAccount) {
    return { message: '🔐 Please authenticate first using /start' }
  }
  
  try {
    const response = await fetch(
      `${FARBUMP_API_URL}/api/bot/status?userAddress=${smartAccount}`
    )
    
    const status = await response.json()
    
    if (!response.ok) {
      return { message: `❌ Failed to fetch status: ${status.error}` }
    }
    
    // Format status message
    const statusEmoji = status.status === 'running' ? '🟢' : '🔴'
    const message = `${statusEmoji} **Bot Status**

Session: ${status.status}
Current Wallet: Bot #${status.currentWallet + 1}
Swaps Completed: ${status.swapsCompleted || 0}
Total Balance: ${status.totalBalance || '0'} ETH

${status.status === 'running' ? 
  'Your bots are actively bumping!' : 
  'Bots are idle. Use /bump to start.'}

View details: ${FARBUMP_WEB_URL}/dashboard`
    
    return {
      message,
      parseMode: 'Markdown'
    }
  } catch (error) {
    return { message: '❌ Failed to fetch status. Please try again.' }
  }
}

/**
 * /stop - Stop bumping
 */
export async function handleStop(user: TelegramUser) {
  const smartAccount = await getSmartAccount(user.id)
  if (!smartAccount) {
    return { message: '🔐 Please authenticate first using /start' }
  }
  
  try {
    const response = await fetch(`${FARBUMP_API_URL}/api/bot/stop`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userAddress: smartAccount })
    })
    
    const result = await response.json()
    
    if (!response.ok) {
      return { message: `❌ Failed to stop: ${result.error}` }
    }
    
    return {
      message: `✅ **Bumping Stopped**

All bot activities have been stopped.

Resume anytime with:
/bump <token_address>`,
      parseMode: 'Markdown'
    }
  } catch (error) {
    return { message: '❌ Failed to stop. Please try again.' }
  }
}

/**
 * /balance - Check bot wallet balances
 */
export async function handleBalance(user: TelegramUser) {
  const smartAccount = await getSmartAccount(user.id)
  if (!smartAccount) {
    return { message: '🔐 Please authenticate first using /start' }
  }
  
  try {
    const response = await fetch(
      `${FARBUMP_API_URL}/api/bot/balances?userAddress=${smartAccount}`
    )
    
    const balances = await response.json()
    
    if (!response.ok) {
      return { message: `❌ Failed to fetch balances: ${balances.error}` }
    }
    
    // Format balance message
    let message = '💰 **Bot Wallet Balances**\n\n'
    
    balances.wallets.forEach((wallet: any, index: number) => {
      message += `Bot #${index + 1}: ${wallet.balance} ETH ($${wallet.usd})\n`
    })
    
    message += `\n**Total: ${balances.total} ETH ($${balances.totalUsd})**`
    
    message += `\n\nFund bots: ${FARBUMP_WEB_URL}/dashboard`
    
    return {
      message,
      parseMode: 'Markdown'
    }
  } catch (error) {
    return { message: '❌ Failed to fetch balances. Please try again.' }
  }
}

/**
 * /help - Show help
 */
export async function handleHelp(user: TelegramUser) {
  return {
    message: `📚 **FarBump Bot Commands**

**Setup:**
/start - Connect your wallet

**Bumping:**
/bump <token> - Start bumping token
/stop - Stop bumping
/status - Check bot status

**Account:**
/balance - Check bot wallet balances

**Info:**
/help - Show this message

**Example:**
\`/bump 0x1234567890abcdef1234567890abcdef12345678\`

**How it works:**
1. Connect wallet (/start)
2. Fund bot wallets (web dashboard)
3. Start bumping (/bump)
4. Monitor progress (/status)
5. Bots swap continuously until depleted

**Features:**
• 5 bot wallets for round-robin swapping
• Gasless transactions (Paymaster)
• $0.01 minimum per swap
• Real-time activity logs

**Support:**
Web: ${FARBUMP_WEB_URL}
Twitter: @FarBumpHQ`,
    parseMode: 'Markdown'
  }
}

/**
 * Parse natural language bump command
 * Example: "bump 0x123..." or "start bumping 0x123..."
 */
export function parseNaturalBump(message: string): string | null {
  const patterns = [
    /bump\s+(0x[a-fA-F0-9]{40})/i,
    /start\s+bumping\s+(0x[a-fA-F0-9]{40})/i,
    /swap\s+(0x[a-fA-F0-9]{40})/i,
  ]
  
  for (const pattern of patterns) {
    const match = message.match(pattern)
    if (match) return match[1]
  }
  
  return null
}

// Export all handlers
export const FarBumpBot = {
  handleStart,
  handleBump,
  handleStatus,
  handleStop,
  handleBalance,
  handleHelp,
  parseNaturalBump,
  getSmartAccount
}
