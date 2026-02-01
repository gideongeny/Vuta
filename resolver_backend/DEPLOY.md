# Deploy VUTA Backend to Cloud (Free Options)

For production use, deploy the backend to a cloud service so users don't need to run anything locally.

## Option 1: Railway (Recommended - Easiest)

1. Go to https://railway.app
2. Sign up with GitHub
3. Click "New Project"
4. Select "Deploy from GitHub repo"
5. Select your Vuta repository
6. Railway will auto-detect the Dockerfile
7. Add environment variable (optional):
   - Key: `RESOLVER_API_KEY`
   - Value: (generate a random string)
8. Deploy!

**Free tier includes:**
- $5/month credit
- Enough for low-medium traffic
- Auto-deploys on git push

## Option 2: Render (Free Tier Available)

1. Go to https://render.com
2. Sign up with GitHub
3. Click "New +" → "Web Service"
4. Connect your GitHub repo
5. Configure:
   - **Name**: vuta-resolver
   - **Environment**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python server.py`
   - **Plan**: Free
6. Add environment variables:
   - `PORT`: 10000 (Render sets this automatically)
   - `RESOLVER_API_KEY`: (optional, generate random string)
7. Deploy!

**Free tier:**
- Spins down after 15 min inactivity
- Free SSL certificate
- Custom domain support

## Option 3: Fly.io (Free Tier)

1. Install Fly CLI: https://fly.io/docs/getting-started/installing-flyctl/
2. Sign up: `fly auth signup`
3. In `resolver_backend/` directory:
   ```bash
   fly launch
   ```
4. Follow prompts
5. Deploy: `fly deploy`

**Free tier:**
- 3 shared-cpu VMs
- 3GB persistent volumes
- 160GB outbound data transfer

## Option 4: Heroku (Paid, but reliable)

1. Install Heroku CLI
2. Login: `heroku login`
3. Create app: `heroku create vuta-resolver`
4. Deploy: `git push heroku master`
5. Set env vars: `heroku config:set RESOLVER_API_KEY=your-key`

## After Deployment

1. Get your backend URL (e.g., `https://vuta-resolver.railway.app`)
2. Update the Flutter app's default backend URL
3. Or users can set it in app settings

## Update App Default URL

Edit `vuta_app/lib/services/resolver_service.dart`:

```dart
static const String baseUrl = String.fromEnvironment(
  'RESOLVER_BASE_URL',
  defaultValue: 'https://your-backend-url.railway.app', // Change this
);
```

Then rebuild the app.

## Environment Variables

- `PORT` - Server port (usually set by platform)
- `RESOLVER_API_KEY` - Optional API key for security

## Monitoring

Most platforms provide:
- Logs dashboard
- Metrics (requests, errors)
- Uptime monitoring

## Cost

- **Railway**: $5/month free credit (usually enough)
- **Render**: Free tier (spins down when idle)
- **Fly.io**: Free tier (generous limits)
- **Heroku**: Paid ($7/month minimum)

For production, Railway or Render free tiers are recommended.
