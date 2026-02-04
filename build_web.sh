#!/bin/bash
# Ensure firebase_options.dart exists before building
cat > lib/firebase_options.dart << 'DART'
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return web;
      case TargetPlatform.iOS:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSyKT-opa0TG-2zEkkK2D1AOgACxEee3U',
    appId: '1:659724352916:web:8069fc283a6d9e4e28e381',
    messagingSenderId: '659724352916',
    projectId: 'inventorymanager-dev-20262',
    authDomain: 'inventorymanager-dev-20262.firebaseapp.com',
    storageBucket: 'inventorymanager-dev-20262.firebasestorage.app',
  );
}
DART

export PATH="$HOME/flutter/bin:$PATH"
flutter build web --base-href="/vault-app/" --release "$@"
