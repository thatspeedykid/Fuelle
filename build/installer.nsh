# fuelle custom NSIS hooks
# This file is included by electron-builder automatically when placed here.
# It ensures user data in %APPDATA%\fuelle is NEVER touched during
# install, upgrade, or uninstall.

!macro customUnInstall
  # Explicitly do NOT delete user data on uninstall.
  # %APPDATA%\fuelle\fuelle_data.json is never removed.
  # The user must manually delete it if they want to wipe their data.
!macroend

!macro customInstall
  # On fresh install or upgrade, never overwrite user data.
  # fuelle_data.json lives in %APPDATA%\fuelle\ which this installer
  # never writes to — only the app itself reads/writes it at runtime.
!macroend
