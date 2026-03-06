# Changelog

## v0.6.0 — Electron + Capacitor Native Release

### Platform overhaul — ditched Flutter, replaced with Electron + Capacitor
- **Windows** builds to a real `.exe` NSIS installer (no browser, no Flutter)
- **macOS** builds to a signed `.dmg`
- **Linux** builds to `.deb`, `.AppImage`, and `.rpm`
- **Android** builds to `.apk` via Capacitor + Gradle (dedicated `build_apk.bat`)
- **iOS** builds to `.ipa` via Capacitor + Xcode

### New app icon
- Redesigned icon: plate + fork + knife + bold F lettermark
- Light mode icon (warm white + dark forest green) used as the default install icon on all platforms
- Dark mode icon (dark bg + lime green) available in `resources/icon_dark.png`
- All platform icon formats auto-generated: `.ico` (Windows), `.icns` (macOS), mipmap folders (Android), `AppIcon.appiconset` (iOS/iPadOS)

### Themes
- **Light mode is now the default** on first launch
- CSS root variables match light mode so there is zero dark flash before JavaScript loads
- Settings toggle correctly shows 🌙 / ☀️ depending on current theme
- User's theme preference is saved and persists across restarts and upgrades

### Data persistence — upgrade safe on all platforms
- Data is stored outside the app install directory on every platform — upgrading or reinstalling **never** overwrites user data
  - Windows: `%APPDATA%\fuelle\fuelle_data.json`
  - macOS: `~/Library/Application Support/fuelle/fuelle_data.json`
  - Linux: `~/.config/fuelle/fuelle_data.json`
  - Android: Capacitor Preferences (app private storage, survives APK upgrades)
  - iOS: Capacitor Preferences (app private storage, survives App Store updates)
- Fixed a silent bug where Electron file storage was never actually used (IPC is async; the old code called it synchronously and always fell through to localStorage)
- Data now triple-writes on every save: native file/Preferences + localStorage backup
- Async init: app waits for data to load before first render, so no missed state on startup

### Font size setting fixed
- All CSS font sizes converted from hardcoded `px` to `rem`
- `setFontSize(13/15/18)` now correctly scales the entire UI as intended

### Build system
- `build.bat` — Windows desktop build (checks for Node.js, clear error if missing)
- `build_apk.bat` — dedicated Android APK builder (checks Node, Java 17, Android SDK)
- `build.sh` — macOS / Linux desktop build
- README updated with Node.js install requirement front and center

---

## v0.5.0 — Alpha (Flutter)

### Initial alpha release
- Meal logging: Breakfast, Lunch, Dinner, Snacks
- USDA FoodData Central food search
- Portion size input per food
- Daily calorie/carb/protein/fat tracking with progress indicators
- Day navigation (forwards/backwards)
- Week view with logged day indicators
- History view with 7-day averages
- Custom nutrition goals (cal, carb, protein, fat)
- Export/Import backup code system (FUELLE1: format)
- Dark and Light mode
- Adjustable text size
- Flutter-based: Windows, macOS, Linux, Android, iOS
