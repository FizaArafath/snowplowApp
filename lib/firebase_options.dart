// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyB5UksCzWg2JjpBAha48MVNS2FbqyLynl4',
    appId: '1:359505398738:web:dd704e07d6f765b1fd960b',
    messagingSenderId: '359505398738',
    projectId: 'snow-plow-d24c0',
    authDomain: 'snow-plow-d24c0.firebaseapp.com',
    databaseURL: 'https://snow-plow-d24c0-default-rtdb.firebaseio.com',
    storageBucket: 'snow-plow-d24c0.firebasestorage.app',
    measurementId: 'G-07G4E3FG34',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRXtQIGdH7pzGxGxeIRP-j6UrghWzsqVA',
    appId: '1:359505398738:android:381c266990c3b292fd960b',
    messagingSenderId: '359505398738',
    projectId: 'snow-plow-d24c0',
    databaseURL: 'https://snow-plow-d24c0-default-rtdb.firebaseio.com',
    storageBucket: 'snow-plow-d24c0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDWGbX_SjZUOwnZnjb9RDQdT_A_Ljlr3yg',
    appId: '1:359505398738:ios:a07257d25acdadebfd960b',
    messagingSenderId: '359505398738',
    projectId: 'snow-plow-d24c0',
    databaseURL: 'https://snow-plow-d24c0-default-rtdb.firebaseio.com',
    storageBucket: 'snow-plow-d24c0.firebasestorage.app',
    iosBundleId: 'com.example.snowplow',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDWGbX_SjZUOwnZnjb9RDQdT_A_Ljlr3yg',
    appId: '1:359505398738:ios:a07257d25acdadebfd960b',
    messagingSenderId: '359505398738',
    projectId: 'snow-plow-d24c0',
    databaseURL: 'https://snow-plow-d24c0-default-rtdb.firebaseio.com',
    storageBucket: 'snow-plow-d24c0.firebasestorage.app',
    iosBundleId: 'com.example.snowplow',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB5UksCzWg2JjpBAha48MVNS2FbqyLynl4',
    appId: '1:359505398738:web:bd97fdb2965ef628fd960b',
    messagingSenderId: '359505398738',
    projectId: 'snow-plow-d24c0',
    authDomain: 'snow-plow-d24c0.firebaseapp.com',
    databaseURL: 'https://snow-plow-d24c0-default-rtdb.firebaseio.com',
    storageBucket: 'snow-plow-d24c0.firebasestorage.app',
    measurementId: 'G-LFHWR712QJ',
  );
}
