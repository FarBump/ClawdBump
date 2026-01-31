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
    const baseUrl = `${config.farbumpApiUrl}/api/v1/auth/telegram/init`;
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
    
    const authUrl = `${baseUrl}?${params.toString()}`;
    
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
    const response = await fetch(
      `${config.farbumpApiUrl}/api/v1/auth/telegram/status?` + 
      `telegram_id=${telegramId}&session_id=${sessionId}`,
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
 * Step 3: Verify existing session
 * 
 * Check if user already has valid authentication
 */
export async function verifySession(
  telegramId: number
): Promise<{
  success: boolean;
  isValid: boolean;
  smartAccountAddress?: string;
  authToken?: string;
  error?: string;
}> {
  const config = getAuthConfig();
  
  try {
    const response = await fetch(
      `${config.farbumpApiUrl}/api/v1/auth/telegram/verify?telegram_id=${telegramId}`,
      {
        headers: {
          'Authorization': `Bearer ${config.apiKey}`
        }
      }
    );
    
    if (!response.ok) {
      return {
        success: true,
        isValid: false
      };
    }
    
    const data = await response.json();
    
    return {
      success: true,
      isValid: data.is_valid,
      smartAccountAddress: data.smart_account_address,
      authToken: data.auth_token
    };
    
  } catch (error) {
    return {
      success: false,
      isValid: false,
      error: `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

/**
 * Step 4: Revoke authentication / Logout
 */
export async function revokeAuth(
  telegramId: number
): Promise<{ success: boolean; error?: string }> {
  const config = getAuthConfig();
  
  try {
    const response = await fetch(`${config.farbumpApiUrl}/api/v1/auth/telegram/revoke`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.apiKey}`
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
 * Generate authentication message for Telegram user
 * 
 * This creates a user-friendly message with authentication instructions
 */
export function generateAuthMessage(authUrl: string): {
  message: string;
  inlineKeyboard: any;
} {
  const message = `🔐 **Authentication Required**

Welcome to FarBump! To get started, you need to authenticate your account.

When you click "Login to FarBump" below:
1. You'll be taken to our secure authentication page
2. Complete the Privy authentication process
3. A smart account will be automatically created for you
4. Return here to start swapping!

Your smart account will be created automatically and linked to your Telegram account.`;

  const inlineKeyboard = {
    inline_keyboard: [
      [
        {
          text: '🔑 Login to FarBump',
          url: authUrl
        }
      ],
      [
        {
          text: '❓ What is Privy?',
          callback_data: 'privy_info'
        }
      ]
    ]
  };
  
  return { message, inlineKeyboard };
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
 */
export async function requireAuthentication(
  telegramId: number
): Promise<{
  authenticated: boolean;
  smartAccountAddress?: string;
  authToken?: string;
  message?: string;
}> {
  // Check local session first
  const localSession = sessionStore.get(telegramId);
  if (localSession?.smartAccountAddress && localSession?.authToken) {
    return {
      authenticated: true,
      smartAccountAddress: localSession.smartAccountAddress,
      authToken: localSession.authToken
    };
  }
  
  // Verify with backend
  const verification = await verifySession(telegramId);
  
  if (verification.success && verification.isValid) {
    // Update local session
    sessionStore.save(telegramId, {
      smartAccountAddress: verification.smartAccountAddress,
      authToken: verification.authToken,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days
    });
    
    return {
      authenticated: true,
      smartAccountAddress: verification.smartAccountAddress,
      authToken: verification.authToken
    };
  }
  
  return {
    authenticated: false,
    message: '🔐 Please authenticate first using /start'
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
  verifySession,
  revokeAuth,
  generateAuthMessage,
  generateAuthStatusMessage,
  requireAuthentication,
  formatSmartAccountInfo,
  sessionStore
};
