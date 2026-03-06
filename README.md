# fuelle 🥗

**Privacy-first meal planner & nutrition tracker — by PrivacyChase**

> No accounts. No servers. No tracking. No ads. Your food data is yours.

---

## ⚠️ Requirement: install Node.js before building anything

👉 **https://nodejs.org/en/download**

- **Windows** — download the `.msi` LTS installer, run it, done
- **macOS** — download the `.pkg` LTS installer, run it, done. Do NOT use Homebrew.
- **Linux** — run these two commands:
  ```
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  ```

After installing, open a **new** terminal and verify: `node --version`

---

## Windows — desktop .exe installer

1. Install Node.js (above)
2. Double-click **`build.bat`**
3. Installer at `dist-electron\fuelle Setup 0.6.0.exe`

---

## macOS — desktop .dmg

1. Install Node.js `.pkg` from https://nodejs.org/en/download
2. Open Terminal in this folder and run:
   ```
   bash build_mac.sh
   ```
3. App at `dist-electron/fuelle-0.6.0.dmg`

---

## Linux — desktop .deb / AppImage

1. Install Node.js (commands above)
2. Open a terminal in this folder and run:
   ```
   bash build_linux.sh
   ```
   Or from file manager: right-click `build_linux.sh` → Properties → Permissions → Allow executing as program → double-click
3. Packages in `dist-electron/`
   - Install .deb: `sudo dpkg -i dist-electron/*.deb`
   - Run AppImage: `chmod +x dist-electron/*.AppImage && ./dist-electron/*.AppImage`

---

## Android — .apk

**Also requires:**
- **Java 17+** → https://adoptium.net (Temurin 17, Windows x64)
- **Android Studio** → https://developer.android.com/studio
  Open it once after installing so it downloads the Android SDK automatically.

1. Install all three (Node.js, Java 17, Android Studio)
2. Double-click **`build_apk.bat`**
3. APK at `capacitor-mobile\android\app\build\outputs\apk\debug\app-debug.apk`
4. Install on device: enable "Install from unknown sources" in Settings, copy APK, tap it

> **Note:** Java 8 will NOT work. Must be Java 17 or newer.

---

## iOS — .ipa

Requires Mac + Xcode + Apple Developer account ($99/yr), or AltStore for free personal sideloading.

1. Install Node.js
2. Open Terminal in the `capacitor-mobile/` folder:
   ```
   npm install
   npx cap sync ios
   npx cap open ios
   ```
3. In Xcode: select your Team → Product → Archive → Distribute App → export `.ipa`

**Free sideloading:** export with Development signing, use AltStore or Sideloadly to install.

---

## Your data is never deleted by installs or upgrades

Data is stored outside the app install folder on every platform:

| Platform | Data location |
|----------|--------------|
| Windows  | `%APPDATA%\fuelle\fuelle_data.json` |
| macOS    | `~/Library/Application Support/fuelle/fuelle_data.json` |
| Linux    | `~/.config/fuelle/fuelle_data.json` |
| Android  | App private storage (survives APK upgrades) |
| iOS      | App private storage (survives App Store updates) |

A backup copy (`fuelle_data.backup.json`) is kept alongside the main file. If the main file is ever corrupted, the app automatically recovers from the backup.

---

## Project layout

```
fuelle-native/
├── www/index.html              ← Entire app — shared by all platforms
├── electron/src/               ← Desktop wrapper (Electron)
├── capacitor-mobile/           ← Mobile wrapper (Capacitor)
│   ├── capacitor.config.json   ← Points webDir to ../www
│   ├── android/
│   └── ios/
├── resources/                  ← Icons for all platforms
├── build.bat                   ← Windows desktop build
├── build_apk.bat               ← Android APK build
├── build_mac.sh                ← macOS build
├── build_linux.sh              ← Linux build
└── build.sh                    ← Core build logic (called by above)
```

---

## Part of the PrivacyChase Suite

| App | Description |
|-----|-------------|
| [Flowe](https://github.com/privacychase/flowe) | Personal finance tracker |
| **Fuelle** | Meal planner & nutrition tracker |

MIT License — by PrivacyChase
