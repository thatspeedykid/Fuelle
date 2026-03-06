ICONS — Add these files here before building:

  icon.png   1024x1024 PNG  (source — used for Linux + as base)
  icon.ico   Windows ICO    (multi-size: 16,32,48,64,128,256)
  icon.icns  macOS ICNS     (macOS only)

QUICK ICON GENERATION (once you have icon.png):
  npm install -g electron-icon-builder
  electron-icon-builder --input=resources/icon.png --output=resources

The fuelle icon.png from the original assets/ folder can be used directly.
