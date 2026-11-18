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
        return android;
      case TargetPlatform.iOS:
        return ios;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDaue38S4U3MSDmcfc6zYcooPwzC9BOOVA',
    appId: '1:381980641519:android:cf2ae909a9ddd5c102331a',
    messagingSenderId: '381980641519',
    projectId: 'cebinden-eve',
    storageBucket: 'cebinden-eve.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDCrG4qwT3ENOpTiZnWP8i_85qXJCtD8Ys',
    appId: '1:381980641519:ios:17a20ce104194fc302331a',
    messagingSenderId: '381980641519',
    projectId: 'cebinden-eve',
    storageBucket: 'cebinden-eve.firebasestorage.app',
    iosClientId:
        '381980641519-es124c8r69qlf4sdlgkv6eo00nk55geh.apps.googleusercontent.com',
    iosBundleId: 'com.cebindeneve.app',
  );

  /// Google ile girişte Firebase'in doğruladığı web OAuth istemcisi.
  static const String googleServerClientId =
      '381980641519-hskendkgt9ivm58pp0rkdus1cti9d0se.apps.googleusercontent.com';
}
