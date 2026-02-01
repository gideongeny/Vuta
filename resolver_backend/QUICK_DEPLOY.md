# Quick Deploy Guide - 5 Minutes to Production Backend

Deploy your backend to the cloud so users don't need to run anything locally.

## 🚀 Option 1: Railway (Easiest - Recommended)

1. **Go to**: https://railway.app
2. **Sign up** with GitHub (free)
3. **Click**: "New Project" → "Deploy from GitHub repo"
4. **Select**: Your Vuta repository
5. **Set root directory**: `resolver_backend`
6. **Add environment variable** (optional):
   - Key: `RESOLVER_API_KEY`
   - Value: Generate random string (or leave empty)
7. **Deploy!** Railway auto-detects the Dockerfile

**Your backend URL will be**: `https://your-project-name.railway.app`

**Free tier**: $5/month credit (usually enough for low-medium traffic)

---

## 🚀 Option 2: Render (Free Tier)

1. **Go to**: https://render.com
2. **Sign up** with GitHub (free)
3. **Click**: "New +" → "Web Service"
4. **Connect**: Your GitHub repo
5. **Configure**:
   - **Name**: `vuta-resolver`
   - **Root Directory**: `resolver_backend`
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python server.py`
   - **Plan**: `Free`
6. **Deploy!**

**Your backend URL will be**: `https://vuta-resolver.onrender.com`

**Note**: Free tier spins down after 15 min inactivity (first request may be slow)

---

## 🚀 Option 3: Fly.io (Free Tier)

1. **Install Fly CLI**: https://fly.io/docs/getting-started/installing-flyctl/
2. **Sign up**: `fly auth signup`
3. **Navigate**: `cd resolver_backend`
4. **Launch**: `fly launch`
5. **Follow prompts** (use defaults)
6. **Deploy**: `fly deploy`

**Your backend URL will be**: `https://your-app-name.fly.dev`

---

## 📱 Update Your App

After deployment, update the app's default backend URL:

1. **Edit**: `vuta_app/lib/services/resolver_service.dart`
2. **Change**:
   ```dart
   defaultValue: 'https://your-backend-url.railway.app', // Your deployed URL
   ```
3. **Rebuild** the app

Or users can set it in app Settings (gear icon).

---

## ✅ Test Your Backend

```bash
# Health check
curl https://your-backend-url.railway.app/health

# Should return: {"ok":true}
```

---

## 💡 Pro Tips

- **Railway**: Best for always-on service, auto-deploys on git push
- **Render**: Free but spins down when idle (good for testing)
- **Fly.io**: Generous free tier, good performance

For production apps, **Railway** is recommended.

---

## 🔒 Security (Optional)

Add an API key to protect your backend:

1. **Generate key**: `openssl rand -hex 32`
2. **Set in platform**: Environment variable `RESOLVER_API_KEY`
3. **Update app**: Set `RESOLVER_API_KEY` in build config

---

## 📊 Monitoring

All platforms provide:
- ✅ Logs dashboard
- ✅ Request metrics
- ✅ Error tracking
- ✅ Uptime monitoring

---

**That's it!** Your backend is now running in the cloud. Users don't need to configure anything - it just works! 🎉
