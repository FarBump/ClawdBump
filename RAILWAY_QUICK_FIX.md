# 🚨 Quick Fix: Bot Tidak Merespon

## ⚡ Langkah Cepat (5 Menit)

### 1. Cek Railway Variables (PENTING!)

**Buka Railway Dashboard → Service → Variables**

Pastikan ada:
```
TELEGRAM_BOT_TOKEN = 8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y
GEMINI_API_KEY = AIzaSyDTUY1VUF0GnY9EG784oxEP3LNO5ZKpVEY
```

**Jika tidak ada, tambahkan sekarang!**

### 2. Restart Service

1. Railway Dashboard → Service
2. Klik **Settings** (gear icon)
3. Klik **Restart Service**
4. Tunggu 30 detik

### 3. Cek Logs

**Railway Dashboard → Service → Logs**

Cari:
- ✅ `Gateway started`
- ✅ `Telegram channel enabled`
- ✅ `Channels: telegram (enabled)`

**Jika tidak ada:**
- Scroll ke atas, cari error
- Copy error message

### 4. Test Bot

Kirim pesan ke bot di Telegram:
- `/start` atau
- `Hello` atau
- `Test`

**Expected:**
- Bot merespon dalam 2-5 detik

**Jika tidak:**
- Cek logs lagi
- Lihat bagian "Common Issues" di bawah

---

## 🔍 Common Issues

### Issue 1: Logs Kosong / Tidak Ada

**Penyebab:** Container tidak start

**Fix:**
1. Cek **Deployments** tab
2. Pastikan build **Succeeded**
3. Jika failed, klik build untuk lihat error
4. Rebuild jika perlu

### Issue 2: "Telegram: token missing"

**Penyebab:** Environment variable tidak ter-load

**Fix:**
1. Pastikan `TELEGRAM_BOT_TOKEN` di-set di Railway Variables
2. **Redeploy** (restart tidak cukup, perlu redeploy)
3. Cek logs lagi

### Issue 3: Bot Tidak Merespon Tapi Logs Normal

**Penyebab:** Webhook masih aktif

**Fix:**
Hapus webhook Telegram:
```bash
curl -X POST "https://api.telegram.org/bot8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y/deleteWebhook"
```

Bot menggunakan **polling**, bukan webhook!

### Issue 4: "No projects matched" Error

**Penyebab:** Build error (sudah di-fix)

**Fix:**
1. Pull latest code
2. Push ke GitHub
3. Railway akan auto-rebuild

---

## 🎯 Diagnostic Commands

### Test Token (dari terminal lokal):

```bash
# Test Telegram token
curl "https://api.telegram.org/bot8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y/getMe"

# Expected: {"ok":true,"result":{...}}

# Test Gemini API key
curl "https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyDTUY1VUF0GnY9EG784oxEP3LNO5ZKpVEY"

# Expected: {"models":[...]}
```

### Cek Webhook:

```bash
curl "https://api.telegram.org/bot8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y/getWebhookInfo"

# Expected: {"ok":true,"result":{"url":""}}
# Jika url tidak kosong, hapus webhook!
```

---

## ✅ Success Checklist

Bot berjalan jika:

- [ ] Railway Deployments = **Active** (hijau)
- [ ] Railway Variables = **TELEGRAM_BOT_TOKEN** dan **GEMINI_API_KEY** ada
- [ ] Railway Logs = Ada log "Gateway started" dan "Telegram enabled"
- [ ] Telegram Webhook = **Kosong** (test via curl)
- [ ] Bot Token = **Valid** (test via curl getMe)
- [ ] Bot merespon = **Ya** (test di Telegram)

---

## 🆘 Masih Error?

Jika semua di atas sudah dicek tapi masih error:

1. **Screenshot Railway Logs** (last 50 lines)
2. **Screenshot Railway Variables**
3. **Screenshot Railway Deployments**
4. **Test token via curl** dan screenshot hasilnya

Kemudian share untuk debugging lebih lanjut.

