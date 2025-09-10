import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection path pentru setările de notificări
  static const String _collectionPath = 'notification_settings';

  // Obține ID-ul utilizatorului curent
  String? get _currentUserId => _auth.currentUser?.uid;

  // Încarcă setările de notificări din Firebase
  Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'miningAlerts': data['miningAlerts'] ?? true,
          'boosterReminders': data['boosterReminders'] ?? true,
          'referralUpdates': data['referralUpdates'] ?? true,
          'achievementAlerts': data['achievementAlerts'] ?? true,
        };
      } else {
        // Returnează valorile implicite dacă documentul nu există
        return {
          'miningAlerts': true,
          'boosterReminders': true,
          'referralUpdates': true,
          'achievementAlerts': true,
        };
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      // Returnează valorile implicite în caz de eroare
      return {
        'miningAlerts': true,
        'boosterReminders': true,
        'referralUpdates': true,
        'achievementAlerts': true,
      };
    }
  }

  // Salvează setările de notificări în Firebase
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .set(settings, SetOptions(merge: true));

      print('Notification settings saved successfully');
    } catch (e) {
      print('Error saving notification settings: $e');
      throw Exception('Failed to save notification settings');
    }
  }

  // Actualizează o singură setare
  Future<void> updateNotificationSetting(String settingKey, bool value) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .set({settingKey: value}, SetOptions(merge: true));

      print('Notification setting $settingKey updated to $value');
    } catch (e) {
      print('Error updating notification setting: $e');
      throw Exception('Failed to update notification setting');
    }
  }

  // Stream pentru a asculta schimbările în timp real
  Stream<Map<String, bool>> notificationSettingsStream() {
    if (_currentUserId == null) {
      return Stream.value({
        'miningAlerts': true,
        'boosterReminders': true,
        'referralUpdates': false,
        'achievementAlerts': true,
      });
    }

    return _firestore
        .collection(_collectionPath)
        .doc(_currentUserId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'miningAlerts': data['miningAlerts'] ?? true,
          'boosterReminders': data['boosterReminders'] ?? true,
          'referralUpdates': data['referralUpdates'] ?? true,
          'achievementAlerts': data['achievementAlerts'] ?? true,
        };
      } else {
        return {
          'miningAlerts': true,
          'boosterReminders': true,
          'referralUpdates': true,
          'achievementAlerts': true,
        };
      }
    });
  }
} 