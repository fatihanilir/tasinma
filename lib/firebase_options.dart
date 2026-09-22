// File generated for Cebinden Eve Firebase project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android app henüz Firebase'e eklenmedi — web config ile dene
        return web;
      case TargetPlatform.iOS:
        return web;
      case TargetPlatform.macOS:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSyPqiaK_5jHws9BUj6VreUt9MZ0CB7bI',
    appId: '1:381980641519:web:b661b6f9ea31b9ac02331a',
    messagingSenderId: '381980641519',
    projectId: 'cebinden-eve',
    authDomain: 'cebinden-eve.firebaseapp.com',
    storageBucket: 'cebinden-eve.firebasestorage.app',
    measurementId: 'G-B7EN4KEE69',
  );
}
