const { contextBridge, ipcRenderer } = require('electron');

// Expose a safe subset of APIs to the renderer (index.html)
contextBridge.exposeInMainWorld('electronAPI', {
  loadData: () => ipcRenderer.invoke('load-data'),
  saveData: (json) => ipcRenderer.invoke('save-data', json),
  openExternal: (url) => ipcRenderer.invoke('open-external', url),
});
