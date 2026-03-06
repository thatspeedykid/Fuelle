# fuelle 🥗

**Privacy-first meal planner & nutrition tracker — by PrivacyChase**

> No accounts. No servers. No tracking. No ads. Your food data is yours.

---

## ⚠️ Requirement: install Node.js before building

**All builds require Node.js.** Install it first, everything else is automatic.

👉 **https://nodejs.org/en/download** — choose the LTS Windows Installer (.msi)

Verify: open a new Command Prompt and type `node --version` — should show `v20.x.x`

---

## Build — Windows (.exe installer)

1. Install Node.js (above)
2. Double-click **`build.bat`**
3. Installer at `dist-electron\fuelle Setup 0.6.0.exe`

---

## Build — Android (.apk)

**Also requires:**
- **Java 17** → https://adoptium.net (Temurin 17, Windows x64)
- **Android Studio** → https://developer.android.com/studio (open it once to finish SDK setup)

1. Install Node.js, Java 17, Android Studio
2. Double-click **`build_apk.bat`**
3. APK at `capacitor-mobile\android\app\build\outputs\apk\debug\app-debug.apk`
4. To install: enable "Install from unknown sources" on your device, copy APK, tap to install

---

## Build — macOS (.dmg)

1. Install Node.js
2. Open Terminal here:
```
bash build.sh mac
```
3. App at `dist-electron/fuelle-0.6.0.dmg`

---

## Build — Linux (.deb / AppImage / rpm)

1. Install Node.js:
```
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```
2. Run:
```
bash build.sh linux
```
3. Packages at `dist-electron/`

---

## Build — iOS (.ipa)

Requires Mac + Xcode + Apple Developer account ($99/yr) or AltStore for free personal sideloading.

1. Install Node.js
2. Open Terminal:
```
cd capacitor-mobile
npm install
npx cap sync ios
npx cap open ios
```
3. In Xcode: select your Team → Product → Archive → Distribute App → export `.ipa`

**Free sideloading with AltStore:** export with Development signing, use AltStore or Sideloadly.

---

## Your data is safe across upgrades

Data is stored **outside** the app install directory on every platform. Upgrading or reinstalling fuelle **never** touches your food logs.

| Platform | Data location |
|----------|--------------|
| Windows  | `%APPDATA%\fuelle\fuelle_data.json` |
| macOS    | `~/Library/Application Support/fuelle/` |
| Linux    | `~/.config/fuelle/` |
| Android  | App private storage (Capacitor Preferences) |
| iOS      | App private storage (Capacitor Preferences) |

---

## Project layout

```
fuelle-native/
├── www/index.html          ← Entire app — shared by all platforms
├── electron/src/           ← Desktop wrapper (Electron)
├── capacitor-mobile/       ← Mobile wrapper (Capacitor)
│   ├── android/
│   └── ios/
├── resources/              ← Icons for all platforms (pre-generated)
│   ├── icon.png            ← Light mode icon (default, 1024×1024)
│   ├── icon_dark.png       ← Dark mode icon
│   ├── icon.ico            ← Windows
│   ├── icon.icns           ← macOS
│   └── icons/             ← Linux (16px–512px)
├── CHANGELOG.md
├── build.bat               ← Windows desktop build
├── build_apk.bat           ← Android APK build
└── build.sh                ← macOS / Linux build
```

---

## Part of the PrivacyChase Suite

| App | Description |
|-----|-------------|
| [Flowe](https://github.com/privacychase/flowe) | Personal finance tracker |
| **Fuelle** | Meal planner & nutrition tracker |

MIT License — by PrivacyChase
