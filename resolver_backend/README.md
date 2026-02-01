# VUTA Resolver Backend

High-performance video extraction backend using **yt-dlp** - the industry-standard extractor used by top Play Store apps.

## Features

- ✅ **yt-dlp powered** - Most reliable extractor, supports 1000+ sites
- ✅ **Fast extraction** - Direct URL extraction without downloading
- ✅ **Wide compatibility** - Instagram, Facebook, TikTok, YouTube, and more
- ✅ **Production ready** - Used by millions of users worldwide

## Prerequisites

- Python 3.9 or higher
- pip (Python package manager)

## Installation

### Local Development

```bash
# Install Python dependencies
pip install -r requirements.txt

# Run the server
python server.py
```

The server will start on `http://localhost:8080`

### Docker

```bash
# Build the image
docker build -t vuta-resolver .

# Run the container
docker run -p 8080:8080 vuta-resolver
```

### Environment Variables

- `PORT` - Server port (default: 8080)
- `RESOLVER_API_KEY` - Optional API key for authentication

## API Endpoints

### Health Check

```bash
GET /health
```

Returns: `{"ok": true}`

### Resolve Video URL

```bash
POST /resolve
Content-Type: application/json

{
  "url": "https://instagram.com/p/..."
}
```

**Response (Success):**
```json
{
  "ok": true,
  "url": "https://...video.mp4",
  "type": "mp4"
}
```

**Response (Error):**
```json
{
  "ok": false,
  "error": "Error message"
}
```

### Authentication (Optional)

If `RESOLVER_API_KEY` is set, include in headers:
```
Authorization: Bearer YOUR_API_KEY
```

## Supported Platforms

yt-dlp supports 1000+ sites including:
- Instagram (posts, reels, stories)
- Facebook (videos, posts)
- TikTok
- YouTube
- Twitter/X
- And many more...

## Troubleshooting

### yt-dlp not found
Make sure yt-dlp is installed:
```bash
pip install yt-dlp
```

### Video requires login
Some videos are private. Users need to log in through the app's WebView first.

### Timeout errors
Increase timeout in `server.py` if needed (currently 60 seconds).

## Why yt-dlp?

- **Industry standard** - Used by top Play Store apps
- **Actively maintained** - Regular updates for new sites
- **Reliable** - Handles edge cases and anti-bot measures
- **Fast** - Direct URL extraction without full download
- **Wide support** - 1000+ supported sites
