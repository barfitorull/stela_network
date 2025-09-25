import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notifications_service.dart';

import 'dart:async';
import 'dart:math';

class MiningProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationsService _notificationsService = NotificationsService();



  // Mining state
  bool _isMining = false;
  double _balance = 0.0;
  double _miningRate = 0.20; // Rata curentă, poate fi modificată de boostere, referali etc.
  double _baseMiningRate = 0.20; // Rata de bază fără niciun bonus
  int _boostersUsedThisSession = 0; // Numărul de boostere UTILIZATE în sesiunea curentă de minare
  int _activeAdBoosts = 0; // Numărul de boost-uri active provenite din vizionarea reclamelor (dacă e o logică separată)
  int _activeReferrals = 0; // Numărul de utilizatori referiți care sunt activi
  int _totalReferrals = 0; // Numărul total de utilizatori referiți
  int _totalMiningSessions = 0; // Numărul total de sesiuni de minare începute
  DateTime? _sessionStartTime; // Timpul de început al sesiunii curente de minare
  DateTime? _lastMiningUpdate; // Ultimul timestamp când balanța a fost actualizată (dacă e necesar)
  DateTime? _lastBoosterTime; // Ultimul timestamp când un booster a fost folosit
  DateTime? _createdAt; // Timpul când s-a creat contul
  DateTime? _lastMemberJoined; // Timpul când s-a alăturat ultimul membru
  DateTime? _lastSaveTime; // Ultimul timestamp când s-a salvat la Firestore
  int? _saveCounter; // Counter pentru salvarea la Firestore
  String? _referralCode; // Codul de referral al utilizatorului curent
  String? _referredBy; // Codul de referral al utilizatorului care l-a invitat pe cel curent
  Timer? _miningTimer; // Timer pentru actualizări periodice ale balanței (dacă se implementează)
  Timer? _cooldownTimer; // Timer pentru perioada de cooldown (dacă se implementează)

  String? _currentUserId; // ID-ul utilizatorului autentificat pentru care rulează acest provider

  // Getters
  bool get isMining => _isMining;
  double get balance => _balance;
  double get miningRate => _miningRate;
  double get baseMiningRate => _baseMiningRate;
  int get boostersUsedThisSession => _boostersUsedThisSession;
  int get activeAdBoosts => _activeAdBoosts;
  int get activeReferrals => _activeReferrals;
  int get totalReferrals => _totalReferrals;
  int get totalMiningSessions => _totalMiningSessions;
  DateTime? get lastMiningUpdate => _lastMiningUpdate;
  DateTime? get lastBoosterTime => _lastBoosterTime;
  DateTime? get sessionStartTime => _sessionStartTime;
  DateTime? get createdAt => _createdAt;
  DateTime? get lastMemberJoined => _lastMemberJoined;
  String? get referralCode => _referralCode;
  String? get referredBy => _referredBy;
  String? get currentUserId => _currentUserId;

  // Getter pentru boosterele RĂMASE, calculat pe baza celor folosite și a maximului permis
  // Necesar pentru HomeScreen
  int get boostersRemaining => maxBoostersPerSession - _boostersUsedThisSession;

  // Constants - pot fi ajustate
  static const int maxBoostersPerSession = 10; // Numărul maxim de boostere ce pot fi folosite într-o sesiune
  static const Duration sessionDuration = Duration(hours: 24); // 24 ore - versiunea finală
  static const Duration cooldownDuration = Duration(hours: 2); // Durata cooldown-ului (dacă se implementează)

  // Constructor
  MiningProvider() {
    _initializeMessaging(); // Inițializează Firebase Messaging
    _initializeLocalNotifications(); // Inițializează notificările locale

    _auth.authStateChanges().listen(_onAuthStateChanged); // Ascultă schimbările de stare a autentificării

    // La pornirea aplicației, dacă există deja un utilizator logat, inițializează providerul pentru el
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      debugPrint('MiningProvider Constructor: User ${currentUser.uid} already logged in. Initializing...');
      initialize(currentUser.uid);
    } else {
      debugPrint('MiningProvider Constructor: No user initially logged in.');
    }
    
    // Start periodic background sync
    _startPeriodicSync();
  }

  // Periodic background sync to keep data updated
  void _startPeriodicSync() {
    // DISABLED: Mining timer already saves to Firebase every 1 second
    // No need for periodic sync which was causing conflicts
  }

  // Callback pentru schimbările de stare a autentificării
  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      // User logged out
      debugPrint('🔄 AuthStateChanged: User logged out');
      await clearUserStateOnLogout();
    } else {
      // User logged in
      debugPrint('🔄 AuthStateChanged: User logged in: ${user.uid}');
      
      if (_currentUserId != user.uid) {
        // Different user - clear old state and initialize new
        debugPrint('🔄 AuthStateChanged: User changed from $_currentUserId to ${user.uid}');
        await clearUserStateOnLogout();
        _currentUserId = user.uid;
        await initialize(user.uid);
        // Save FCM token for new user
        await _saveFCMToken();
      } else {
        // Same user - ONLY initialize if data is missing
        debugPrint('🔄 AuthStateChanged: Same user ${user.uid}');
        if (_referralCode == null) {
          debugPrint('🔄 AuthStateChanged: Re-initializing for same user due to missing referral code');
          await initialize(user.uid);
        }
        // Always save FCM token when user is logged in
        await _saveFCMToken();
      }
    }
  }

  // Salvează FCM token pentru utilizatorul curent
  Future<void> _saveFCMToken() async {
    try {
      if (_currentUserId == null) {
        debugPrint('🔔 Cannot save FCM token: no current user ID');
        return;
      }
      
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(_currentUserId!).set({'fcmToken': token}, SetOptions(merge: true));
        debugPrint('🔔 FCM Token saved for user: $_currentUserId');
      } else {
        debugPrint('🔔 FCM Token is null, cannot save');
      }
    } catch (e) {
      debugPrint('🔔 Error saving FCM token: $e');
    }
  }

  // Curăță complet starea providerului la logout sau la schimbarea utilizatorului
  Future<void> clearUserStateOnLogout() async {
    debugPrint('🔄 Clearing user state for former user: $_currentUserId');
    
    // Cancel all timers first
    _miningTimer?.cancel();
    _cooldownTimer?.cancel();

    // COMPLETE RESET - all variables to default values
    _isMining = false;
    _balance = 0.0;
    _miningRate = 0.20;
    _baseMiningRate = 0.20;
    _boostersUsedThisSession = 0;
    _activeAdBoosts = 0;
    _activeReferrals = 0;
    _totalReferrals = 0;
    _totalMiningSessions = 0;
    _sessionStartTime = null;
    _lastMiningUpdate = null;
    _lastBoosterTime = null;
    _createdAt = null;
    _lastMemberJoined = null;
    // DON'T reset _referredBy - it's permanent user data
    _referralCode = null;
    _currentUserId = null;

    debugPrint('✅ User state cleared completely.');
    notifyListeners();
  }

  // Inițializează Firebase Messaging (permisiuni, token)
  void _initializeMessaging() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true, announcement: false, badge: true, carPlay: false,
        criticalAlert: true, provisional: false, sound: true, // CRITICAL: Enable critical alerts
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 User granted notification permission: ${settings.authorizationStatus}');
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('🔔 FCM Token: $token');
          // Salvează token-ul în Firestore pentru utilizatorul curent
          if (_currentUserId != null) {
            await _firestore.collection('users').doc(_currentUserId!).set({'fcmToken': token}, SetOptions(merge: true));
            debugPrint('🔔 FCM Token saved for user: $_currentUserId');
          }
        }
      } else {
        debugPrint('🔔 User declined or has not yet granted notification permission.');
        // Try to request permission again
        await _requestNotificationPermission();
      }
    } catch (e) {
      debugPrint('🔔 Error initializing Firebase Messaging: $e');
    }
  }

  // Request notification permission and get FCM token
  Future<void> _requestNotificationPermission() async {
    try {
      debugPrint('🔔 Requesting notification permission...');
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true, announcement: false, badge: true, carPlay: false,
        criticalAlert: false, provisional: false, sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 Permission granted, getting FCM token...');
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('🔔 FCM Token obtained: $token');
          if (_currentUserId != null) {
            await _firestore.collection('users').doc(_currentUserId!).set({'fcmToken': token}, SetOptions(merge: true));
            debugPrint('🔔 FCM Token saved for user: $_currentUserId');
          }
        }
      } else {
        debugPrint('🔔 Permission denied: ${settings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('🔔 Error requesting notification permission: $e');
    }
  }

  // Inițializează notificările locale
  void _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = 
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings = 
          InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
      
      await FlutterLocalNotificationsPlugin().initialize(initializationSettings);
      debugPrint('✅ Local notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }



  // Inițializează starea providerului pentru un anumit utilizator (după login sau la pornire)
  Future<void> initialize(String userId) async {
    // Verify user is actually logged in
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      debugPrint('❌ Initialize: User mismatch or not logged in. Aborting.');
      await clearUserStateOnLogout();
      return;
    }

    debugPrint('🔄 Initializing MiningProvider for user: $userId');
    
    // Cancel timers first
    _miningTimer?.cancel();
    _cooldownTimer?.cancel();
    
    // Set current user
    _currentUserId = userId;
    
    // CRITICAL: Force clear state before loading new data
    _isMining = false;
    _balance = 0.0;
    _miningRate = 0.20;
    _baseMiningRate = 0.20;
    _boostersUsedThisSession = 0;
    _activeAdBoosts = 0;
    _activeReferrals = 0;
    _totalReferrals = 0;
    _totalMiningSessions = 0;
    _sessionStartTime = null;
    _lastMiningUpdate = null;
    _lastBoosterTime = null;
    _createdAt = null;
    _lastMemberJoined = null;
    _referralCode = null;
    // CRITICAL: DON'T reset _referredBy - it's permanent user data
    // _referredBy will be loaded from Firestore
    
    // CRITICAL: Load user data from Firestore (this will set all variables correctly)
    await _loadUserData(userId);
    
    // CRITICAL: Save FCM token to ensure it's up to date
    await _saveFCMToken();
    
    // CRITICAL: Force notify listeners to ensure UI updates
    debugPrint('🔄 Notifying listeners after initialization');
    notifyListeners();
  }

  // Încarcă datele utilizatorului din Firestore
  Future<void> _loadUserData(String userId) async {
    // Allow loading data even if there's a temporary user mismatch (e.g., after referral bonus application)
    if (_currentUserId != userId && _currentUserId != null) {
      debugPrint('⚠️ _loadUserData: User mismatch. Current: $_currentUserId, Requested: $userId - but allowing load for referral sync');
    }
    
    debugPrint('🔄 Loading data for user: $userId');
    
    try {
      // CRITICAL: Force reload from server to avoid cache issues
      final doc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.server));
      
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('✅ Firestore data found for user: $userId');
        debugPrint('📊 Raw Firestore data: $data');
        
        // Load all data from Firestore
        _balance = (data['balance'] ?? 0.0).toDouble();
        _baseMiningRate = (data['baseMiningRate'] ?? 0.20).toDouble();
        _miningRate = (data['miningRate'] ?? _baseMiningRate).toDouble();
        
        debugPrint('📊 Loaded balance from Firestore: $_balance');
        debugPrint('📊 Loaded baseMiningRate from Firestore: $_baseMiningRate');
        debugPrint('📊 Loaded miningRate from Firestore: $_miningRate');
        
        // Calculate boosters used from remaining
        int boostersRemainingFromDb = (data['boostersRemaining'] ?? maxBoostersPerSession) as int;
        _boostersUsedThisSession = maxBoostersPerSession - boostersRemainingFromDb;
        
        _activeAdBoosts = (data['activeAdBoosts'] ?? 0) as int;
        _activeReferrals = (data['activeReferrals'] ?? 0) as int;
        _totalReferrals = (data['totalReferrals'] ?? 0) as int;
        _totalMiningSessions = (data['totalMiningSessions'] ?? 0) as int;
        
        _sessionStartTime = data['sessionStartTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['sessionStartTime'])
            : null;
        _lastMiningUpdate = data['lastMiningUpdate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastMiningUpdate'])
            : null;
        _lastBoosterTime = data['lastBoosterTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastBoosterTime'])
            : null;
        _createdAt = data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null;
        _lastMemberJoined = data['lastMemberJoined'] != null
            ? (data['lastMemberJoined'] as Timestamp).toDate()
            : null;
        
        _referredBy = data['referredBy'] as String?;
        _isMining = data['isMining'] ?? false;
        
        debugPrint('📊 Loaded referredBy from Firestore: $_referredBy');
        debugPrint('📊 Loaded isMining from Firestore: $_isMining');
        
        // CRITICAL: If referredBy is loaded, ensure it's not null
        if (_referredBy != null && _referredBy!.isNotEmpty) {
          debugPrint('✅ ReferredBy successfully loaded: $_referredBy');
        } else {
          debugPrint('⚠️ ReferredBy is null or empty');
          // CRITICAL: Check if referredBy exists in data but wasn't loaded correctly
          if (data.containsKey('referredBy')) {
            debugPrint('⚠️ referredBy field exists in Firestore data: ${data['referredBy']}');
            _referredBy = data['referredBy'] as String?;
            debugPrint('⚠️ Re-loaded referredBy: $_referredBy');
          }
        }
        
        // Handle referral code - CRITICAL FIX: NEVER generate new codes for existing users
        String? loadedReferralCode = data['referralCode'] as String?;
        if (loadedReferralCode != null && loadedReferralCode.isNotEmpty) {
          _referralCode = loadedReferralCode;
          debugPrint('🎯 Using existing referral code: $_referralCode');
        } else {
          // CRITICAL FIX: DO NOT generate new referral codes here
          // This prevents referral code regeneration on app reinstall
          _referralCode = null;
          debugPrint('⚠️ No referral code found in Firestore - keeping null to prevent regeneration');
          debugPrint('⚠️ Referral codes should only be generated during user registration');
        }
        
        // CRITICAL FIX: If user was referred, ensure bonus is applied immediately
        if (_referredBy != null && _balance == 0.0) {
          debugPrint('🎯 User was referred by $_referredBy but balance is 0. Applying bonus...');
          try {
            final result = await _functions.httpsCallable('updateReferrals').call({
              'referralCode': _referredBy,
            });
            
            if (result.data['success'] == true) {
              debugPrint('🎯 Referral bonus applied successfully: ${result.data['bonusApplied']} STC');
              // CRITICAL: Update balance and referredBy directly instead of reloading all data
              _balance = (result.data['newBalance'] ?? _balance).toDouble();
              _referredBy = _referredBy ?? result.data['referralCode']; // CRITICAL: Set referredBy if not already set
              debugPrint('🎯 Balance updated to: $_balance');
              debugPrint('🎯 ReferredBy updated to: $_referredBy');
            } else {
              debugPrint('🎯 Referral bonus application failed: ${result.data['message']}');
            }
          } catch (e) {
            debugPrint('🎯 Error applying referral bonus: $e');
          }
        }
        
        debugPrint('✅ Data loaded successfully:');
        debugPrint('💰 Balance: $_balance');
        debugPrint('⚡ Mining Rate: $_miningRate');
        debugPrint('🎯 Referral Code: $_referralCode');
        debugPrint('👥 Referred By: $_referredBy');
        debugPrint('⛏️ Is Mining: $_isMining');
        
        // CRITICAL FIX: Restart mining timer if user was mining
        if (_isMining && _sessionStartTime != null) {
          debugPrint('⛏️ User was mining, restarting timer...');
          _startMiningTimer();
        }
        
      } else {
        // New user - set defaults and generate referral code
        debugPrint('🆕 New user $userId - setting defaults');
        _referralCode = _generateReferralCode();
        debugPrint('🎯 Generated referral code: $_referralCode');
        
        // Create user document with referral code
        final userData = {
          'balance': 0.0,
          'miningRate': _baseMiningRate,
          'baseMiningRate': _baseMiningRate,
          'boostersRemaining': maxBoostersPerSession,
          'activeAdBoosts': 0,
          'activeReferrals': 0,
          'totalReferrals': 0,
          'totalMiningSessions': 0,
          'sessionStartTime': null,
          'lastMiningUpdate': null,
          'lastBoosterTime': null,
          'referralCode': _referralCode,
          'referredBy': _referredBy,
          'isMining': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('users').doc(userId).set(userData);
        debugPrint('🆕 New user document created with referral code: $_referralCode');
      }
      
      // Check for session expiration
      if (_isMining && _sessionStartTime != null) {
        final elapsedTime = DateTime.now().difference(_sessionStartTime!);
        if (elapsedTime >= sessionDuration) {
          debugPrint('⛏️ Session expired. Stopping mining.');
          await stopMining(notify: false);
          _boostersUsedThisSession = 0;
          // Don't save again - stopMining already saved with recalculated balance
        }
      }
      
      _calculateMiningRate();
      
    } catch (e, s) {
      debugPrint('❌ Error loading user data: $e');
      debugPrint('Stack trace: $s');
    }
    
    // CRITICAL: Always notify listeners at the end
    debugPrint('🔄 Notifying listeners after data load');
    notifyListeners();
  }
// SFÂRȘIT PARTEA 1 din 2
// Salvează datele utilizatorului în Firestore
  Future<void> _saveUserData({bool isNewUser = false}) async {
    if (_currentUserId == null) {
      debugPrint('❌ _saveUserData: No current user ID');
      return;
    }

    // Calculate boosters remaining
    int calculatedBoostersRemaining = maxBoostersPerSession - _boostersUsedThisSession;
    if (calculatedBoostersRemaining < 0) calculatedBoostersRemaining = 0;
    if (calculatedBoostersRemaining > maxBoostersPerSession) calculatedBoostersRemaining = maxBoostersPerSession;

    debugPrint('💾 Saving data for user: $_currentUserId');
    debugPrint('💰 Balance: $_balance');
    debugPrint('⚡ Mining Rate: $_miningRate');
    debugPrint('🎯 Referral Code: $_referralCode');
    debugPrint('👥 Referred By: $_referredBy');
    debugPrint('⛏️ Is Mining: $_isMining');

    final Map<String, dynamic> dataToSave = {
      'balance': _balance,
      'miningRate': _miningRate,
      'baseMiningRate': _baseMiningRate,
      'boostersRemaining': calculatedBoostersRemaining,
      'activeAdBoosts': _activeAdBoosts,
              'activeReferrals': _activeReferrals,
        'totalReferrals': _totalReferrals,
        'lastMemberJoined': _lastMemberJoined != null ? Timestamp.fromDate(_lastMemberJoined!) : null,
      'totalMiningSessions': _totalMiningSessions,
      'sessionStartTime': _sessionStartTime?.millisecondsSinceEpoch,
      'lastMiningUpdate': _lastMiningUpdate?.millisecondsSinceEpoch,
      'lastBoosterTime': _lastBoosterTime?.millisecondsSinceEpoch,
      'referralCode': _referralCode,
      'referredBy': _referredBy,
      'isMining': _isMining,
      'notificationSent1': false,
      'notificationSent2': false,
      'notificationSent3': false,
      'notificationSent4': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (isNewUser) {
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        debugPrint('🆕 Creating new user document');
        await _firestore.collection('users').doc(_currentUserId!).set(dataToSave);
      } else {
        debugPrint('📝 Updating existing user document');
        
        // CRITICAL FIX: Don't overwrite balance if it's lower than Firebase
        final currentDoc = await _firestore.collection('users').doc(_currentUserId!).get();
        if (currentDoc.exists) {
          final currentData = currentDoc.data()!;
          final firebaseBalance = (currentData['balance'] ?? 0.0).toDouble();
          
          if (_balance < firebaseBalance) {
            debugPrint('💰 CRITICAL: Local balance ($_balance) is lower than Firebase ($firebaseBalance). Keeping Firebase balance.');
            dataToSave['balance'] = firebaseBalance;
            _balance = firebaseBalance; // Update local balance too
          } else {
            debugPrint('💰 Saving current balance: $_balance');
          }
        }
        
        // CRITICAL FIX: Remove critical fields that should NEVER be overwritten
        final updateData = Map<String, dynamic>.from(dataToSave);
        updateData.remove('referredBy'); // Never overwrite referral relationships
        updateData.remove('referralCode'); // Never overwrite existing referral codes
        updateData.remove('createdAt'); // Never overwrite creation date
        
        await _firestore.collection('users').doc(_currentUserId!).set(updateData, SetOptions(merge: true));
      }
      debugPrint('✅ User data saved successfully');
    } catch (e, s) {
      debugPrint('❌ Error saving user data: $e');
      debugPrint('Stack trace: $s');
    }
  }

  // Generează un cod de referral aleatoriu - DOAR pentru utilizatori noi
  String _generateReferralCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    
    debugPrint('🎯 CRITICAL: Generating referral code: $code');
    debugPrint('🎯 WARNING: This should ONLY happen during user registration!');
    
    return code;
  }



  // Pornește sesiunea de minare
  Future<void> startMining() async {
    if (_isMining) {
      debugPrint('⛏️ Already mining.');
      return;
    }
    if (_currentUserId == null) {
      debugPrint('❌ Cannot start mining, no user logged in.');
      return;
    }

    // Check if previous session hasn't expired yet
    if (_sessionStartTime != null) {
      final elapsedTime = DateTime.now().difference(_sessionStartTime!);
      if (elapsedTime < sessionDuration) {
        final remainingTime = sessionDuration - elapsedTime;
        debugPrint('⛏️ Previous session still active. Remaining time: ${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m');
        throw Exception('Sesiunea anterioară încă este activă. Mai ai ${remainingTime.inHours} ore și ${remainingTime.inMinutes % 60} minute.');
      }
    }

    _isMining = true;
    _sessionStartTime = DateTime.now(); // Always set new start time
    _lastMiningUpdate = DateTime.now();
    _totalMiningSessions++;

    _boostersUsedThisSession = 0;

    debugPrint('⛏️ Starting mining session for $_currentUserId. Start time: $_sessionStartTime.');
    _calculateMiningRate();
    await _saveUserData();
    notifyListeners();



    // Send notification for mining start
    try {
      await _notificationsService.addNotification(
        title: 'Mining Started!',
        message: 'Your mining session has begun. You are now earning STC!',
        type: 'mining',
        icon: 'mining',
        color: Colors.green,
      );
    } catch (e) {
      debugPrint('❌ Error sending mining notification: $e');
    }

    // Start mining timer for balance updates
    _startMiningTimer();
    

    
    // Update referrer's active referrals
    await _updateReferrerActiveReferrals();
    
    // Update live stats - increment active miners
    await _updateLiveStatsActiveMiners(1);
  }

  // Timer pentru actualizarea balanței în timp real
  void _startMiningTimer() {
    _miningTimer?.cancel();
    _miningTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isMining || _currentUserId == null) {
        timer.cancel();
        return;
      }

      // Check if session has ended (24 hours)
      if (_sessionStartTime != null) {
        final elapsedTime = DateTime.now().difference(_sessionStartTime!);
        if (elapsedTime >= sessionDuration) {
          debugPrint('⏰ 24-hour session ended. Stopping mining automatically.');
          await stopMining();
          return;
        }
      }

      // Calculate mining earnings
      final now = DateTime.now();
      if (_lastMiningUpdate != null) {
        final timeDiff = now.difference(_lastMiningUpdate!).inMilliseconds;
        final earnings = (_miningRate / 3600) * (timeDiff / 1000.0); // Convert rate per hour to per millisecond
        
        if (earnings > 0) {
          _balance += earnings;
          _lastMiningUpdate = now;
          
          debugPrint('💰 Mining update: +${earnings.toStringAsFixed(6)} STC. New balance: ${_balance.toStringAsFixed(6)}');
          
          // Update live stats - add STC to total mined
          await _updateLiveStatsTotalSTCMined(earnings);
          
          // Save to Firestore every 1 second (but update UI every 100ms)
          if (timer.tick % 10 == 0) { // Every 10 ticks = 1 second
            await _saveUserData();
          }
          notifyListeners();
        }
      }
    });
  }

  // Oprește sesiunea de minare
  Future<void> stopMining({bool notify = true}) async {
    if (!_isMining) {
      debugPrint('⛏️ Not currently mining.');
      return;
    }
    if (_currentUserId == null) {
      debugPrint('❌ Cannot stop mining, no user identified.');
      return;
    }

    _isMining = false;
    _miningTimer?.cancel();

    debugPrint('⛏️ Stopping mining session for $_currentUserId.');
    
    // CRITICAL FIX: Recalculate final balance before saving
    if (_lastMiningUpdate != null) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastMiningUpdate!).inMilliseconds;
      final finalEarnings = (_miningRate / 3600) * (timeDiff / 1000.0);
      if (finalEarnings > 0) {
        _balance += finalEarnings;
        _lastMiningUpdate = now;
        debugPrint('💰 Final mining earnings: +${finalEarnings.toStringAsFixed(6)} STC. Final balance: ${_balance.toStringAsFixed(6)}');
      }
    }
    
    // CRITICAL FIX: Update lastMiningUpdate to current time when stopping
    _lastMiningUpdate = DateTime.now();
    
    // CRITICAL FIX: Reset boosters when stopping mining session
    _boostersUsedThisSession = 0;
    debugPrint('🚀 Boosters reset to 0 when stopping mining session');
    
    await _saveUserData();
    

    
    // Update referrer's active referrals
    await _updateReferrerActiveReferrals();
    
    // Update live stats - decrement active miners
    await _updateLiveStatsActiveMiners(-1);
    

    

    

    

    
    // Send immediate notification
    await _sendMiningStoppedNotification();
    
    // Schedule delayed notifications
    _scheduleDelayedNotifications();
    
    if (notify) notifyListeners();
  }



  // Trimite notificare imediată când se oprește minarea
  Future<void> _sendMiningStoppedNotification() async {
    try {
      if (_currentUserId == null) {
        debugPrint('❌ Cannot send mining stopped notification: no current user ID');
        return;
      }
      
      // Call server-side function to send push notification
      final result = await _functions.httpsCallable('sendMiningStoppedNotification').call();
      
      if (result.data['success'] == true) {
        debugPrint('✅ Mining stopped push notification sent successfully');
      } else {
        debugPrint('❌ Mining stopped push notification failed: ${result.data['message']}');
      }
      
    } catch (e) {
      debugPrint('❌ Error sending mining stopped notification: $e');
    }
  }

  // Programează notificări întârziate
  void _scheduleDelayedNotifications() {
    // Cancel existing timers
    _cooldownTimer?.cancel();
    
    debugPrint('📅 Scheduling delayed notifications');
    
    // Schedule 1-hour notification
    _cooldownTimer = Timer(const Duration(hours: 1), () {
      _sendDelayedNotification(1);
    });
  }

  // Trimite notificare întârziată
  Future<void> _sendDelayedNotification(int hour) async {
    try {
      String? token = await _messaging.getToken();
      
      if (_currentUserId != null && token != null) {
        String title = '';
        String body = '';
        
        if (hour == 1) {
          title = '**Don\'t forget to mine STC!**';
          body = 'Your mining session ended. Come back and start a new session!';
        } else if (hour == 2) {
          title = '**Your mining session is waiting!**';
          body = 'Don\'t miss out on STC earnings. Start mining now!';
        } else if (hour == 3) {
          title = '**Last reminder to mine STC!**';
          body = 'Your mining session ended 3 hours ago. Don\'t lose more STC!';
        }
        
        // Send FCM notification
        await _functions.httpsCallable('sendNotificationHttp').call({
          'token': token,
          'title': title,
          'body': body,
        });
        debugPrint('Delayed FCM notification sent successfully (${hour}h)');
        
        // Show local notification
        await _showLocalNotification(title, body);
      }
    } catch (e) {
      debugPrint('Error sending delayed FCM notification: $e');
    }
  }

  // Afișează notificare locală
  Future<void> _showLocalNotification(String title, String body) async {
    try {
      // Request notification permissions
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
          FlutterLocalNotificationsPlugin();
      
      // Show system notification
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'mining_channel',
        'Mining Notifications',
        channelDescription: 'Notifications for mining activities',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await flutterLocalNotificationsPlugin.show(
        0, // notification id
        title,
        body,
        platformChannelSpecifics,
      );
      
      debugPrint('✅ System notification displayed: $title');
      
      // Only add to app notifications for immediate notification, not for delayed ones
      // This prevents duplicate notifications
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  // Calculează rata de minare pe baza parametrilor curenți
  void _calculateMiningRate() {
    double rate = _baseMiningRate;
    
    // Add referral bonus
    rate += _activeReferrals * 0.20; // +0.20 STC/hr per active referral
    
    // Add ad boost bonus
    rate += _activeAdBoosts * 0.10;  // +0.10 STC/hr per ad boost
    
    // Add booster bonus (each booster used increases rate by 0.20)
    rate += _boostersUsedThisSession * 0.20; // +0.20 STC/hr per booster used

    _miningRate = rate > 0 ? rate : 0.01; // Ensure minimum positive rate
    
    debugPrint('⚡ Mining rate calculated: $_miningRate STC/hr');
    debugPrint('  - Base rate: $_baseMiningRate');
    debugPrint('  - Active referrals: $_activeReferrals (+${_activeReferrals * 0.20})');
    debugPrint('  - Active ad boosts: $_activeAdBoosts (+${_activeAdBoosts * 0.10})');
    debugPrint('  - Boosters used: $_boostersUsedThisSession (+${_boostersUsedThisSession * 0.20})');
  }

  // Utilizează un booster
  Future<void> useBooster() async {
    if (_currentUserId == null) {
      debugPrint('🚀 Cannot use booster, no user logged in.');
      throw Exception('Utilizator neconectat.');
    }

    if (!isMining) {
      debugPrint('🚀 Cannot use booster, mining session not active.');
      throw Exception('Trebuie să pornești sesiunea de minare pentru a folosi un booster.');
    }

    if (boostersRemaining <= 0) {
      debugPrint('🚀 No boosters left to use. Boosters used: $_boostersUsedThisSession');
      throw Exception('Nu mai ai boostere disponibile în această sesiune.');
    }

    debugPrint('🚀 Using booster for user: $_currentUserId');
    
    // Increment boosters used
    _boostersUsedThisSession++;
    _lastBoosterTime = DateTime.now();
    
    debugPrint('🚀 Booster used. Boosters used this session: $_boostersUsedThisSession. Boosters remaining: $boostersRemaining.');

    // Recalculate mining rate with new booster
    _calculateMiningRate();
    
    // Save updated data
    await _saveUserData();
    
    // Send notification for booster use
    try {
      await _notificationsService.addNotification(
        title: 'Booster Used!',
        message: 'Your mining rate has increased! You are now earning more STC.',
        type: 'booster',
        icon: 'rocket',
        color: Colors.orange,
      );
    } catch (e) {
      debugPrint('❌ Error sending booster notification: $e');
    }
    
    debugPrint('✅ Booster applied successfully. New mining rate: $_miningRate STC/hr');
    notifyListeners();
  }

  // Adaugă un cod de referral (folosit de un utilizator nou pentru a indica cine l-a invitat)
  Future<void> addReferralCode(String code) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot add referral code, no user logged in.');
      throw Exception('Utilizator neconectat.');
    }

    if (_referralCode == code) {
      debugPrint('⚠️ User $_currentUserId cannot use their own referral code.');
      throw Exception('Nu poți folosi propriul tău cod de invitație.');
    }

    try {
      debugPrint('📞 Calling "updateReferrals" cloud function for $_currentUserId with code: $code');
      final HttpsCallable callable = _functions.httpsCallable('updateReferrals');
      final result = await callable.call<Map<String, dynamic>>({'referralCode': code});

      if (result.data['success'] == true) {
        debugPrint('✅ Referral code processed successfully by cloud function for $_currentUserId.');
        // CRITICAL: Wait for Firestore to sync
        await Future.delayed(const Duration(milliseconds: 2000));
        debugPrint('⏳ Waited for Firestore sync');
        
        // Re-încarcă datele utilizatorului pentru a reflecta bonusul și `referredBy` setate de funcția Cloud
        await _loadUserData(_currentUserId!);
        debugPrint('🔄 User data reloaded after referral processing');
        
        // CRITICAL: Force another reload to ensure referredBy is loaded
        await Future.delayed(const Duration(milliseconds: 1000));
        await _loadUserData(_currentUserId!);
        debugPrint('🔄 Second reload completed');
        
        // CRITICAL: Force UI update after referral processing
        notifyListeners();
        debugPrint('🔄 UI updated after referral processing');
      } else {
        debugPrint('❌ Cloud function "updateReferrals" reported failure: ${result.data['message']}');
        throw Exception(result.data['message'] ?? 'Eroare la procesarea codului de invitație.');
      }
    } on FirebaseFunctionsException catch (e,s) {
      debugPrint('❌ FirebaseFunctionsException calling updateReferrals for $_currentUserId: ${e.code} - ${e.message}');
      debugPrintStack(stackTrace: s);
      throw Exception(e.message ?? 'Eroare server la validarea codului.');
    } catch (e,s) {
      debugPrint('❌ Generic error in addReferralCode for $_currentUserId: $e');
      debugPrintStack(stackTrace: s);
      throw Exception('A apărut o eroare necunoscută la procesarea codului.');
    }
  }

  // Actualizează referrer-ul când user-ul începe/oprește minarea
  Future<void> _updateReferrerActiveReferrals() async {
    if (_currentUserId == null || _referredBy == null) {
      return; // No referrer to update
    }

    try {
      debugPrint('📞 Calling "updateReferrerActiveReferrals" cloud function');
      final HttpsCallable callable = _functions.httpsCallable('updateReferrerActiveReferrals');
      await callable.call<Map<String, dynamic>>({'isMining': _isMining});
      debugPrint('✅ Referrer active referrals updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating referrer active referrals: $e');
    }
  }

  // Update live stats for active miners
  Future<void> _updateLiveStatsActiveMiners(int increment) async {
    try {
      final statsRef = _firestore.collection('liveStats').doc('stats');
      await _firestore.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);
        final currentActiveMiners = statsDoc.exists ? (statsDoc.data()?['activeMiners'] ?? 0) : 0;
        final newActiveMiners = currentActiveMiners + increment;
        transaction.set(statsRef, {'activeMiners': newActiveMiners}, SetOptions(merge: true));
        debugPrint('📊 Live stats updated: activeMiners = $newActiveMiners');
      });
    } catch (e) {
      debugPrint('❌ Error updating live stats activeMiners: $e');
    }
  }

  // Update live stats for total STC mined
  Future<void> _updateLiveStatsTotalSTCMined(double stcAmount) async {
    try {
      final statsRef = _firestore.collection('liveStats').doc('stats');
      await _firestore.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);
        final currentTotal = statsDoc.exists ? (statsDoc.data()?['totalSTCMined'] ?? 0.0) : 0.0;
        final newTotal = currentTotal + stcAmount;
        transaction.set(statsRef, {'totalSTCMined': newTotal}, SetOptions(merge: true));
        debugPrint('📊 Live stats updated: totalSTCMined = ${newTotal.toStringAsFixed(6)}');
      });
    } catch (e) {
      debugPrint('❌ Error updating live stats totalSTCMined: $e');
    }
  }

  // Force reload data from Firebase and update UI
  Future<void> forceReloadData() async {
    if (_currentUserId == null) {
      debugPrint('❌ forceReloadData: No current user ID');
      return;
    }
    
    debugPrint('🔄 Force reloading data for user: $_currentUserId');
    
    try {
      final doc = await _firestore.collection('users').doc(_currentUserId!).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('✅ Force reload: Firestore data found');
        debugPrint('📊 Force reload: Raw data: $data');
        
        // Update ALL data from Firebase
        _balance = (data['balance'] ?? 0.0).toDouble();
        _baseMiningRate = (data['baseMiningRate'] ?? 0.20).toDouble();
        _miningRate = (data['miningRate'] ?? _baseMiningRate).toDouble();
        
        int boostersRemainingFromDb = (data['boostersRemaining'] ?? maxBoostersPerSession) as int;
        _boostersUsedThisSession = maxBoostersPerSession - boostersRemainingFromDb;
        
        _activeAdBoosts = (data['activeAdBoosts'] ?? 0) as int;
        _activeReferrals = (data['activeReferrals'] ?? 0) as int;
        _totalReferrals = (data['totalReferrals'] ?? 0) as int;
        _totalMiningSessions = (data['totalMiningSessions'] ?? 0) as int;
        
        _sessionStartTime = data['sessionStartTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['sessionStartTime'])
            : null;
        _lastMiningUpdate = data['lastMiningUpdate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastMiningUpdate'])
            : null;
        _lastBoosterTime = data['lastBoosterTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastBoosterTime'])
            : null;
        
        _referredBy = data['referredBy'] as String?;
        _isMining = data['isMining'] ?? false;
        
        debugPrint('✅ Force reload: Data updated successfully');
        debugPrint('💰 Force reload: Balance: $_balance');
        debugPrint('⚡ Force reload: Mining Rate: $_miningRate');
        debugPrint('⛏️ Force reload: Is Mining: $_isMining');
        
        // Force UI update
        notifyListeners();
        debugPrint('🔄 Force reload: UI updated');
        
      } else {
        debugPrint('❌ Force reload: User document not found');
      }
    } catch (e) {
      debugPrint('❌ Force reload: Error loading data: $e');
    }
  }

  // CRITICAL: Force refresh user data - this is the key method to solve the UI update issue
  Future<void> forceRefreshUserData() async {
    if (_currentUserId == null) {
      debugPrint('❌ Cannot force refresh: no current user ID');
      return;
    }
    
    debugPrint('🔄 FORCE REFRESH: Reloading user data for $_currentUserId');
    
    try {
      // First, clear current state to ensure clean reload
      _balance = 0.0;
      _miningRate = 0.20;
      _baseMiningRate = 0.20;
      _boostersUsedThisSession = 0;
      _activeAdBoosts = 0;
      _activeReferrals = 0;
      _totalReferrals = 0;
      _totalMiningSessions = 0;
      _sessionStartTime = null;
      _lastMiningUpdate = null;
      _lastBoosterTime = null;
      _createdAt = null;
      _lastMemberJoined = null;
      _referralCode = null;
      // CRITICAL: DON'T reset _referredBy - it's permanent user data
      // _referredBy will be reloaded from Firestore
      
      // Notify listeners immediately to show loading state
      notifyListeners();
      
      // Wait a moment to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Now reload data from Firestore with server source to bypass cache
      await _loadUserDataFromServer(_currentUserId!);
      
      debugPrint('✅ FORCE REFRESH: User data reloaded successfully');
    } catch (e) {
      debugPrint('❌ FORCE REFRESH: Error reloading user data: $e');
    }
  }

  // CRITICAL: Load user data from server with cache bypass
  Future<void> _loadUserDataFromServer(String userId) async {
    debugPrint('🔄 Loading data from server for user: $userId');
    
    try {
      // CRITICAL: Force reload from server to bypass all cache
      final doc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.server));
      
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('✅ Server data found for user: $userId');
        debugPrint('📊 Server data: $data');
        
        // Load ALL data from server to ensure complete sync
        _balance = (data['balance'] ?? 0.0).toDouble();
        _baseMiningRate = (data['baseMiningRate'] ?? 0.20).toDouble();
        _miningRate = (data['miningRate'] ?? _baseMiningRate).toDouble();
        
        int boostersRemainingFromDb = (data['boostersRemaining'] ?? maxBoostersPerSession) as int;
        _boostersUsedThisSession = maxBoostersPerSession - boostersRemainingFromDb;
        
        _activeAdBoosts = (data['activeAdBoosts'] ?? 0) as int;
        _activeReferrals = (data['activeReferrals'] ?? 0) as int;
        _totalReferrals = (data['totalReferrals'] ?? 0) as int;
        _totalMiningSessions = (data['totalMiningSessions'] ?? 0) as int;
        
        _sessionStartTime = data['sessionStartTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['sessionStartTime'])
            : null;
        _lastMiningUpdate = data['lastMiningUpdate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastMiningUpdate'])
            : null;
        _lastBoosterTime = data['lastBoosterTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastBoosterTime'])
            : null;
        _createdAt = data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null;
        _lastMemberJoined = data['lastMemberJoined'] != null
            ? (data['lastMemberJoined'] as Timestamp).toDate()
            : null;
        
        _referredBy = data['referredBy'] as String?;
        _isMining = data['isMining'] ?? false;
        
        // CRITICAL: Load referral code from server
        String? serverReferralCode = data['referralCode'] as String?;
        if (serverReferralCode != null && serverReferralCode.isNotEmpty) {
          _referralCode = serverReferralCode;
          debugPrint('🎯 Server referral code loaded: $_referralCode');
        } else {
          debugPrint('⚠️ No referral code found on server');
        }
        
        debugPrint('✅ Server data loaded: balance=$_balance, referredBy=$_referredBy, referralCode=$_referralCode');
        
        // Force UI update
        notifyListeners();
      } else {
        debugPrint('❌ No server data found for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error loading server data: $e');
    }
  }

  // CRITICAL: Check and fix referral bonus if needed
  Future<void> checkAndFixReferralBonus() async {
    if (_currentUserId == null) {
      debugPrint('❌ Cannot check referral bonus: no current user ID');
      return;
    }
    
    debugPrint('🎯 CHECKING REFERRAL BONUS: User $_currentUserId');
    debugPrint('🎯 Current balance: $_balance');
    debugPrint('🎯 Referred by: $_referredBy');
    
    // If user was referred but balance is 0, apply bonus
    if (_referredBy != null && _balance == 0.0) {
      debugPrint('🎯 APPLYING REFERRAL BONUS: User was referred but balance is 0');
      
      try {
        final result = await _functions.httpsCallable('updateReferrals').call({
          'referralCode': _referredBy,
        });
        
        if (result.data['success'] == true) {
          debugPrint('🎯 REFERRAL BONUS APPLIED: ${result.data['bonusApplied']} STC');
          
          // Update local balance immediately
          _balance = (result.data['newBalance'] ?? 10.0).toDouble();
          debugPrint('🎯 UPDATED BALANCE: $_balance STC');
          
          // Force UI update
          notifyListeners();
          
          // Also update Firestore to ensure consistency
          await _firestore.collection('users').doc(_currentUserId!).update({
            'balance': _balance,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          debugPrint('🎯 FIREBASE UPDATED: Balance saved to Firestore');
        } else {
          debugPrint('🎯 REFERRAL BONUS FAILED: ${result.data['message']}');
        }
      } catch (e) {
        debugPrint('🎯 REFERRAL BONUS ERROR: $e');
      }
    } else {
      debugPrint('🎯 NO REFERRAL BONUS NEEDED: Balance is $_balance, Referred by $_referredBy');
    }
  }

  // Update activeReferrals and totalReferrals from team data (real-time)
  void updateReferralsFromTeam(int activeCount, int totalCount) {
    debugPrint('🔄 Updating referrals from team: active=$activeCount, total=$totalCount');
    _activeReferrals = activeCount;
    _totalReferrals = totalCount;
    _calculateMiningRate();
    notifyListeners();
    debugPrint('✅ Referrals updated: active=$_activeReferrals, total=$_totalReferrals, MiningRate=$_miningRate');
  }

  // Debug method for referredBy
  Future<void> debugReferredBy() async {
    debugPrint('🔍 DEBUG REFERRED BY:');
    debugPrint('🔍 Current user ID: $_currentUserId');
    debugPrint('🔍 Referred by: $_referredBy');
    debugPrint('🔍 Referral code: $_referralCode');
    debugPrint('🔍 Balance: $_balance');
    debugPrint('🔍 Active referrals: $_activeReferrals');
    debugPrint('🔍 Total referrals: $_totalReferrals');
  }

  @override
  void dispose() {
    super.dispose();
  }
}
// SFÂRȘIT PARTEA 2 din 2
// ASIGURĂ-TE CĂ NU MAI ESTE NIMIC DUPĂ ACEASTĂ LINIE ÎN FIȘIER
