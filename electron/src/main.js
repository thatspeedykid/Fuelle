const { app, BrowserWindow, ipcMain, shell } = require('electron');
const path = require('path');
const fs   = require('fs');

// ── Data paths ────────────────────────────────────────────────────────────────
// userData is OUTSIDE the install directory — it is NEVER touched by the
// installer, uninstaller, or an upgrade. It belongs entirely to the user.
//
//   Windows : %APPDATA%\fuelle\fuelle_data.json
//   macOS   : ~/Library/Application Support/fuelle/fuelle_data.json
//   Linux   : ~/.config/fuelle/fuelle_data.json

const userDataDir = app.getPath('userData');
const dataFile    = path.join(userDataDir, 'fuelle_data.json');
const backupFile  = path.join(userDataDir, 'fuelle_data.backup.json');

// ── Ensure userData directory exists ─────────────────────────────────────────
function ensureDir() {
  if (!fs.existsSync(userDataDir)) {
    fs.mkdirSync(userDataDir, { recursive: true });
  }
}

// ── Load ──────────────────────────────────────────────────────────────────────
function loadData() {
  ensureDir();
  // Try primary file first
  if (fs.existsSync(dataFile)) {
    try {
      const raw = fs.readFileSync(dataFile, 'utf8');
      JSON.parse(raw); // validate — if corrupt, fall through to backup
      return raw;
    } catch (e) {
      console.warn('fuelle: primary data file corrupt, trying backup...');
    }
  }
  // Try backup
  if (fs.existsSync(backupFile)) {
    try {
      const raw = fs.readFileSync(backupFile, 'utf8');
      JSON.parse(raw);
      console.log('fuelle: restored from backup.');
      return raw;
    } catch (e) {
      console.warn('fuelle: backup also corrupt.');
    }
  }
  return null; // new install — app will use defaultData()
}

// ── Save ──────────────────────────────────────────────────────────────────────
function saveData(json) {
  ensureDir();
  try {
    // 1. Validate incoming JSON before writing anything
    JSON.parse(json);

    // 2. Rotate current file to backup BEFORE overwriting
    if (fs.existsSync(dataFile)) {
      fs.copyFileSync(dataFile, backupFile);
    }

    // 3. Write atomically: write to .tmp, then rename
    const tmpFile = dataFile + '.tmp';
    fs.writeFileSync(tmpFile, json, 'utf8');
    fs.renameSync(tmpFile, dataFile);

  } catch (e) {
    console.error('fuelle: save failed:', e);
  }
}

// ── IPC ───────────────────────────────────────────────────────────────────────
ipcMain.handle('load-data',      ()       => loadData());
ipcMain.handle('save-data',      (_, j)   => saveData(j));
ipcMain.handle('open-external',  (_, url) => shell.openExternal(url));

// ── Window ────────────────────────────────────────────────────────────────────
function createWindow() {
  const win = new BrowserWindow({
    width:    900,
    height:   680,
    minWidth: 320,
    minHeight:500,
    title:    'fuelle',
    backgroundColor: '#f5f5f0',
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    icon: path.join(__dirname, '..', '..', 'resources', 'icon.png'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  win.loadFile(path.join(__dirname, '..', '..', 'www', 'index.html'));
  win.setMenu(null);

  if (process.env.NODE_ENV === 'development') win.webContents.openDevTools();
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
