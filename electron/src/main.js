const { app, BrowserWindow, ipcMain, shell, nativeTheme } = require('electron');
const path = require('path');
const fs = require('fs');

// ── Data file location (next to app, in userData) ─────────────────────────────
const dataFile = path.join(app.getPath('userData'), 'fuelle_data.json');

function loadData() {
  // Data lives in userData — a directory that installers NEVER overwrite.
  // Windows: %APPDATA%\fuelle\fuelle_data.json
  // macOS:   ~/Library/Application Support/fuelle/fuelle_data.json
  // Linux:   ~/.config/fuelle/fuelle_data.json
  // Upgrading or reinstalling the app does NOT touch this folder.
  try {
    if (fs.existsSync(dataFile)) return fs.readFileSync(dataFile, 'utf8');
  } catch (e) {
    console.error('fuelle: failed to load data:', e);
  }
  return null;
}

function saveData(json) {
  try {
    // Ensure the userData directory exists (first run after install)
    const dir = path.dirname(dataFile);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(dataFile, json, 'utf8');
  } catch (e) {
    console.error('fuelle: failed to save data:', e);
  }
}

// ── IPC handlers ──────────────────────────────────────────────────────────────
ipcMain.handle('load-data', () => loadData());
ipcMain.handle('save-data', (_, json) => saveData(json));
ipcMain.handle('open-external', (_, url) => shell.openExternal(url));

// ── Create window ─────────────────────────────────────────────────────────────
function createWindow() {
  const win = new BrowserWindow({
    width: 900,
    height: 680,
    minWidth: 320,
    minHeight: 500,
    title: 'fuelle',
    backgroundColor: '#f5f5f0',
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    // macOS icon
    icon: path.join(__dirname, '..', 'resources', 'icon.png'),
  });

  win.loadFile(path.join(__dirname, '..', '..', 'www', 'index.html'));

  // Remove default menu on all platforms
  win.setMenu(null);

  // Open DevTools only in dev mode
  if (process.env.NODE_ENV === 'development') win.webContents.openDevTools();
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
