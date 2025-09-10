import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection path pentru notificări
  static const String _collectionPath = 'notifications';

  // Obține ID-ul utilizatorului curent
  String? get _currentUserId => _auth.currentUser?.uid;

  // Adaugă o notificare nouă
  Future<void> addNotification({
    required String title,
    required String message,
    required String type, // 'mining', 'booster', 'referral', 'achievement'
    String? icon,
    Color? color,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .collection('user_notifications')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'icon': icon ?? 'notifications',
        'color': color?.value ?? 0xFF4CAF50,
        'isUnread': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Notification added successfully');
    } catch (e) {
      print('Error adding notification: $e');
      throw Exception('Failed to add notification');
    }
  }

  // Obține ultimele 3 notificări ale utilizatorului
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .doc(_currentUserId)
        .collection('user_notifications')
        .orderBy('timestamp', descending: true)
        .limit(3) // Limitează la ultimele 3 notificări
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'general',
          'icon': data['icon'] ?? 'notifications',
          'color': data['color'] ?? 0xFF4CAF50,
          'isUnread': data['isUnread'] ?? false,
          'timestamp': data['timestamp'],
        };
      }).toList();
    });
  }

  // Obține numărul de notificări necitite
  Stream<int> getUnreadCount() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_collectionPath)
        .doc(_currentUserId)
        .collection('user_notifications')
        .where('isUnread', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Marchează o notificare ca citită
  Future<void> markAsRead(String notificationId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .collection('user_notifications')
          .doc(notificationId)
          .update({'isUnread': false});

      print('Notification marked as read');
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read');
    }
  }

  // Marchează toate notificările ca citite
  Future<void> markAllAsRead() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .collection('user_notifications')
          .where('isUnread', isEqualTo: true)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isUnread': false});
      }

      await batch.commit();
      print('All notifications marked as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read');
    }
  }

  // Șterge o notificare
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .collection('user_notifications')
          .doc(notificationId)
          .delete();

      print('Notification deleted');
    } catch (e) {
      print('Error deleting notification: $e');
      throw Exception('Failed to delete notification');
    }
  }

  // Șterge toate notificările
  Future<void> deleteAllNotifications() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final allNotifications = await _firestore
          .collection(_collectionPath)
          .doc(_currentUserId)
          .collection('user_notifications')
          .get();

      for (final doc in allNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All notifications deleted');
    } catch (e) {
      print('Error deleting all notifications: $e');
      throw Exception('Failed to delete all notifications');
    }
  }
} 