import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

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
        throw UnsupportedError('No Firebase options for Linux.');
      default:
        throw UnsupportedError('Unknown platform.');
    }
  }

  // 🌐 WEB
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
    appId: dotenv.env['FIREBASE_WEB_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WEB_SENDER']!,
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'],
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE'],
    measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'],
  );

  // 🤖 ANDROID
  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY']!,
    appId: dotenv.env['FIREBASE_ANDROID_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_ANDROID_SENDER']!,
    projectId: dotenv.env['FIREBASE_ANDROID_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_ANDROID_STORAGE'],
  );

  // 🍎 iOS
  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY']!,
    appId: dotenv.env['FIREBASE_IOS_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_IOS_SENDER']!,
    projectId: dotenv.env['FIREBASE_IOS_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_IOS_STORAGE'],
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'],
  );

  // 🍎 macOS (same values as iOS)
  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY']!,
    appId: dotenv.env['FIREBASE_IOS_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_IOS_SENDER']!,
    projectId: dotenv.env['FIREBASE_IOS_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_IOS_STORAGE'],
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'],
  );

  // 🪟 WINDOWS — add if needed (your .env currently does not contain Windows keys)
  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
    appId: dotenv.env['FIREBASE_WEB_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WEB_SENDER']!,
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'],
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE'],
    measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'],
  );
}
