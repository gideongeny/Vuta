# VUTA Backend Setup Guide

## Quick Start

### Option 1: Simple Start (Recommended for Development)
Double-click `start_backend.bat` or run:
```powershell
.\start_backend.ps1
```

### Option 2: Background Process (Recommended for Daily Use)
Run in PowerShell:
```powershell
.\start_backend_background.ps1
```

This starts the backend in the background. To stop it:
```powershell
.\stop_backend.ps1
```

## Automatic Startup (Windows)

### Method 1: Task Scheduler (Recommended)

1. Open **Task Scheduler** (search in Windows)
2. Click **Create Basic Task**
3. Name it: "VUTA Resolver Backend"
4. Trigger: **When I log on**
5. Action: **Start a program**
6. Program: `python`
7. Arguments: `server.py`
8. Start in: `C:\Users\mukht\Desktop\Android\Vuta\resolver_backend`
9. Check **"Run whether user is logged on or not"**
10. Click **Finish**

### Method 2: Startup Folder

1. Press `Win + R`
2. Type: `shell:startup`
3. Create a shortcut to `start_backend_background.ps1`
4. Right-click shortcut → Properties
5. Change target to:
   ```
   powershell.exe -ExecutionPolicy Bypass -File "C:\Users\mukht\Desktop\Android\Vuta\resolver_backend\start_backend_background.ps1"
   ```

### Method 3: Windows Service (Advanced)

For production use, you can install it as a Windows service using `nssm` (Non-Sucking Service Manager):

1. Download NSSM: https://nssm.cc/download
2. Extract and run: `nssm install VutaResolver`
3. Configure:
   - Path: `C:\Python311\python.exe` (or your Python path)
   - Startup directory: `C:\Users\mukht\Desktop\Android\Vuta\resolver_backend`
   - Arguments: `server.py`
4. Start service: `nssm start VutaResolver`

## Testing the Backend

### Health Check
```powershell
curl http://localhost:8080/health
```

Should return: `{"ok":true}`

### Test Video Extraction
```powershell
curl -X POST http://localhost:8080/resolve -H "Content-Type: application/json" -d '{\"url\":\"https://www.instagram.com/p/YOUR_POST_ID/\"}'
```

## Configuration

### Change Port
Edit `server.py` and change:
```python
port = int(os.environ.get('PORT', 8080))
```

Or set environment variable:
```powershell
$env:PORT = 3000
python server.py
```

### Add API Key (Optional)
```powershell
$env:RESOLVER_API_KEY = "your-secret-key"
python server.py
```

## Troubleshooting

### Port Already in Use
If port 8080 is busy, change it:
```powershell
$env:PORT = 8081
python server.py
```

Then update the app settings to use the new port.

### Python Not Found
Make sure Python is in your PATH:
```powershell
python --version
```

If not found, add Python to PATH or use full path:
```powershell
C:\Python311\python.exe server.py
```

### Dependencies Missing
Reinstall dependencies:
```powershell
python -m pip install -r requirements.txt
```

### Backend Not Accessible from App

**For Android Emulator:**
- Use: `http://10.0.2.2:8080`

**For Physical Device:**
1. Find your computer's IP: `ipconfig` (look for IPv4 Address)
2. Use: `http://YOUR_IP:8080` (e.g., `http://192.168.1.100:8080`)
3. Make sure Windows Firewall allows connections on port 8080

### Firewall Configuration
1. Open **Windows Defender Firewall**
2. Click **Allow an app through firewall**
3. Add Python or allow port 8080

## Logs

The backend outputs logs to the console. For background processes, you can redirect to a file:

```powershell
python server.py > backend.log 2>&1
```

## Stopping the Backend

### If running in foreground:
Press `Ctrl+C`

### If running in background:
```powershell
.\stop_backend.ps1
```

Or find and kill the process:
```powershell
Get-Process python | Where-Object {$_.Path -like "*resolver_backend*"} | Stop-Process
```
