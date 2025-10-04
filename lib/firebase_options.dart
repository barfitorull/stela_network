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
        throw UnsupportedError('No macOS config set.');
      case TargetPlatform.windows:
        throw UnsupportedError('No Windows config set.');
      case TargetPlatform.linux:
        throw UnsupportedError('No Linux config set.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAn_gvUTDbTEsrpOz9mSnEI9zqsCvYyD24',
    appId: 'AICI_PUI_APP_ID_DE_LA_WEB', // Completează cu App ID-ul de la Web din Firebase Console
    messagingSenderId: '496934996329',
    projectId: 'stela-network',
    authDomain: 'stela-network.firebaseapp.com',
    storageBucket: 'stela-network.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAn_gvUTDbTEsrpOz9mSnEI9zqsCvYyD24',
    appId: '1:496934996329:android:18f215208832cb45e095f8',
    messagingSenderId: '496934996329',
    projectId: 'stela-network',
    storageBucket: 'stela-network.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAn_gvUTDbTEsrpOz9mSnEI9zqsCvYyD24',
    appId: '1:496934996329:ios:9d7cdaf1f2fc9feee095f8',
    messagingSenderId: '496934996329',
    projectId: 'stela-network',
    storageBucket: 'stela-network.firebasestorage.app',
    iosClientId: '496934996329-han5gc1k8f8pmjikr35gd2iq1a8spjcf.apps.googleusercontent.com',
    iosBundleId: 'stela.network.ios',
  );
} 