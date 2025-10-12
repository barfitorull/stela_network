import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/mining_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_tabs.dart';
import 'services/admob_service.dart';
import 'services/notification_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Simple class to hold auth result for ProxyProvider
class AuthResult {
  final User user;
  AuthResult({required this.user});
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
}

// Request consent info (GDPR, CCPA, ATT) using UMP SDK
Future<void> requestConsentInfo() async {
  try {
    final params = ConsentRequestParameters();
    
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        print('📋 Consent info updated');
        
        // Check if consent form is available
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          print('📋 Consent form available, loading...');
          loadConsentForm();
        } else {
          print('📋 No consent form needed for this user');
        }
      },
      (FormError error) {
        print('📋 Consent info update error: ${error.message}');
      },
    );
  } catch (e) {
    print('📋 Error requesting consent info: $e');
  }
}

// Load and show consent form if needed
void loadConsentForm() {
  try {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        print('📋 Consent status: $status');
        
        if (status == ConsentStatus.required) {
          print('📋 Showing consent form');
          consentForm.show((FormError? formError) {
            if (formError != null) {
              print('📋 Form show error: ${formError.message}');
            }
            // Reload form in case consent status changed
            loadConsentForm();
          });
        }
      },
      (FormError formError) {
        print('📋 Consent form load error: ${formError.message}');
      },
    );
  } catch (e) {
    print('📋 Error loading consent form: $e');
  }
}

// Check for app updates function with UI
Future<void> checkForUpdates(BuildContext context) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    
    // For now, just show the snackbar for version 1.0.3 and below
    // In a real implementation, you'd check against a server or store API
    if (currentVersion == '1.0.3' || currentVersion == '1.0.2' || currentVersion == '1.0.1' || currentVersion == '1.0.0') {
      print('📱 Update available: $currentVersion → 1.0.4');
      
      // Show persistent snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New version of Stela Network available'),
            backgroundColor: Colors.green,
            duration: Duration(days: 365), // Persistent until update
            action: SnackBarAction(
              label: 'Update',
              textColor: Colors.white,
              onPressed: () {
                // Open Google Play Store
                // You can implement this with url_launcher
                print('Opening Google Play Store...');
              },
            ),
          ),
        );
      }
    } else {
      print('📱 App is up to date: $currentVersion');
    }
  } catch (e) {
    print('📱 Error checking updates: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request consent info (GDPR, CCPA, ATT) BEFORE initializing AdMob
  await requestConsentInfo();

  // Initialize AdMob
  await AdMobService.initialize();

  // Initialize notification service
  await NotificationService.init();

  // Initialize Firebase Messaging
  final messaging = FirebaseMessaging.instance;
  
  // Edge-to-edge is now handled in MainActivity.kt for Android 15 compatibility

  // Request permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Get FCM token
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Rămâne neschimbat
        ChangeNotifierProvider(create: (_) => AdminProvider()), // Admin provider
        // --- BLOCUL MODIFICAT ---
        // MiningProvider este acum responsabil să asculte FirebaseAuth.instance.authStateChanges()
        // și să se actualizeze intern. Se va inițializa în constructor și prin _onAuthStateChanged.
        ChangeNotifierProxyProvider<AuthResult, MiningProvider>(
          create: (_) => MiningProvider(),
          update: (_, authResult, previousProvider) {
            if (authResult?.user != null) {
              // User is logged in, ensure provider is initialized
              previousProvider?.initialize(authResult!.user!.uid);
              return previousProvider ?? MiningProvider();
            } else {
              // User is logged out, clear provider state
              previousProvider?.clearUserStateOnLogout();
              return previousProvider ?? MiningProvider();
            }
          },
        ),
        // --- SFÂRȘIT BLOC MODIFICAT ---
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Stela Network',
            theme: themeProvider.getThemeData(themeProvider.themeMode),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check for updates when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthResult?>(
      stream: FirebaseAuth.instance.authStateChanges().map((user) => 
        user != null ? AuthResult(user: user) : null
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A1A), // Sau tema ta de loading
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A90E2), // Sau tema ta de loading
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in
          print('🔄 AuthWrapper: User logged in: ${snapshot.data!.user.uid}');
          // MiningProvider ar trebui să fi fost deja actualizat
          // prin propriul său listener intern la authStateChanges.
          return const MainTabs();
        } else {
          // User is not logged in
          print('❌ AuthWrapper: No user logged in');
          // MiningProvider ar trebui să fi fost curățat
          // prin propriul său listener intern la authStateChanges.
          return const LoginScreen();
        }
      },
    );
  }
}
