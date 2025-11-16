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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBn_4_example_key',
    appId: '1:439851419572:web:example',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    authDomain: 'katenka-74591.firebaseapp.com',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBn_4_example_key',
    appId: '1:439851419572:android:example',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBn_4_example_key',
    appId: '1:439851419572:ios:example',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.time',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBn_4_example_key',
    appId: '1:439851419572:macos:example',
    messagingSenderId: '439851419572',
    projectId: 'katenka-74591',
    databaseURL: 'https://katenka-74591-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.time',
  );
}
