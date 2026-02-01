/**
 * Privy Authentication Integration for Telegram Bot
 * 
 * This module handles Telegram user authentication via Privy SDK
 * and smart account creation through FarBump backend
 */

interface PrivyAuthConfig {
  farbumpApiUrl: string;
  farbumpApiKey: string;
  botUsername: string;
}

interface TelegramUser {
  id: number;
  username?: string;
  first_name?: string;
  last_name?: string;
}

interface AuthSession {
  telegramId: number;
  smartAccountAddress?: string;
  privyUserId?: string;
  authToken?: string;
  createdAt: string;
  expiresAt: string;
}

interface AuthResponse {
  success: boolean;
  authUrl?: string;
  sessionId?: string;
  smartAccountAddress?: string;
  error?: string;
}

/**
 * Get configuration from environment
 */
function getAuthConfig(): PrivyAuthConfig {
  return {
    farbumpApiUrl: process.env.FARBUMP_API_URL || 'https://farbump.vercel.app/',
    farbumpApiKey: process.env.FARBUMP_API_KEY!,
    botUsername: process.env.TELEGRAM_BOT_USERNAME || 'farbump_bot'
  };
}

/**
 * Normalize URL by removing trailing slash to avoid double slashes
 */
function normalizeUrl(baseUrl: string, path: string): string {
  const normalizedBase = baseUrl.replace(/\/$/, '');
  return `${normalizedBase}${path.startsWith('/') ? path : '/' + path}`;
}

/**
 * Step 1: Initiate Privy authentication for Telegram user
 * 
 * This will:
 * 1. Build auth URL with telegram_id and telegram_username as query parameters
 * 2. Return the URL directly (no API call needed - backend handles auth via URL)
 * 3. User clicks button and completes auth in browser
 */
export async function initiatePrivyAuth(telegramUser: TelegramUser): Promise<AuthResponse> {
  const config = getAuthConfig();
  
  try {
    // Build auth URL with query parameters
    const endpoint = normalizeUrl(config.farbumpApiUrl, '/api/v1/auth/telegram/init');
    const params = new URLSearchParams({
      telegram_id: telegramUser.id.toString(),
      telegram_username: telegramUser.username || ''
    });
    
    // Add optional parameters if available
    if (telegramUser.first_name) {
      params.append('telegram_first_name', telegramUser.first_name);
    }
    if (telegramUser.last_name) {
      params.append('telegram_last_name', telegramUser.last_name);
    }
    
    const authUrl = `${endpoint}?${params.toString()}`;
    
    return {
      success: true,
      authUrl: authUrl,
      sessionId: undefined // Session ID will be handled by backend via URL
    };
    
  } catch (error) {
    return {
      success: false,
      error: `Failed to generate auth URL: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Step 2: Check authentication status
 * 
 * Poll this endpoint to check if user has completed Privy authentication
 */
export async function checkAuthStatus(
  telegramId: number,
  sessionId: string
): Promise<{
  success: boolean;
  status: 'pending' | 'completed' | 'expired' | 'failed';
  smartAccountAddress?: string;
  privyUserId?: string;
  authToken?: string;
  error?: string;
}> {
  const config = getAuthConfig();
  
  try {
    const statusUrl = normalizeUrl(config.farbumpApiUrl, '/api/v1/auth/telegram/status');
    const response = await fetch(
      `${statusUrl}?telegram_id=${telegramId}&session_id=${sessionId}`,
      {
        headers: {
          'Authorization': `Bearer ${config.farbumpApiKey}`
        }
      }
    );
    
    if (!response.ok) {
      const error = await response.json();
      return {
        success: false,
        status: 'failed',
        error: error.message || 'Failed to check auth status'
      };
    }
    
    const data = await response.json();
    
    return {
      success: true,
      status: data.status,
      smartAccountAddress: data.smart_account_address,
      privyUserId: data.privy_user_id,
      authToken: data.auth_token
    };
    
  } catch (error) {
    return {
      success: false,
      status: 'failed',
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Check user authentication status
 * 
 * Fetches user registration status and wallet address from FarBump API
 * This is the primary function for checking if a user is authenticated
 */
export async function checkUserAuth(
  telegramId: number
): Promise<{
  success: boolean;
  is_valid: boolean;
  wallet_address?: string;
  privy_user_id?: string;
  error?: string;
}> {
  const config = getAuthConfig();
  
  try {
    const verifyUrl = normalizeUrl(config.farbumpApiUrl, '/api/v1/auth/telegram/verify');
    const response = await fetch(
      `${verifyUrl}?telegram_id=${telegramId}`,
      {
        headers: {
          'Authorization': `Bearer ${config.farbumpApiKey}`
        }
      }
    );
    
    if (!response.ok) {
      return {
        success: true,
        is_valid: false
      };
    }
    
    const data = await response.json();
    
    return {
      success: true,
      is_valid: data.is_valid || false,
      wallet_address: data.smart_account_address || data.wallet_address,
      privy_user_id: data.privy_user_id
    };
    
  } catch (error) {
    return {
      success: false,
      is_valid: false,
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Step 3: Verify existing session
 * 
 * Check if user already has valid authentication
 * (Kept for backward compatibility)
 */
export async function verifySession(
  telegramId: number
): Promise<{
  success: boolean;
  isValid: boolean;
  smartAccountAddress?: string;
  privyUserId?: string;
  authToken?: string;
  error?: string;
}> {
  const authCheck = await checkUserAuth(telegramId);
  
  return {
    success: authCheck.success,
    isValid: authCheck.is_valid,
    smartAccountAddress: authCheck.wallet_address,
    privyUserId: authCheck.privy_user_id,
    error: authCheck.error
  };
}

/**
 * Step 4: Revoke authentication / Logout
 */
export async function revokeAuth(
  telegramId: number
): Promise<{ success: boolean; error?: string }> {
  const config = getAuthConfig();
  
  try {
    const revokeUrl = normalizeUrl(config.farbumpApiUrl, '/api/v1/auth/telegram/revoke');
    const response = await fetch(revokeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.farbumpApiKey}`
      },
      body: JSON.stringify({
        telegram_id: telegramId
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      return {
        success: false,
        error: error.message || 'Failed to revoke authentication'
      };
    }
    
    return { success: true };
    
  } catch (error) {
    return {
      success: false,
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Generate authentication message with instructions to open Mini App from bot menu
 * 
 * Simple instruction to click "ClawdBump" in the left menu to open Mini App
 */
export function generateAuthMessage(telegramUser: TelegramUser): {
  message: string;
  inlineKeyboard?: any;
} {
  const message = `👋 **Welcome to ClawdBump!**

To get started, click **"ClawdBump"** in the left menu (⬅️) to open the Mini App and login with your Telegram account.

After logging in, your smart account will be automatically created and linked to your Telegram account.

Type /help for commands.`;

  return { message };
}

/**
 * Generate authentication status message
 */
export function generateAuthStatusMessage(status: string): string {
  switch (status) {
    case 'pending':
      return '⏳ Waiting for authentication...\n\nPlease complete the login process in your browser.';
    
    case 'completed':
      return '✅ Authentication successful!\n\nYour smart account has been created. You can now start swapping tokens!';
    
    case 'expired':
      return '⌛ Authentication link expired.\n\nPlease use /start to generate a new login link.';
    
    case 'failed':
      return '❌ Authentication failed.\n\nPlease try again with /start or contact support if the issue persists.';
    
    default:
      return '🔄 Checking authentication status...';
  }
}

/**
 * Session storage helper (in-memory for now, should use Redis/DB in production)
 */
class SessionStore {
  private sessions: Map<number, AuthSession> = new Map();
  
  /**
   * Save user session
   */
  save(telegramId: number, session: Omit<AuthSession, 'telegramId'>): void {
    this.sessions.set(telegramId, {
      telegramId,
      ...session
    });
  }
  
  /**
   * Get user session
   */
  get(telegramId: number): AuthSession | undefined {
    const session = this.sessions.get(telegramId);
    
    // Check if session is expired
    if (session && new Date(session.expiresAt) < new Date()) {
      this.sessions.delete(telegramId);
      return undefined;
    }
    
    return session;
  }
  
  /**
   * Delete user session
   */
  delete(telegramId: number): void {
    this.sessions.delete(telegramId);
  }
  
  /**
   * Check if user has valid session
   */
  has(telegramId: number): boolean {
    return this.get(telegramId) !== undefined;
  }
}

// Export singleton instance
export const sessionStore = new SessionStore();

/**
 * Helper function to check if user is authenticated
 * Use this as middleware before executing swap commands
 * 
 * This function will:
 * 1. Check local cache first (for performance)
 * 2. If not found, verify with FarBump backend API
 * 3. Return user's smart account address and Privy user ID if authenticated
 */
export async function requireAuthentication(
  telegramId: number,
  forceRefresh: boolean = false
): Promise<{
  authenticated: boolean;
  smartAccountAddress?: string;
  privyUserId?: string;
  authToken?: string;
  message?: string;
}> {
  // Check local session first (unless force refresh)
  if (!forceRefresh) {
    const localSession = sessionStore.get(telegramId);
    if (localSession?.smartAccountAddress && localSession?.authToken) {
      return {
        authenticated: true,
        smartAccountAddress: localSession.smartAccountAddress,
        privyUserId: localSession.privyUserId,
        authToken: localSession.authToken
      };
    }
  }
  
  // Verify with backend API (always check to ensure user has logged in via Mini App)
  const verification = await verifySession(telegramId);
  
  if (verification.success && verification.isValid && verification.smartAccountAddress) {
    // Update local session with all available data
    sessionStore.save(telegramId, {
      smartAccountAddress: verification.smartAccountAddress,
      privyUserId: verification.privyUserId,
      authToken: verification.authToken,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days
    });
    
    return {
      authenticated: true,
      smartAccountAddress: verification.smartAccountAddress,
      privyUserId: verification.privyUserId,
      authToken: verification.authToken
    };
  }
  
  return {
    authenticated: false,
    message: '🔐 Please authenticate first. Click "ClawdBump" in the left menu to open Mini App and login with Telegram.'
  };
}

/**
 * Format smart account info for display
 */
export function formatSmartAccountInfo(
  smartAccountAddress: string,
  privyUserId?: string
): string {
  return `📱 **Your Smart Account**

Address: \`${smartAccountAddress}\`
${privyUserId ? `Privy ID: \`${privyUserId}\`` : ''}

Your smart account is secured by Privy and linked to your Telegram account.

You can now:
• Swap tokens
• Check balance
• View transaction history
• Set up auto-swaps`;
}

// Export all functions
export const PrivyAuth = {
  initiatePrivyAuth,
  checkAuthStatus,
  checkUserAuth,
  verifySession,
  revokeAuth,
  generateAuthMessage,
  generateAuthStatusMessage,
  requireAuthentication,
  formatSmartAccountInfo,
  sessionStore
};
