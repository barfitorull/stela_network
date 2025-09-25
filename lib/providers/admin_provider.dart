import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Admin state
  bool _isLoggedIn = false;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Login admin
  void loginAdmin() {
    _isLoggedIn = true;
    notifyListeners();
  }

  // Logout admin
  void logoutAdmin() {
    _isLoggedIn = false;
    _users.clear();
    _errorMessage = '';
    notifyListeners();
  }

  // Load all users
  Future<void> loadUsers() async {
    debugPrint('🔄 Loading users...');
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('🔄 Querying Firestore...');
      final querySnapshot = await _firestore.collection('users').get();
      debugPrint('🔄 Found ${querySnapshot.docs.length} documents');
      
      _users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('🔄 Processing user: ${data['email']}');
        return {
          'id': doc.id,
          'email': data['email'] ?? 'Unknown',
          'username': data['username'] ?? 'Unknown',
          'balance': data['balance'] ?? 0.0,
          'isMining': data['isMining'] ?? false,
          'activeReferrals': data['activeReferrals'] ?? 0,
          'totalReferrals': data['totalReferrals'] ?? 0,
          'miningRate': data['miningRate'] ?? 0.20,
          'createdAt': data['createdAt'],
          'lastMiningUpdate': data['lastMiningUpdate'],
        };
      }).toList();

      debugPrint('✅ Loaded ${_users.length} users successfully');
    } catch (e) {
      _errorMessage = 'Error loading users: $e';
      debugPrint('❌ Error loading users: $e');
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('🔄 NotifyListeners called');
  }

  // Search users by email or username
  List<Map<String, dynamic>> searchUsers(String query) {
    if (query.isEmpty) return _users;
    
    return _users.where((user) {
      final email = user['email'].toString().toLowerCase();
      final username = user['username'].toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return email.contains(searchQuery) || username.contains(searchQuery);
    }).toList();
  }

  // Credit user balance
  Future<bool> creditUser(String userId, double amount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Credited $amount STC to user $userId');
      return true;
    } catch (e) {
      _errorMessage = 'Error crediting user: $e';
      debugPrint('❌ Error crediting user: $e');
      return false;
    }
  }

  // Debit user balance
  Future<bool> debitUser(String userId, double amount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'balance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Debited $amount STC from user $userId');
      return true;
    } catch (e) {
      _errorMessage = 'Error debiting user: $e';
      debugPrint('❌ Error debiting user: $e');
      return false;
    }
  }

  // Send push notification to all users
  Future<bool> sendNotificationToAll(String title, String message) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('adminSendNotificationToAll');
      final result = await callable.call({
        'title': title,
        'message': message,
      });
      
      if (result.data['success'] == true) {
        debugPrint('✅ Notification sent to all users');
        return true;
      } else {
        _errorMessage = result.data['message'] ?? 'Failed to send notification';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error sending notification: $e';
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  // Send push notification to specific user
  Future<bool> sendNotificationToUser(String userId, String title, String message) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('adminSendNotificationToUser');
      final result = await callable.call({
        'userId': userId,
        'title': title,
        'message': message,
      });
      
      if (result.data['success'] == true) {
        debugPrint('✅ Notification sent to user $userId');
        return true;
      } else {
        _errorMessage = result.data['message'] ?? 'Failed to send notification';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error sending notification: $e';
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  // Get user statistics
  Map<String, dynamic> getUserStats() {
    if (_users.isEmpty) return {};

    final totalUsers = _users.length;
    final activeUsers = _users.where((user) => user['isMining'] == true).length;
    final totalBalance = _users.fold(0.0, (sum, user) => sum + (user['balance'] as double));
    final totalReferrals = _users.fold(0, (sum, user) => sum + (user['totalReferrals'] as int));

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': totalUsers - activeUsers,
      'totalBalance': totalBalance,
      'totalReferrals': totalReferrals,
    };
  }
}
