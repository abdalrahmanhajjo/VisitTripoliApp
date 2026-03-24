// Generated from Firebase project visit-tripoli-65251 + android/app/google-services.json.
// Re-run `flutterfire configure` if you add iOS/web or change apps.

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
        throw UnsupportedError(
          'Add an iOS app in Firebase and run flutterfire configure',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBw7GOFmbBuwPhXlq3pSh9533gEQ37Ujdw',
    appId: '1:904702521837:android:9216613f1c8475006277e4',
    messagingSenderId: '904702521837',
    projectId: 'visit-tripoli-65251',
    storageBucket: 'visit-tripoli-65251.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAyDY5Nh3FLHCr3kJ6rMYU1nizCIX50WhI',
    appId: '1:904702521837:web:6193d8ff489cdcd76277e4',
    messagingSenderId: '904702521837',
    projectId: 'visit-tripoli-65251',
    authDomain: 'visit-tripoli-65251.firebaseapp.com',
    storageBucket: 'visit-tripoli-65251.firebasestorage.app',
    measurementId: 'G-8JXRHXH5Y2',
  );

}