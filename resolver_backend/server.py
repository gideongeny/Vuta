#!/usr/bin/env python3
"""
VUTA Resolver Backend using yt-dlp
yt-dlp is the industry-standard extractor used by top Play Store apps
"""

import os
import json
import subprocess
from flask import Flask, request, jsonify
from flask_cors import CORS
from typing import Optional, Dict, Any

app = Flask(__name__)
CORS(app)

REQUIRED_API_KEY = os.environ.get('RESOLVER_API_KEY', '').strip()

def is_authorized(req) -> bool:
    """Check if request is authorized"""
    if not REQUIRED_API_KEY:
        return True
    auth_header = req.headers.get('Authorization', '').strip()
    if not auth_header.lower().startswith('bearer '):
        return False
    token = auth_header[7:].strip()
    return token == REQUIRED_API_KEY

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'ok': True})

@app.route('/resolve', methods=['POST'])
def resolve():
    """Resolve video URL using yt-dlp"""
    if not is_authorized(request):
        return jsonify({'ok': False, 'error': 'Unauthorized'}), 401

    data = request.get_json() or {}
    url = data.get('url', '').strip()
    
    if not url:
        return jsonify({'ok': False, 'error': 'Missing url'}), 400

    try:
        # Use yt-dlp to extract video URL
        # -g: get URL only (no download)
        # --no-playlist: single video only
        # --format: prefer mp4, fallback to best video
        # --no-warnings: suppress warnings
        cmd = [
            'yt-dlp',
            '-g',  # Get URL only
            '--no-playlist',  # Single video
            '--format', 'best[ext=mp4]/best',  # Prefer mp4, fallback to best
            '--no-warnings',
            '--no-check-certificate',  # Some sites have cert issues
            url
        ]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60,  # 60 second timeout
            check=False
        )

        if result.returncode != 0:
            error_msg = result.stderr or result.stdout or 'Unknown error'
            # Try to extract useful error message
            if 'Private video' in error_msg or 'Sign in' in error_msg:
                return jsonify({
                    'ok': False,
                    'error': 'Video is private or requires login. Please log in through the app first.'
                }), 422
            elif 'Unsupported URL' in error_msg or 'No video' in error_msg:
                return jsonify({
                    'ok': False,
                    'error': 'Unsupported URL or no video found'
                }), 422
            else:
                return jsonify({
                    'ok': False,
                    'error': f'Extraction failed: {error_msg[:200]}'
                }), 422

        video_url = result.stdout.strip()
        
        if not video_url:
            return jsonify({
                'ok': False,
                'error': 'No video URL found'
            }), 422

        # Determine video type
        video_type = 'mp4'
        if '.m3u8' in video_url.lower():
            video_type = 'm3u8'
        elif '.webm' in video_url.lower():
            video_type = 'webm'
        elif '.mov' in video_url.lower():
            video_type = 'mov'

        return jsonify({
            'ok': True,
            'url': video_url,
            'type': video_type
        })

    except subprocess.TimeoutExpired:
        return jsonify({
            'ok': False,
            'error': 'Request timeout. The video extraction took too long.'
        }), 504
    except Exception as e:
        return jsonify({
            'ok': False,
            'error': f'Server error: {str(e)}'
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
