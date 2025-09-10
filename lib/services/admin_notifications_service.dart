import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminNotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection path pentru notificări admin
  static const String _collectionPath = 'admin_notifications';

  // Obține ID-ul utilizatorului curent
  String? get _currentUserId => _auth.currentUser?.uid;

  // Trimite notificare către toți utilizatorii
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String message,
    String? type,
    String? icon,
    Color? color,
  }) async {
    try {
      // Verifică dacă utilizatorul este admin (poți adăuga logica ta de verificare)
      if (!_isAdmin()) {
        throw Exception('Only admins can send notifications to all users');
      }

      // Obține toți utilizatorii
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Trimite notificare către fiecare utilizator
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Adaugă notificarea în colecția de notificări a utilizatorului
        await _firestore
            .collection('notifications')
            .doc(userId)
            .collection('user_notifications')
            .add({
          'title': title,
          'message': message,
          'type': type ?? 'admin',
          'icon': icon ?? 'campaign',
          'color': color?.value ?? 0xFF2196F3,
          'isUnread': true,
          'timestamp': FieldValue.serverTimestamp(),
          'isAdminNotification': true,
        });
      }

      print('Notification sent to ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('Error sending notification to all users: $e');
      throw Exception('Failed to send notification to all users');
    }
  }

  // Trimite notificare către utilizatori specifici
  Future<void> sendNotificationToUsers({
    required String title,
    required String message,
    required List<String> userIds,
    String? type,
    String? icon,
    Color? color,
  }) async {
    try {
      if (!_isAdmin()) {
        throw Exception('Only admins can send notifications');
      }

      for (final userId in userIds) {
        await _firestore
            .collection('notifications')
            .doc(userId)
            .collection('user_notifications')
            .add({
          'title': title,
          'message': message,
          'type': type ?? 'admin',
          'icon': icon ?? 'campaign',
          'color': color?.value ?? 0xFF2196F3,
          'isUnread': true,
          'timestamp': FieldValue.serverTimestamp(),
          'isAdminNotification': true,
        });
      }

      print('Notification sent to ${userIds.length} users');
    } catch (e) {
      print('Error sending notification to specific users: $e');
      throw Exception('Failed to send notification to specific users');
    }
  }

  // Trimite notificare către utilizatori activi (care au minat în ultimele 7 zile)
  Future<void> sendNotificationToActiveUsers({
    required String title,
    required String message,
    String? type,
    String? icon,
    Color? color,
  }) async {
    try {
      if (!_isAdmin()) {
        throw Exception('Only admins can send notifications');
      }

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // Obține utilizatorii activi
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastMiningUpdate', isGreaterThan: sevenDaysAgo)
          .get();

      for (final userDoc in activeUsersSnapshot.docs) {
        final userId = userDoc.id;
        
        await _firestore
            .collection('notifications')
            .doc(userId)
            .collection('user_notifications')
            .add({
          'title': title,
          'message': message,
          'type': type ?? 'admin',
          'icon': icon ?? 'campaign',
          'color': color?.value ?? 0xFF2196F3,
          'isUnread': true,
          'timestamp': FieldValue.serverTimestamp(),
          'isAdminNotification': true,
        });
      }

      print('Notification sent to ${activeUsersSnapshot.docs.length} active users');
    } catch (e) {
      print('Error sending notification to active users: $e');
      throw Exception('Failed to send notification to active users');
    }
  }

  // Programează o notificare pentru viitor
  Future<void> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledTime,
    String? type,
    String? icon,
    Color? color,
  }) async {
    try {
      if (!_isAdmin()) {
        throw Exception('Only admins can schedule notifications');
      }

      await _firestore
          .collection(_collectionPath)
          .add({
        'title': title,
        'message': message,
        'type': type ?? 'admin',
        'icon': icon ?? 'campaign',
        'color': color?.value ?? 0xFF2196F3,
        'scheduledTime': scheduledTime,
        'isSent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Notification scheduled for ${scheduledTime.toString()}');
    } catch (e) {
      print('Error scheduling notification: $e');
      throw Exception('Failed to schedule notification');
    }
  }

  // Obține toate notificările programate
  Stream<List<Map<String, dynamic>>> getScheduledNotifications() {
    if (!_isAdmin()) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'admin',
          'icon': data['icon'] ?? 'campaign',
          'color': data['color'] ?? 0xFF2196F3,
          'scheduledTime': data['scheduledTime'],
          'isSent': data['isSent'] ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }

  // Șterge o notificare programată
  Future<void> deleteScheduledNotification(String notificationId) async {
    try {
      if (!_isAdmin()) {
        throw Exception('Only admins can delete scheduled notifications');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(notificationId)
          .delete();

      print('Scheduled notification deleted');
    } catch (e) {
      print('Error deleting scheduled notification: $e');
      throw Exception('Failed to delete scheduled notification');
    }
  }

  // Verifică dacă utilizatorul curent este admin
  bool _isAdmin() {
    // Aici poți implementa logica ta de verificare pentru admin
    // Pentru moment, returnez true pentru test
    return true;
    
    // Exemplu pentru verificare reală:
    // final user = _auth.currentUser;
    // return user?.email == 'admin@stela.com';
  }
} 