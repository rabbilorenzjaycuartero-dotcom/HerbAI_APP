import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is configured only for Android. Add a Web app in Firebase '
        'Console and regenerate this file before building for Web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase is configured only for Android. Register this platform '
          'with Firebase and regenerate firebase_options.dart.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvyhCY5JpORbMDMvSf6VdjFENXYC05nhs',
    appId: '1:487242513363:android:5859dd419f355e883fcd26',
    messagingSenderId: '487242513363',
    projectId: 'herbai-mobile-app',
    storageBucket: 'herbai-mobile-app.firebasestorage.app',
  );
}
