# 🎬 VUTA - Pull the Web to Your Pocket

<div align="center">

![VUTA Logo](vuta_app/assets/images/vuta_logo.png)

**A powerful Android application for downloading videos and media from social media platforms**

[![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red)]()

</div>

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Building](#-building)
- [Usage](#-usage)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

### 🎯 Core Functionality
- **Multi-Platform Support**: Download videos from Instagram, Facebook, and direct media URLs
- **Smart URL Detection**: Automatically detects and processes social media links
- **Web Extraction**: Built-in WebView for extracting videos from protected pages
- **Background Downloads**: Queue downloads to run in the background
- **Download History**: Track all your downloaded media
- **Night Queue**: Schedule downloads for off-peak hours (Pro feature)

### 🚀 Advanced Features
- **Resolver Backend**: Optional Python backend powered by **yt-dlp** (industry-standard extractor used by top Play Store apps)
- **Wide Platform Support**: Supports 1000+ sites including Instagram, Facebook, TikTok, YouTube, and more
- **WhatsApp Integration**: Direct sharing to WhatsApp (Pro feature)
- **Pro Features**: Unlock advanced capabilities with in-app purchases
- **Ad-Supported**: Free tier with optional ad removal
- **Modern UI**: Beautiful dark theme with smooth animations

---

## 🏗️ Architecture

VUTA is built with a modern, modular architecture:

### Frontend (Flutter App)
- **Framework**: Flutter 3.9+ with Dart
- **State Management**: Riverpod for reactive state management
- **Storage**: SharedPreferences for lightweight data, MediaStore for downloads
- **Networking**: Dio for HTTP requests
- **Background Tasks**: WorkManager for background processing

### Backend (Optional Resolver)
- **Runtime**: Python 3.9+ with Flask
- **Extractor**: yt-dlp (industry-standard, used by top Play Store apps)
- **Purpose**: Resolves video URLs from social media platforms using proven extraction methods

### Key Components
```
vuta_app/
├── lib/
│   ├── core/              # Core utilities, parsers, theme
│   ├── features/           # Feature modules (home, downloads, history, etc.)
│   ├── services/          # Background services (ads, billing, resolver)
│   └── widgets/           # Reusable UI components
└── android/               # Android-specific configuration

resolver_backend/
├── server.js              # Express server with Playwright
└── Dockerfile             # Container configuration
```

---

## 📦 Prerequisites

### For Development
- **Flutter SDK** 3.9.0 or higher
- **Dart SDK** 3.9.0 or higher
- **Android Studio** (latest version recommended)
- **Android SDK** (API level 21+)
- **Java Development Kit (JDK)** 11 or higher
- **Git** for version control

### For Resolver Backend (Optional)
- **Python** 3.9 or higher
- **pip** (Python package manager)
- **yt-dlp** (installed automatically via requirements.txt)

### For Building
- **Gradle** 7.5+ (included in Android project)
- **Android NDK** (optional, for native code)

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/gideongeny/Vuta.git
cd Vuta
```

### 2. Install Flutter Dependencies

```bash
cd vuta_app
flutter pub get
```

### 3. Install Resolver Backend Dependencies (Optional)

```bash
cd resolver_backend
pip install -r requirements.txt
```

### 4. Configure Android

The Android project is pre-configured. If you encounter issues:

```bash
cd vuta_app/android
# Flutter will automatically configure local.properties
```

---

## ⚙️ Configuration

### App Configuration

#### Resolver Backend URL
The app can connect to an optional resolver backend for advanced video extraction:

1. Open the app
2. Navigate to Settings (gear icon)
3. Enter your resolver backend URL (default: `http://10.0.2.2:8080` for Android emulator)

#### API Key (Optional)
If your resolver backend requires authentication:

1. Set environment variable: `RESOLVER_API_KEY=your_secret_key`
2. Or configure in the app settings

### Build Configuration

#### Release Signing
Currently configured with debug keystore. For Play Store release:

1. Generate a release keystore:
```bash
keytool -genkey -v -keystore ~/vuta-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vuta
```

2. Create `vuta_app/android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=vuta
storeFile=/path/to/vuta-release-key.jks
```

3. Update `vuta_app/android/app/build.gradle.kts` to use the keystore

---

## 🔨 Building

### Development Build

```bash
cd vuta_app
flutter run
```

### Release APK

```bash
cd vuta_app
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Release App Bundle (Play Store)

```bash
cd vuta_app
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Resolver Backend

#### Local Development

**Windows (Easiest):**
```powershell
cd resolver_backend
.\start_backend.ps1
```

Or double-click `start_backend.bat`

**Background Mode (Recommended):**
```powershell
.\start_backend_background.ps1
```

**Manual Start:**
```bash
cd resolver_backend
python server.py
```

Server runs on `http://localhost:8080` by default.

**Note**: Make sure Python 3.9+ is installed. Dependencies will be installed automatically.

**Auto-Start on Windows Login:**
See `resolver_backend/SETUP_GUIDE.md` for detailed instructions on setting up automatic startup.

#### Docker Deployment
```bash
cd resolver_backend
docker build -t vuta-resolver .
docker run -p 8080:8080 -e RESOLVER_API_KEY=your_key vuta-resolver
```

**Note**: The Docker image includes Python, Flask, and yt-dlp pre-installed.

---

## 📱 Usage

### Basic Download Flow

1. **Paste URL**: Copy a social media link (Instagram, Facebook, etc.)
2. **Detect & Download**: Tap "DETECT & DOWNLOAD" button
3. **Extract (if needed)**: For protected content, the app opens a WebView
   - Log in to the platform if required
   - Wait for the video to load
   - Tap "EXTRACT" button
   - The app will automatically find and download the video
4. **View Downloads**: Navigate to Downloads screen to see progress

### Tips for Best Results

- **Wait for Video to Load**: Before tapping Extract, ensure the video is fully loaded and playing
- **Login Required**: Some platforms require login - use the WebView to authenticate
- **Resolver Backend**: For blob URLs and protected streams, set up the resolver backend
- **Network Connection**: Ensure stable internet connection for downloads

### Troubleshooting Extraction

If extraction fails:

1. **Check Login Status**: Make sure you're logged in to the platform
2. **Wait for Video**: Let the video fully load before extracting
3. **Retry**: Tap Extract again after the page fully loads
4. **Resolver Backend**: For blob URLs, ensure resolver backend is running
5. **Check URL**: Verify the URL is accessible and the content is public

---

## 🔧 Troubleshooting

### Common Issues

#### "Storage permission denied"
- **Solution**: Grant storage permissions when prompted
- Go to Android Settings → Apps → VUTA → Permissions → Storage

#### "No video URL found"
- **Causes**:
  - Video not loaded yet
  - Requires login
  - Protected/private content
  - Blob URL (needs resolver backend)
- **Solutions**:
  1. Wait for video to fully load
  2. Log in through the WebView
  3. Ensure content is public
  4. Set up resolver backend for blob URLs

#### "Could not resolve stream"
- **Cause**: Resolver backend not running or unreachable
- **Solutions**:
  1. Check resolver backend is running: `curl http://localhost:8080/health`
  2. Verify URL in app settings matches backend URL
  3. For emulator: use `http://10.0.2.2:8080`
  4. For physical device: use your computer's IP address
  5. Ensure Python 3.9+ and yt-dlp are installed: `pip install yt-dlp`

#### Build Errors

**Gradle sync failed**
```bash
cd vuta_app/android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Flutter SDK not found**
- Ensure Flutter is in your PATH
- Run `flutter doctor` to diagnose issues
- Android Studio should auto-detect Flutter SDK

#### App Crashes

1. Check logs: `flutter logs` or Android Studio Logcat
2. Clear app data: Settings → Apps → VUTA → Clear Data
3. Reinstall: Uninstall and reinstall the app

---

## 📁 Project Structure

```
Vuta/
├── vuta_app/                    # Flutter application
│   ├── lib/
│   │   ├── core/                # Core functionality
│   │   │   ├── download_engine.dart
│   │   │   ├── social_parser.dart
│   │   │   ├── theme.dart
│   │   │   └── widgets/
│   │   ├── features/            # Feature modules
│   │   │   ├── downloads/      # Download management
│   │   │   ├── history/         # Download history
│   │   │   ├── home/            # Home screen
│   │   │   ├── night_queue/     # Scheduled downloads
│   │   │   ├── pro/             # Pro features
│   │   │   ├── settings/        # App settings
│   │   │   ├── web_extract/     # WebView extraction
│   │   │   └── whatsapp/        # WhatsApp integration
│   │   ├── services/            # Background services
│   │   │   ├── ads_service.dart
│   │   │   ├── background_tasks.dart
│   │   │   ├── billing_service.dart
│   │   │   ├── resolver_service.dart
│   │   │   └── ...
│   │   ├── widgets/             # Reusable widgets
│   │   └── main.dart            # App entry point
│   ├── android/                 # Android configuration
│   ├── assets/                   # Images, fonts, etc.
│   └── pubspec.yaml             # Flutter dependencies
│
├── resolver_backend/            # Optional Python backend
│   ├── server.py                # Flask server with yt-dlp
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile               # Docker configuration
│   └── README.md                # Backend documentation
│
├── image/                        # Project images
└── README.md                     # This file
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Code Style
- Follow Dart/Flutter style guidelines
- Run `flutter analyze` before committing
- Write meaningful commit messages
- Add comments for complex logic

### Reporting Issues
When reporting issues, please include:
- Device/OS version
- App version
- Steps to reproduce
- Expected vs actual behavior
- Logs (if applicable)

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Riverpod** for state management
- **Playwright** for browser automation
- All open-source contributors whose packages made this possible

---

## 📞 Support

For issues, questions, or contributions:
- **GitHub Issues**: [Create an issue](https://github.com/gideongeny/Vuta/issues)
- **Repository**: [https://github.com/gideongeny/Vuta](https://github.com/gideongeny/Vuta)

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ Star this repo if you find it helpful!

</div>
