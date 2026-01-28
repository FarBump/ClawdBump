/**
 * FarBump API Integration Tools
 * 
 * This file contains tool implementations for interacting with FarBump API
 */

interface FarBumpConfig {
  apiUrl: string;
  apiKey: string;
}

interface SwapParams {
  fromToken: string;
  toToken: string;
  amount: number;
  walletAddress: string;
  slippage?: number;
}

interface SwapResponse {
  success: boolean;
  txHash?: string;
  estimatedOutput?: number;
  actualOutput?: number;
  error?: string;
}

interface BalanceResponse {
  success: boolean;
  balances?: Record<string, number>;
  totalUsd?: number;
  error?: string;
}

/**
 * Get FarBump configuration from environment
 */
function getFarBumpConfig(): FarBumpConfig {
  const apiUrl = process.env.FARBUMP_API_URL || 'https://api.farbump.com';
  const apiKey = process.env.FARBUMP_API_KEY;
  
  if (!apiKey) {
    throw new Error('FARBUMP_API_KEY environment variable is required');
  }
  
  return { apiUrl, apiKey };
}

/**
 * Execute token swap via FarBump API
 */
export async function executeSwap(params: SwapParams): Promise<SwapResponse> {
  const config = getFarBumpConfig();
  
  try {
    const response = await fetch(`${config.apiUrl}/api/v1/swap`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.apiKey}`,
        'X-User-Address': params.walletAddress
      },
      body: JSON.stringify({
        from_token: params.fromToken,
        to_token: params.toToken,
        amount: params.amount,
        slippage: params.slippage || 0.5 // Default 0.5% slippage
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      return {
        success: false,
        error: error.message || 'Swap failed'
      };
    }
    
    const data = await response.json();
    
    return {
      success: true,
      txHash: data.tx_hash,
      estimatedOutput: data.estimated_output,
      actualOutput: data.actual_output
    };
    
  } catch (error) {
    return {
      success: false,
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Get wallet balance from FarBump
 */
export async function getBalance(walletAddress: string): Promise<BalanceResponse> {
  const config = getFarBumpConfig();
  
  try {
    const response = await fetch(
      `${config.apiUrl}/api/v1/balance?wallet=${walletAddress}`,
      {
        headers: {
          'Authorization': `Bearer ${config.apiKey}`
        }
      }
    );
    
    if (!response.ok) {
      const error = await response.json();
      return {
        success: false,
        error: error.message || 'Failed to fetch balance'
      };
    }
    
    const data = await response.json();
    
    return {
      success: true,
      balances: data.balances,
      totalUsd: data.total_usd
    };
    
  } catch (error) {
    return {
      success: false,
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Set up auto-swap schedule
 */
export async function setupAutoSwap(params: {
  walletAddress: string;
  fromToken: string;
  toToken: string;
  amount: number;
  interval: string; // 'daily', 'weekly', 'hourly'
}): Promise<{ success: boolean; scheduleId?: string; error?: string }> {
  const config = getFarBumpConfig();
  
  try {
    const response = await fetch(`${config.apiUrl}/api/v1/autoswap`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.apiKey}`,
        'X-User-Address': params.walletAddress
      },
      body: JSON.stringify({
        from_token: params.fromToken,
        to_token: params.toToken,
        amount: params.amount,
        interval: params.interval
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      return {
        success: false,
        error: error.message || 'Failed to setup auto-swap'
      };
    }
    
    const data = await response.json();
    
    return {
      success: true,
      scheduleId: data.schedule_id
    };
    
  } catch (error) {
    return {
      success: false,
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Get transaction history
 */
export async function getTransactionHistory(
  walletAddress: string,
  limit: number = 10
): Promise<{
  success: boolean;
  transactions?: Array<{
    txHash: string;
    fromToken: string;
    toToken: string;
    amount: number;
    timestamp: string;
    status: string;
  }>;
  error?: string;
}> {
  const config = getFarBumpConfig();
  
  try {
    const response = await fetch(
      `${config.apiUrl}/api/v1/transactions?wallet=${walletAddress}&limit=${limit}`,
      {
        headers: {
          'Authorization': `Bearer ${config.apiKey}`
        }
      }
    );
    
    if (!response.ok) {
      const error = await response.json();
      return {
        success: false,
        error: error.message || 'Failed to fetch transactions'
      };
    }
    
    const data = await response.json();
    
    return {
      success: true,
      transactions: data.transactions
    };
    
  } catch (error) {
    return {
      success: false,
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Helper function to parse user swap intent from natural language
 */
export function parseSwapIntent(message: string): {
  fromToken?: string;
  toToken?: string;
  amount?: number;
} {
  const patterns = [
    // "Swap 0.1 ETH to USDC"
    /swap\s+([\d.]+)\s+(\w+)\s+to\s+(\w+)/i,
    // "Exchange 100 USDC for ETH"
    /exchange\s+([\d.]+)\s+(\w+)\s+for\s+(\w+)/i,
    // "Buy 1000 USDC with ETH"
    /buy\s+([\d.]+)\s+(\w+)\s+with\s+(\w+)/i,
  ];
  
  for (const pattern of patterns) {
    const match = message.match(pattern);
    if (match) {
      const [, amount, token1, token2] = match;
      
      // Determine which is from and which is to based on command
      const isBuyCommand = message.toLowerCase().includes('buy');
      
      return {
        amount: parseFloat(amount),
        fromToken: isBuyCommand ? token2 : token1,
        toToken: isBuyCommand ? token1 : token2
      };
    }
  }
  
  return {};
}

/**
 * Format balance display
 */
export function formatBalance(balances: Record<string, number>, totalUsd?: number): string {
  let output = '💰 Your FarBump Balance:\n\n';
  
  for (const [token, amount] of Object.entries(balances)) {
    output += `${token}: ${amount.toLocaleString()}\n`;
  }
  
  if (totalUsd) {
    output += `\nTotal USD: ~$${totalUsd.toLocaleString()}`;
  }
  
  return output;
}

/**
 * Format transaction history
 */
export function formatTransactions(transactions: Array<any>): string {
  let output = '📊 Recent Transactions:\n\n';
  
  transactions.forEach((tx, index) => {
    const timeAgo = getTimeAgo(new Date(tx.timestamp));
    output += `${index + 1}. ${tx.fromToken} → ${tx.toToken} (${timeAgo})\n`;
    output += `   Amount: ${tx.amount}\n`;
    output += `   Status: ${tx.status}\n`;
    output += `   TX: ${tx.txHash.substring(0, 10)}...\n\n`;
  });
  
  return output;
}

/**
 * Helper to get time ago string
 */
function getTimeAgo(date: Date): string {
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);
  
  if (seconds < 60) return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

// Export all functions as a module
export const FarBumpTools = {
  executeSwap,
  getBalance,
  setupAutoSwap,
  getTransactionHistory,
  parseSwapIntent,
  formatBalance,
  formatTransactions
};
