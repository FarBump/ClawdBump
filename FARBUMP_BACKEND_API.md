# FarBump Backend API Specification

## Required API Endpoints untuk Telegram Bot Integration

Backend FarBump perlu mengimplementasikan endpoint-endpoint berikut untuk integrasi dengan Telegram bot.

## Authentication Endpoints

### 1. Initialize Privy Authentication

**Endpoint:** `POST /api/v1/auth/telegram/init`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
Content-Type: application/json
```

**Request Body:**
```json
{
  "telegram_id": 123456789,
  "telegram_username": "user123",
  "telegram_first_name": "John",
  "telegram_last_name": "Doe"
}
```

**Response (Success):**
```json
{
  "success": true,
  "session_id": "sess_abc123xyz",
  "auth_url": "https://farbump.com/auth/telegram?session=sess_abc123xyz",
  "expires_at": "2024-01-15T10:30:00Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Invalid request",
  "message": "telegram_id is required"
}
```

**Implementation Notes:**
- Generate unique session_id untuk tracking auth flow
- Create Privy auth URL dengan session_id embedded
- Session expires dalam 10 menit
- Store session data in Redis/database untuk verification

---

### 2. Check Authentication Status

**Endpoint:** `GET /api/v1/auth/telegram/status`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
```

**Query Parameters:**
- `telegram_id` (required): Telegram user ID
- `session_id` (required): Session ID from init endpoint

**Response (Pending):**
```json
{
  "success": true,
  "status": "pending",
  "message": "Waiting for user to complete authentication"
}
```

**Response (Completed):**
```json
{
  "success": true,
  "status": "completed",
  "smart_account_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "privy_user_id": "did:privy:abc123",
  "auth_token": "jwt_token_here",
  "created_at": "2024-01-15T10:25:00Z"
}
```

**Response (Expired):**
```json
{
  "success": true,
  "status": "expired",
  "message": "Authentication session has expired"
}
```

**Implementation Notes:**
- Bot akan poll endpoint ini setiap 3-5 detik
- Ketika user complete Privy auth di browser:
  1. Create smart account via Privy SDK
  2. Save mapping: telegram_id → smart_account_address
  3. Generate JWT auth_token untuk API calls
  4. Update session status ke "completed"

---

### 3. Verify Existing Session

**Endpoint:** `GET /api/v1/auth/telegram/verify`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
```

**Query Parameters:**
- `telegram_id` (required): Telegram user ID

**Response (Valid):**
```json
{
  "success": true,
  "is_valid": true,
  "smart_account_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "auth_token": "jwt_token_here",
  "privy_user_id": "did:privy:abc123"
}
```

**Response (Invalid/Not Found):**
```json
{
  "success": true,
  "is_valid": false
}
```

**Implementation Notes:**
- Check if telegram_id has existing valid session
- Verify JWT token is not expired
- Return existing smart account if found

---

### 4. Revoke Authentication

**Endpoint:** `POST /api/v1/auth/telegram/revoke`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
Content-Type: application/json
```

**Request Body:**
```json
{
  "telegram_id": 123456789
}
```

**Response:**
```json
{
  "success": true,
  "message": "Authentication revoked successfully"
}
```

**Implementation Notes:**
- Invalidate JWT token
- Clear session dari database
- Optionally: log revocation for audit

---

## Swap Endpoints

### 5. Execute Swap

**Endpoint:** `POST /api/v1/swap`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
X-User-Address: <smart_account_address>
Content-Type: application/json
```

**Request Body:**
```json
{
  "from_token": "ETH",
  "to_token": "USDC",
  "amount": 0.1,
  "slippage": 0.5
}
```

**Response:**
```json
{
  "success": true,
  "tx_hash": "0x1234567890abcdef...",
  "estimated_output": 185.5,
  "actual_output": 184.8,
  "gas_used": "0.002 ETH",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Implementation Notes:**
- Validate user has sufficient balance
- Use existing FarBump swap logic
- Return transaction hash for tracking
- Store transaction in database

---

### 6. Get Balance

**Endpoint:** `GET /api/v1/balance`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
```

**Query Parameters:**
- `wallet` (required): Smart account address

**Response:**
```json
{
  "success": true,
  "balances": {
    "ETH": 2.45,
    "USDC": 5230.00,
    "DAI": 1000.50
  },
  "total_usd": 10345.50
}
```

---

### 7. Get Transaction History

**Endpoint:** `GET /api/v1/transactions`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
```

**Query Parameters:**
- `wallet` (required): Smart account address
- `limit` (optional): Number of transactions (default: 10, max: 100)

**Response:**
```json
{
  "success": true,
  "transactions": [
    {
      "tx_hash": "0xabc...",
      "from_token": "ETH",
      "to_token": "USDC",
      "amount": 0.5,
      "output": 1847.32,
      "timestamp": "2024-01-15T08:00:00Z",
      "status": "completed"
    }
  ]
}
```

---

### 8. Setup Auto-Swap

**Endpoint:** `POST /api/v1/autoswap`

**Headers:**
```
Authorization: Bearer <FARBUMP_API_KEY>
X-User-Address: <smart_account_address>
Content-Type: application/json
```

**Request Body:**
```json
{
  "from_token": "ETH",
  "to_token": "USDC",
  "amount": 0.01,
  "interval": "daily"
}
```

**Response:**
```json
{
  "success": true,
  "schedule_id": "sched_xyz789",
  "next_run": "2024-01-16T09:00:00Z"
}
```

---

## Privy Integration Flow (Backend)

### Flow Diagram:
```
1. Bot calls POST /auth/telegram/init
   ↓
2. Backend creates Privy session
   ↓
3. Backend generates auth URL
   ↓
4. User opens URL in browser
   ↓
5. User completes Privy authentication
   ↓
6. Privy webhook/callback hits backend
   ↓
7. Backend creates smart account via Privy SDK
   ↓
8. Backend updates session status to "completed"
   ↓
9. Bot polls GET /auth/telegram/status
   ↓
10. Bot receives smart_account_address
```

### Backend Implementation (Pseudocode):

```typescript
// 1. Initialize auth endpoint
app.post('/api/v1/auth/telegram/init', async (req, res) => {
  const { telegram_id, telegram_username } = req.body;
  
  // Generate unique session
  const sessionId = generateSessionId();
  
  // Create Privy auth URL
  const authUrl = `https://farbump.com/auth/privy?` + 
    `session=${sessionId}&` +
    `telegram_id=${telegram_id}`;
  
  // Store session in Redis with 10min expiry
  await redis.setex(
    `auth:session:${sessionId}`,
    600, // 10 minutes
    JSON.stringify({
      telegram_id,
      telegram_username,
      status: 'pending',
      created_at: new Date()
    })
  );
  
  res.json({
    success: true,
    session_id: sessionId,
    auth_url: authUrl
  });
});

// 2. Privy callback handler
app.get('/auth/privy/callback', async (req, res) => {
  const { session, privy_token } = req.query;
  
  // Verify Privy token
  const privyUser = await privyClient.verifyToken(privy_token);
  
  // Get session data
  const sessionData = await redis.get(`auth:session:${session}`);
  const { telegram_id } = JSON.parse(sessionData);
  
  // Create or get smart account
  const smartAccount = await privyClient.createSmartAccount(privyUser.id);
  
  // Save mapping
  await db.users.upsert({
    telegram_id,
    privy_user_id: privyUser.id,
    smart_account_address: smartAccount.address,
    created_at: new Date()
  });
  
  // Generate JWT token
  const authToken = jwt.sign(
    { telegram_id, address: smartAccount.address },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
  
  // Update session status
  await redis.setex(
    `auth:session:${session}`,
    300, // 5 more minutes
    JSON.stringify({
      telegram_id,
      status: 'completed',
      smart_account_address: smartAccount.address,
      privy_user_id: privyUser.id,
      auth_token: authToken
    })
  );
  
  // Redirect user
  res.redirect('https://t.me/farbump_bot?start=auth_success');
});

// 3. Check status endpoint
app.get('/api/v1/auth/telegram/status', async (req, res) => {
  const { session_id } = req.query;
  
  const sessionData = await redis.get(`auth:session:${session_id}`);
  
  if (!sessionData) {
    return res.json({ success: true, status: 'expired' });
  }
  
  const session = JSON.parse(sessionData);
  
  res.json({
    success: true,
    status: session.status,
    smart_account_address: session.smart_account_address,
    privy_user_id: session.privy_user_id,
    auth_token: session.auth_token
  });
});
```

---

## Environment Variables (Backend)

```bash
# Privy SDK
PRIVY_APP_ID=your_privy_app_id
PRIVY_APP_SECRET=your_privy_app_secret

# FarBump API
FARBUMP_API_KEY=your_internal_api_key

# JWT
JWT_SECRET=your_jwt_secret_key

# Redis (for session storage)
REDIS_URL=redis://localhost:6379

# Database
DATABASE_URL=postgresql://...
```

---

## Security Considerations

1. **API Key**: Semua endpoint require valid API key
2. **Rate Limiting**: Implement rate limiting per telegram_id
3. **Session Expiry**: Auth sessions expire in 10 minutes
4. **JWT Tokens**: Use short-lived tokens (30 days max)
5. **HTTPS Only**: All endpoints must use HTTPS
6. **Input Validation**: Validate all input parameters
7. **CORS**: Configure CORS untuk Privy callbacks

---

## Testing Checklist

- [ ] Can initialize auth and get auth URL
- [ ] Auth URL redirects to Privy correctly
- [ ] Privy callback creates smart account
- [ ] Bot can poll and get completed status
- [ ] JWT token works for swap endpoints
- [ ] Balance endpoint returns correct data
- [ ] Swap execution works end-to-end
- [ ] Transaction history is tracked
- [ ] Session revocation works
- [ ] Rate limiting prevents abuse
