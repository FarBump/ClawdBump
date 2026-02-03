# ClawdBump Telegram Bot

Bot Telegram untuk ClawdBump yang dijalankan oleh **OpenClaw** di Railway. Bot ini memakai Google Gemini dan skill ClawdBump untuk cek saldo, status bumping, serta mengontrol sesi bumping via backend ClawdBump.

## Struktur Repo

```
clawdbump-bot-telegram/
├── package.json
├── railway.json
├── scripts/
│   └── start-openclaw.sh
├── workspace/
│   ├── SKILL.md
│   └── AGENTS.md
├── .env.example
└── README.md
```

## Prasyarat

- Node.js ≥ 22
- Token bot dari [@BotFather](https://t.me/BotFather)
- Google AI API Key (Gemini)
- Backend ClawdBump sudah deploy dengan endpoint `POST /api/telegram/bot-action`

## Variabel Lingkungan

| Variable | Keterangan |
|----------|------------|
| `TELEGRAM_BOT_TOKEN` | Token bot dari BotFather |
| `GOOGLE_GENERATIVE_AI_API_KEY` | API key Google AI (Gemini) |
| `CLAWDBUMP_APP_URL` | URL base app ClawdBump (tanpa trailing slash) |
| `CLAWDBUMP_BOT_SECRET` | Secret yang sama dengan di backend ClawdBump |
| `PORT` | Di-set otomatis oleh Railway |

Lihat `.env.example` untuk template. Jangan commit rahasia; set nilai asli di Railway (atau `.env` lokal untuk development).

## Deploy di Railway

1. Buat project baru di [Railway](https://railway.app) dan hubungkan repo ini.
2. Set semua variabel lingkungan yang wajib.
3. **Build:** `npm run build`
4. **Start:** `npm start`
5. Opsional: set `NODE_VERSION=22` di variables.

Dokumentasi lengkap setup ada di `docs/CLAWDBOT_TELEGRAM_BOT_SETUP.md` di repo ClawdBump utama.
