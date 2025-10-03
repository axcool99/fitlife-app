import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBGNa0dD1Z_wc9lvdbI_rEdApPMa4OLR9w',
    appId: '1:730357354171:web:9eebc396ba222e50d9239e',
    messagingSenderId: '730357354171',
    projectId: 'fitness-c0836',
    authDomain: 'fitness-c0836.firebaseapp.com',
    storageBucket: 'fitness-c0836.firebasestorage.app',
    measurementId: 'G-30F42W2DRH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhcNx2Y2jWJCp7nx9PoXFXCefY1lnJtyE',
    appId: '1:730357354171:android:d36e3de57738785bd9239e',
    messagingSenderId: '730357354171',
    projectId: 'fitness-c0836',
    storageBucket: 'fitness-c0836.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA43x734tKS5Kg8lsmQBW8IXUOHCP107_g',
    appId: '1:730357354171:ios:c75f6b0c318e3b6ed9239e',
    messagingSenderId: '730357354171',
    projectId: 'fitness-c0836',
    storageBucket: 'fitness-c0836.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBGNa0dD1Z_wc9lvdbI_rEdApPMa4OLR9w',
    appId: '1:730357354171:web:9eebc396ba222e50d9239e', // Note: This should be updated with macOS appId from Firebase console
    messagingSenderId: '730357354171',
    projectId: 'fitness-c0836',
    storageBucket: 'fitness-c0836.firebasestorage.app',
  );
}