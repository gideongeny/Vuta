const express = require('express');
const { chromium } = require('playwright');

const app = express();
app.use(express.json({ limit: '1mb' }));

const REQUIRED_API_KEY = (process.env.RESOLVER_API_KEY || '').trim();

app.use((_, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  next();
});

app.get('/health', (_, res) => {
  res.json({ ok: true });
});

function isAuthorized(req) {
  if (!REQUIRED_API_KEY) return true;
  const auth = String(req.headers['authorization'] || '').trim();
  if (!auth.toLowerCase().startsWith('bearer ')) return false;
  const token = auth.slice('bearer '.length).trim();
  return token === REQUIRED_API_KEY;
}

function looksLikeMp4(url, contentType) {
  if (!url) return false;
  const u = url.toLowerCase();
  const ct = (contentType || '').toLowerCase();
  return u.includes('.mp4') || ct.includes('video/mp4') || ct.startsWith('video/');
}

function looksLikeM3u8(url, contentType) {
  if (!url) return false;
  const u = url.toLowerCase();
  const ct = (contentType || '').toLowerCase();
  return u.includes('.m3u8') || ct.includes('application/vnd.apple.mpegurl') || ct.includes('application/x-mpegurl');
}

app.post('/resolve', async (req, res) => {
  if (!isAuthorized(req)) {
    res.status(401).json({ ok: false, error: 'Unauthorized' });
    return;
  }

  const url = (req.body && req.body.url ? String(req.body.url) : '').trim();
  if (!url) {
    res.status(400).json({ ok: false, error: 'Missing url' });
    return;
  }

  let browser;
  try {
    const candidates = [];

    browser = await chromium.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-dev-shm-usage'],
    });

    const context = await browser.newContext({
      userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      viewport: { width: 1280, height: 720 },
    });

    const page = await context.newPage();

    page.on('response', async (response) => {
      try {
        const u = response.url();
        if (!u || u.startsWith('blob:')) return;
        const headers = response.headers();
        const ct = headers['content-type'] || '';

        if (looksLikeMp4(u, ct)) {
          candidates.push({ url: u, type: 'mp4', contentType: ct });
          return;
        }

        if (looksLikeM3u8(u, ct)) {
          candidates.push({ url: u, type: 'm3u8', contentType: ct });
        }
      } catch (_) {}
    });

    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
    await page.waitForTimeout(2000);

    await page.evaluate(() => {
      const v = document.querySelector('video');
      if (!v) return;
      try {
        v.muted = true;
        const p = v.play();
        if (p && typeof p.catch === 'function') p.catch(() => {});
      } catch (_) {}
    });

    await page.waitForTimeout(9000);

    const mp4 = candidates.find((c) => c.type === 'mp4');
    if (mp4) {
      res.json({ ok: true, url: mp4.url, type: 'mp4' });
      return;
    }

    const m3u8 = candidates.find((c) => c.type === 'm3u8');
    if (m3u8) {
      res.json({ ok: true, url: m3u8.url, type: 'm3u8' });
      return;
    }

    res.status(422).json({ ok: false, error: 'No downloadable media URL found. Content may require login/cookies or uses protected streaming.' });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  } finally {
    try {
      if (browser) await browser.close();
    } catch (_) {}
  }
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Resolver backend listening on :${port}`);
});
