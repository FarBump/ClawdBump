# Skill: ClawdBump

The ClawdBump bot helps users check credit, bumping status, and control bumping sessions via Telegram.

## Tool: clawdbump_action

Call the ClawdBump backend to perform an action on behalf of the user who is chatting.

### Input

- **telegramId** (string, required): Telegram User ID from the chat context (e.g. from.id).
- **action** (string, required): One of: `check_balance`, `check_status`, `stop_bumping`, `start_bumping`.
- **params** (object, optional): For `start_bumping` only, must include:
  - `tokenAddress` (string): Token contract address.
  - `amountUsd` (string): e.g. "0.01".
  - `intervalSeconds` (number): 2–600.

### How to call the backend

- **URL:** `{CLAWDBUMP_APP_URL}/api/telegram/bot-action`
- **Method:** POST
- **Headers:** `Authorization: Bearer {CLAWDBUMP_BOT_SECRET}`, `Content-Type: application/json`
- **Body:** `{ "telegramId": "<telegramId>", "action": "<action>", "params": {} }`

Replace `{CLAWDBUMP_APP_URL}` and `{CLAWDBUMP_BOT_SECRET}` with the values from the environment.

### Response handling

- **check_balance:** Format as "Your total credit: X ETH" (and optional breakdown). If `user_not_found`, say "Please log in first via the ClawdBump Mini App."
- **check_status:** "No active session." or "Active session: token …, $X per bump, every Y seconds."
- **stop_bumping:** "Bumping session has been stopped." or the error message from the backend.
- **start_bumping:** Confirm parameters and "Bumping session is now running." or show backend error (e.g. insufficient balance, already has session).
- **user_not_found:** Always tell the user to log in via the ClawdBump Mini App.
