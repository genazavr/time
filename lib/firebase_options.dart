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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAx5J_U2NoGAtdxF9WwDnIbOBfiNs2wcjU',
    appId: '1:439851419572:web:ef9f9ef2dbfa0f346a94e1',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    authDomain: 'katenka-74591.firebaseapp.com',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
    storageBucket: 'katenka-74591.firebasestorage.app',
    measurementId: 'G-8LHG1CYX80',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-FJ--DQVflP9oqbfOsBITq9426w3YwlA',
    appId: '1:439851419572:android:f1a77c0f05793a296a94e1',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
    storageBucket: 'katenka-74591.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAY_bSzgHx646SfbO2X03vquCE6IhOfpr4',
    appId: '1:439851419572:ios:95ddcf513f1b35bb6a94e1',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
    storageBucket: 'katenka-74591.firebasestorage.app',
    iosBundleId: 'com.example.time',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAY_bSzgHx646SfbO2X03vquCE6IhOfpr4',
    appId: '1:439851419572:ios:95ddcf513f1b35bb6a94e1',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
    storageBucket: 'katenka-74591.firebasestorage.app',
    iosBundleId: 'com.example.time',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAx5J_U2NoGAtdxF9WwDnIbOBfiNs2wcjU',
    appId: '1:439851419572:web:b6d8813b888b745d6a94e1',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    authDomain: 'katenka-74591.firebaseapp.com',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
    storageBucket: 'katenka-74591.firebasestorage.app',
    measurementId: 'G-TEXCL3KY32',
  );

}