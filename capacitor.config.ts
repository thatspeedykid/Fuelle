import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.privacychase.fuelle',
  appName: 'fuelle',
  webDir: 'www',
  bundledWebRuntime: false,
  server: {
    // No external server - loads bundled files only
    iosScheme: 'capacitor',
    androidScheme: 'https',
  },
  plugins: {
    // Capacitor preferences (native key-value storage)
    Preferences: {
      group: 'com.privacychase.fuelle'
    },
    SplashScreen: {
      launchShowDuration: 800,
      backgroundColor: '#0e0f0d',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#0e0f0d',
    },
  },
  ios: {
    contentInset: 'always',
    scrollEnabled: false,
  },
  android: {
    allowMixedContent: false,
    captureInput: true,
    webContentsDebuggingEnabled: false,
  },
};

export default config;
