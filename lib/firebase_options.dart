

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
    apiKey: 'AIzaSyDXnw3LPwkDwrX-bv6O34u8pXx8A1LIdM8',
    appId: '1:585624770214:web:dea7899ae287ab3aa44667',
    messagingSenderId: '585624770214',
    projectId: 'sports-academy-app-cb958',
    authDomain: 'sports-academy-app-cb958.firebaseapp.com',
    storageBucket: 'sports-academy-app-cb958.firebasestorage.app',
    measurementId: 'G-1F9G3NMD08',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbEm-LE9lyUPKa36GtEIG1XccO0wRJSSs',
    appId: '1:585624770214:android:fc24ab2256da8e88a44667',
    messagingSenderId: '585624770214',
    projectId: 'sports-academy-app-cb958',
    storageBucket: 'sports-academy-app-cb958.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDgNAQA4BVKPU8iUNFhpiF7uCBxl-7stT8',
    appId: '1:585624770214:ios:ab9ed80977c59c11a44667',
    messagingSenderId: '585624770214',
    projectId: 'sports-academy-app-cb958',
    storageBucket: 'sports-academy-app-cb958.firebasestorage.app',
    iosBundleId: 'com.sportsacademy.sportsAcademyApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDgNAQA4BVKPU8iUNFhpiF7uCBxl-7stT8',
    appId: '1:585624770214:ios:ab9ed80977c59c11a44667',
    messagingSenderId: '585624770214',
    projectId: 'sports-academy-app-cb958',
    storageBucket: 'sports-academy-app-cb958.firebasestorage.app',
    iosBundleId: 'com.sportsacademy.sportsAcademyApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDXnw3LPwkDwrX-bv6O34u8pXx8A1LIdM8',
    appId: '1:585624770214:web:6565cdb28ad28cd9a44667',
    messagingSenderId: '585624770214',
    projectId: 'sports-academy-app-cb958',
    authDomain: 'sports-academy-app-cb958.firebaseapp.com',
    storageBucket: 'sports-academy-app-cb958.firebasestorage.app',
    measurementId: 'G-FZEMXF0Z6P',
  );
}