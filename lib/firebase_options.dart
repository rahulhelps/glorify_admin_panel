import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDg23MwwrkXto2fpJnPJlFSFjk8wf8LNoU',
    appId: '1:233059619721:android:8521112a1f4efb20e24758',
    messagingSenderId: '233059619721',
    projectId: 'life-change-78727',
    databaseURL: 'https://life-change-78727-default-rtdb.firebaseio.com',
    storageBucket: 'life-change-78727.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQBRuXkoNncUVJT0bX35KP3WealXdOu1M',
    appId: '1:233059619721:ios:9dfb42b96549a9a7e24758',
    messagingSenderId: '233059619721',
    projectId: 'life-change-78727',
    databaseURL: 'https://life-change-78727-default-rtdb.firebaseio.com',
    storageBucket: 'life-change-78727.firebasestorage.app',
    iosBundleId: 'com.example.lifeChange',
  );
}
