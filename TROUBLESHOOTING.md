# Troubleshooting: Telegram Bot Tidak Merespon

## 🔍 Checklist Diagnostik

### 1. Cek Container Status di Railway

1. Buka Railway Dashboard
2. Pilih service ClawdBump
3. Cek tab **Deployments**:
   - Status harus **Active** (hijau)
   - Build harus **Succeeded**
   - Container harus **Running**

### 2. Cek Logs Railway

**Di Railway Dashboard → Service → Logs:**

Cari log berikut yang menunjukkan bot sudah jalan:
```
✅ Gateway started on port 18789
✅ Telegram channel enabled
✅ Connected to Telegram API
```

**Jika tidak ada log sama sekali:**
- Container mungkin tidak start
- Cek error di build logs

**Jika ada error:**
- Copy error message
- Cek bagian "Common Errors" di bawah

### 3. Verifikasi Environment Variables

**Di Railway Dashboard → Service → Variables:**

Pastikan variabel berikut sudah di-set:
- ✅ `TELEGRAM_BOT_TOKEN` = `8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y`
- ✅ `GEMINI_API_KEY` = `AIzaSyDTUY1VUF0GnY9EG784oxEP3LNO5ZKpVEY`
- ✅ `PORT` = (auto-set oleh Railway, jangan override)

**Cara set:**
1. Klik **Variables** tab
2. Klik **+ New Variable**
3. Tambahkan setiap variable
4. Klik **Deploy** untuk apply changes

### 4. Test Telegram Bot Token

**Via curl (dari terminal lokal):**
```bash
curl "https://api.telegram.org/bot8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y/getMe"
```

**Expected response:**
```json
{
  "ok": true,
  "result": {
    "id": 8456270009,
    "is_bot": true,
    "first_name": "YourBotName",
    "username": "your_bot_username"
  }
}
```

**Jika error:**
- Token mungkin invalid atau expired
- Regenerate token dari @BotFather

### 5. Cek Webhook Telegram

**Via curl:**
```bash
curl "https://api.telegram.org/bot8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y/getWebhookInfo"
```

**Jika webhook sudah di-set:**
- Hapus webhook dulu:
```bash
curl -X POST "https://api.telegram.org/bot8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y/deleteWebhook"
```

Bot menggunakan **polling**, bukan webhook, jadi webhook harus kosong.

---

## 🚨 Common Errors & Solutions

### Error 1: "Container failed to start"

**Penyebab:**
- Build gagal
- CMD tidak valid
- Missing dependencies

**Solusi:**
1. Cek build logs di Railway
2. Pastikan Dockerfile valid
3. Rebuild: Railway akan auto-rebuild setelah push

### Error 2: "No projects matched the filters"

**Penyebab:**
- pnpm workspace error (sudah di-fix)

**Solusi:**
- Sudah di-fix di Dockerfile terbaru
- Pull latest code dan rebuild

### Error 3: "Telegram: token missing"

**Penyebab:**
- `TELEGRAM_BOT_TOKEN` tidak di-set
- Environment variable tidak ter-load

**Solusi:**
1. Set `TELEGRAM_BOT_TOKEN` di Railway Variables
2. Redeploy service
3. Cek logs untuk konfirmasi

### Error 4: "Google provider: API key missing"

**Penyebab:**
- `GEMINI_API_KEY` tidak di-set

**Solusi:**
1. Set `GEMINI_API_KEY` di Railway Variables
2. Redeploy service

### Error 5: Bot tidak merespon tapi logs normal

**Penyebab:**
- Webhook masih aktif (harus polling)
- Bot token salah
- Channel tidak enabled

**Solusi:**
1. Hapus webhook (lihat step 5 di atas)
2. Verifikasi token
3. Cek logs untuk "Telegram channel enabled"

---

## 🔧 Manual Testing Steps

### Step 1: Test dari Railway Logs

1. Buka Railway Dashboard
2. Pilih service → **Logs** tab
3. Kirim pesan ke bot di Telegram
4. Cek apakah ada log baru muncul

**Expected logs:**
```
[telegram] Received message from user 123456789
[agent] Processing message...
[agent] Response generated
[telegram] Sending message to user 123456789
```

### Step 2: Test Gateway Health

**Via Railway Terminal (jika tersedia):**
```bash
# Connect ke container
railway run bash

# Test gateway
node dist/entry.js gateway run --help

# Check if gateway can start
node dist/entry.js gateway run --port 18789
```

### Step 3: Test Environment Variables

**Via Railway Terminal:**
```bash
echo $TELEGRAM_BOT_TOKEN
echo $GEMINI_API_KEY
echo $PORT
```

**Expected:**
- `TELEGRAM_BOT_TOKEN` = token Anda
- `GEMINI_API_KEY` = API key Anda
- `PORT` = angka (18789 atau Railway-assigned)

---

## 🎯 Quick Fix Checklist

Jika bot tidak merespon, cek secara berurutan:

- [ ] **Container status = Running** (Railway Dashboard)
- [ ] **Build status = Succeeded** (Railway Dashboard)
- [ ] **Environment variables di-set** (Railway Variables)
- [ ] **Logs menunjukkan "Gateway started"** (Railway Logs)
- [ ] **Logs menunjukkan "Telegram enabled"** (Railway Logs)
- [ ] **Webhook Telegram = kosong** (test via curl)
- [ ] **Bot token valid** (test via curl getMe)
- [ ] **Tidak ada error di logs** (Railway Logs)

---

## 📞 Next Steps Jika Masih Error

Jika semua checklist di atas sudah dicek tapi masih error:

1. **Copy full logs** dari Railway (last 100 lines)
2. **Screenshot** Railway Variables
3. **Screenshot** Railway Deployments status
4. **Test token** via curl dan screenshot hasilnya

Kemudian share informasi tersebut untuk debugging lebih lanjut.

---

## 🔄 Force Restart

Jika perlu restart service:

1. Railway Dashboard → Service
2. Klik **Settings** → **Restart Service**
3. Tunggu ~30 detik
4. Cek logs lagi

---

## ✅ Success Indicators

Bot berjalan dengan benar jika:

✅ Logs menunjukkan:
```
Gateway started on 0.0.0.0:18789
Telegram channel enabled
Channels: telegram (enabled)
```

✅ Test message di Telegram:
- Bot merespon dalam 2-5 detik
- Response relevan dengan pertanyaan
- Tidak ada error message

✅ Railway metrics:
- CPU usage > 0%
- Memory usage > 0%
- Network traffic > 0

