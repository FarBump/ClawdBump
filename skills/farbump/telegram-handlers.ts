/**
 * Telegram Bot Message Handlers with Privy Authentication
 * 
 * This file contains the bot command handlers that integrate with
 * Privy authentication and FarBump API
 */

import { PrivyAuth } from './privy-auth.js';
import { FarBumpTools } from './farbump-tools.js';

interface TelegramContext {
  userId: number;
  username?: string;
  firstName?: string;
  lastName?: string;
  chatId: number;
}

/**
 * Check user authentication and return English response
 * 
 * This function checks if user is registered and returns appropriate English message
 * along with wallet_address if authenticated
 */
async function checkUserAuth(telegramId: number): Promise<{
  isAuthenticated: boolean;
  walletAddress?: string;
  message: string;
}> {
  const authResult = await PrivyAuth.checkUserAuth(telegramId);
  
  if (!authResult.success || !authResult.is_valid || !authResult.wallet_address) {
    const miniAppLink = process.env.MINI_APP_LINK || process.env.FARBUMP_WEB_URL || 'https://farbump.vercel.app';
    return {
      isAuthenticated: false,
      message: `Oops! It looks like your wallet isn't linked yet. 🤖\n\nPlease open the FarBump Mini App to activate your Privy Smart Account and start bumping: ${miniAppLink}`
    };
  }
  
  return {
    isAuthenticated: true,
    walletAddress: authResult.wallet_address,
    message: `Welcome back! I've detected your wallet: \`${authResult.wallet_address}\`. How can I assist you with your $BUMP positions today?`
  };
}

/**
 * Handler for /start command
 * Initiates Privy authentication flow
 */
export async function handleStart(ctx: TelegramContext): Promise<{
  message: string;
  buttons?: any;
  parseMode?: string;
}> {
  // Check user authentication status
  const authCheck = await checkUserAuth(ctx.userId);
  
  if (authCheck.isAuthenticated && authCheck.walletAddress) {
    return {
      message: authCheck.message + '\n\nType /help to see available commands.',
      parseMode: 'Markdown'
    };
  }
  
  // User not authenticated - show instructions
  const miniAppLink = process.env.MINI_APP_LINK || process.env.FARBUMP_WEB_URL || 'https://farbump.vercel.app';
  return {
    message: `👋 **Welcome to ClawdBump!**

${authCheck.message}

To get started, click **"ClawdBump"** in the left menu (⬅️) to open the Mini App and login with your Telegram account.

After logging in, your smart account will be automatically created and linked to your Telegram account.`,
    parseMode: 'Markdown'
  };
}

/**
 * Handler for /status command
 * Check authentication status
 */
export async function handleStatus(ctx: TelegramContext): Promise<{
  message: string;
  parseMode?: string;
}> {
  const authCheck = await checkUserAuth(ctx.userId);
  
  return {
    message: authCheck.message,
    parseMode: 'Markdown'
  };
}

/**
 * Handler for /balance command
 * Get wallet balance
 */
export async function handleBalance(ctx: TelegramContext): Promise<{
  message: string;
  parseMode?: string;
}> {
  // Check authentication
  const authCheck = await checkUserAuth(ctx.userId);
  
  if (!authCheck.isAuthenticated || !authCheck.walletAddress) {
    return {
      message: authCheck.message,
      parseMode: 'Markdown'
    };
  }
  
  // Fetch balance
  const balanceResult = await FarBumpTools.getBalance(authCheck.walletAddress);
  
  if (!balanceResult.success || !balanceResult.balances) {
    return {
      message: `❌ Failed to fetch balance.

Error: ${balanceResult.error}

Please try again later.`,
      parseMode: 'Markdown'
    };
  }
  
  return {
    message: FarBumpTools.formatBalance(balanceResult.balances, balanceResult.totalUsd),
    parseMode: 'Markdown'
  };
}

/**
 * Handler for swap commands
 * Parse natural language and execute swap
 */
export async function handleSwapIntent(
  ctx: TelegramContext,
  message: string
): Promise<{
  message: string;
  buttons?: any;
  parseMode?: string;
}> {
  // Check authentication
  const authCheck = await checkUserAuth(ctx.userId);
  
  if (!authCheck.isAuthenticated || !authCheck.walletAddress) {
    return {
      message: authCheck.message,
      parseMode: 'Markdown'
    };
  }
  
  // Parse swap intent
  const swapIntent = FarBumpTools.parseSwapIntent(message);
  
  if (!swapIntent.fromToken || !swapIntent.toToken || !swapIntent.amount) {
    return {
      message: `❌ Could not understand swap request.

Please use format: "swap 0.1 ETH to USDC"

Examples:
• swap 0.1 ETH to USDC
• exchange 100 USDC for ETH
• buy 1000 USDC with ETH`,
      parseMode: 'Markdown'
    };
  }
  
  // Generate confirmation message
  const confirmMessage = `🔄 **Swap Confirmation**

From: ${swapIntent.amount} ${swapIntent.fromToken}
To: ${swapIntent.toToken}

Wallet Address: \`${authCheck.walletAddress}\`

Confirm this swap?`;

  const confirmButtons = {
    inline_keyboard: [
      [
        {
          text: '✅ Confirm',
          callback_data: `swap_confirm:${swapIntent.fromToken}:${swapIntent.toToken}:${swapIntent.amount}`
        },
        {
          text: '❌ Cancel',
          callback_data: 'swap_cancel'
        }
      ]
    ]
  };
  
  return {
    message: confirmMessage,
    buttons: confirmButtons,
    parseMode: 'Markdown'
  };
}

/**
 * Handler for swap confirmation callback
 */
export async function handleSwapConfirm(
  ctx: TelegramContext,
  fromToken: string,
  toToken: string,
  amount: number
): Promise<{
  message: string;
  parseMode?: string;
}> {
  // Check authentication
  const authCheck = await checkUserAuth(ctx.userId);
  
  if (!authCheck.isAuthenticated || !authCheck.walletAddress) {
    return {
      message: authCheck.message,
      parseMode: 'Markdown'
    };
  }
  
  // Execute swap
  const swapResult = await FarBumpTools.executeSwap({
    fromToken,
    toToken,
    amount,
    walletAddress: authCheck.walletAddress
  });
  
  if (!swapResult.success) {
    return {
      message: `❌ Swap failed

Error: ${swapResult.error}

Please check your balance and try again.`,
      parseMode: 'Markdown'
    };
  }
  
  return {
    message: `✅ **Swap Successful!**

From: ${amount} ${fromToken}
To: ~${swapResult.actualOutput || swapResult.estimatedOutput} ${toToken}

TX Hash: \`${swapResult.txHash}\`

View on Explorer: https://etherscan.io/tx/${swapResult.txHash}`,
    parseMode: 'Markdown'
  };
}

/**
 * Handler for /bump command
 * Start bumping a token (Uniswap v4 liquidity operations)
 */
export async function handleBump(
  ctx: TelegramContext,
  tokenAddress?: string
): Promise<{
  message: string;
  parseMode?: string;
}> {
  // Check authentication
  const authCheck = await checkUserAuth(ctx.userId);
  
  if (!authCheck.isAuthenticated || !authCheck.walletAddress) {
    return {
      message: authCheck.message,
      parseMode: 'Markdown'
    };
  }
  
  if (!tokenAddress) {
    return {
      message: `❌ Please provide a token address.

Usage: /bump <token_address>

Example:
/bump 0x1234567890abcdef1234567890abcdef12345678

Your wallet: \`${authCheck.walletAddress}\``,
      parseMode: 'Markdown'
    };
  }
  
  // Validate token address format
  if (!/^0x[a-fA-F0-9]{40}$/.test(tokenAddress)) {
    return {
      message: `❌ Invalid token address format.

Please provide a valid Ethereum address (0x followed by 40 hex characters).

Example: /bump 0x1234567890abcdef1234567890abcdef12345678`,
      parseMode: 'Markdown'
    };
  }
  
  // TODO: Implement actual bump logic via FarBump API
  // For now, return confirmation message
  return {
    message: `🚀 **Bump Operation Initiated**

Token Address: \`${tokenAddress}\`
Wallet Address: \`${authCheck.walletAddress}\`

Bump operation will be executed using your wallet address. This will interact with Uniswap v4 liquidity pools.

Note: Full bump functionality will be implemented via FarBump API.`,
    parseMode: 'Markdown'
  };
}

/**
 * Handler for /history command
 * View transaction history
 */
export async function handleHistory(ctx: TelegramContext): Promise<{
  message: string;
  parseMode?: string;
}> {
  // Check authentication
  const authCheck = await checkUserAuth(ctx.userId);
  
  if (!authCheck.isAuthenticated || !authCheck.walletAddress) {
    return {
      message: authCheck.message,
      parseMode: 'Markdown'
    };
  }
  
  // Fetch transaction history
  const historyResult = await FarBumpTools.getTransactionHistory(
    authCheck.walletAddress,
    10
  );
  
  if (!historyResult.success || !historyResult.transactions) {
    return {
      message: `❌ Failed to fetch transaction history.

Error: ${historyResult.error}

Please try again later.`,
      parseMode: 'Markdown'
    };
  }
  
  if (historyResult.transactions.length === 0) {
    return {
      message: '📊 No transactions yet.\n\nStart swapping to see your history here!',
      parseMode: 'Markdown'
    };
  }
  
  return {
    message: FarBumpTools.formatTransactions(historyResult.transactions),
    parseMode: 'Markdown'
  };
}

/**
 * Handler for /logout command
 * Revoke authentication
 */
export async function handleLogout(ctx: TelegramContext): Promise<{
  message: string;
  parseMode?: string;
}> {
  const revokeResult = await PrivyAuth.revokeAuth(ctx.userId);
  
  if (!revokeResult.success) {
    return {
      message: `❌ Failed to logout.

Error: ${revokeResult.error}`,
      parseMode: 'Markdown'
    };
  }
  
  // Clear local session
  PrivyAuth.sessionStore.delete(ctx.userId);
  
  return {
    message: `👋 Logged out successfully!

Your session has been revoked.
Use /start to login again anytime.`,
    parseMode: 'Markdown'
  };
}

/**
 * Handler for /help command
 */
export async function handleHelp(ctx: TelegramContext): Promise<{
  message: string;
  parseMode?: string;
}> {
  const helpMessage = `📚 **FarBump Bot Commands**

**Authentication:**
/start - Login with Privy
/status - Check authentication status
/logout - Logout and revoke session

**Swaps:**
Just chat naturally! Examples:
• "swap 0.1 ETH to USDC"
• "exchange 100 USDC for ETH"
• "buy 1000 USDC"

**Account:**
/balance - Check your balance
/history - View transaction history

**Help:**
/help - Show this message

For support, contact: @farbump_support`;
  
  return {
    message: helpMessage,
    parseMode: 'Markdown'
  };
}

/**
 * Handler for callback queries (inline button clicks)
 */
export async function handleCallbackQuery(
  ctx: TelegramContext,
  callbackData: string
): Promise<{
  message: string;
  buttons?: any;
  parseMode?: string;
} | null> {
  // Parse callback data
  if (callbackData === 'privy_info') {
    return {
      message: `🔐 **What is Privy?**

Privy is a secure authentication platform that:
• Creates a smart contract wallet for you
• Keeps your keys safe with advanced encryption
• Allows easy login with social accounts
• No need to remember seed phrases!

Your Telegram account will be linked to your Privy wallet, making it easy and secure to swap tokens.

Learn more: https://privy.io`,
      parseMode: 'Markdown'
    };
  }
  
  if (callbackData.startsWith('swap_confirm:')) {
    const [, fromToken, toToken, amountStr] = callbackData.split(':');
    const amount = parseFloat(amountStr);
    
    return await handleSwapConfirm(ctx, fromToken, toToken, amount);
  }
  
  if (callbackData === 'swap_cancel') {
    return {
      message: '❌ Swap cancelled.',
      parseMode: 'Markdown'
    };
  }
  
  return null;
}

// Export all handlers
export const TelegramHandlers = {
  handleStart,
  handleStatus,
  handleBalance,
  handleBump,
  handleSwapIntent,
  handleSwapConfirm,
  handleHistory,
  handleLogout,
  handleHelp,
  handleCallbackQuery
};
