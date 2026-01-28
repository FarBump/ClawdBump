# FarBump Swap Automation Skill

## Purpose
Allows users to execute token swaps and automation through FarBump API via natural Telegram conversation.

## Available Commands

### Swap Commands
- "Swap 0.1 ETH to USDC"
- "Exchange 100 USDC for ETH"
- "Buy 1000 tokens at address 0x..."

### Status Commands
- "What's my balance?"
- "Check my swap status"
- "Show recent transactions"

### Automation Commands
- "Auto-swap 0.01 ETH to USDC daily"
- "Set up recurring swap"
- "Disable auto-swap"

## User Authentication

Users must provide their wallet address on first use:
```
User: /start
Bot: Please provide your wallet address to get started
User: 0xYourWalletAddress
Bot: ✅ Wallet linked! You can now perform swaps.
```

## API Integration

### FarBump API Endpoints Used
- `POST /api/v1/swap` - Execute swap
- `GET /api/v1/balance` - Get wallet balance
- `POST /api/v1/autoswap` - Set up automation
- `GET /api/v1/transactions` - Get transaction history

### Required Environment Variables
- `FARBUMP_API_URL` - FarBump API base URL
- `FARBUMP_API_KEY` - Your FarBump API key

## Examples

### Example 1: Simple Swap
```
User: Swap 0.5 ETH to USDC

Bot: 🔄 Processing swap...
     From: 0.5 ETH
     To: USDC
     Estimated output: ~1,850 USDC
     
     Confirm? (yes/no)

User: yes

Bot: ✅ Swap successful!
     TX Hash: 0xabc123...
     Received: 1,847.32 USDC
     🔗 View on Explorer
```

### Example 2: Check Balance
```
User: What's my balance?

Bot: 💰 Your FarBump Balance:
     ETH: 2.45
     USDC: 5,230.00
     Total USD: ~$10,345.50
```

### Example 3: Auto-Swap Setup
```
User: Set up auto-swap 0.01 ETH to USDC every day

Bot: ⚙️ Auto-Swap Configuration:
     Amount: 0.01 ETH
     To: USDC
     Frequency: Daily (every 24h)
     Next run: Tomorrow 9:00 AM UTC
     
     Confirm setup? (yes/no)

User: yes

Bot: ✅ Auto-swap activated!
     You'll receive notifications for each swap.
     Disable anytime with: /autoswap off
```

## Error Handling

- Insufficient balance: Clear message with current balance
- Invalid token address: Prompt for valid address
- API errors: Retry with exponential backoff
- Network issues: Queue request and retry

## Safety Features

1. **Confirmation Required**: All swaps require user confirmation
2. **Slippage Protection**: Warns if slippage > 5%
3. **Gas Price Check**: Alerts on high gas fees
4. **Daily Limits**: Configurable per-user limits

## Advanced Features

### Price Alerts
```
User: Alert me when ETH reaches $3000

Bot: ✅ Price alert set!
     You'll be notified when ETH ≥ $3,000
```

### Transaction History
```
User: Show my last 5 transactions

Bot: 📊 Recent Transactions:
     1. Swap 0.5 ETH → 1,847 USDC (2h ago)
     2. Swap 100 USDC → 0.027 ETH (1d ago)
     ...
```

## Configuration

See main clawdbot.json for FarBump-specific settings:
- Rate limits
- Default slippage tolerance
- Auto-swap intervals
- Notification preferences
