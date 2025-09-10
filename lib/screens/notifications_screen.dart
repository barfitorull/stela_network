import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../providers/theme_provider.dart';
import '../services/notification_settings_service.dart';
import '../services/notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationSettingsService _settingsService = NotificationSettingsService();
  final NotificationsService _notificationsService = NotificationsService();
  
  bool miningAlerts = true;
  bool boosterReminders = true;
  bool referralUpdates = true;
  bool achievementAlerts = true;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _pushNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadNotifications();
    _checkPushNotificationStatus();
  }

  // Încarcă setările de notificări din Firebase
  Future<void> _loadNotificationSettings() async {
    try {
      final settings = await _settingsService.loadNotificationSettings();
      setState(() {
        miningAlerts = settings['miningAlerts'] ?? true;
        boosterReminders = settings['boosterReminders'] ?? true;
        referralUpdates = settings['referralUpdates'] ?? true;
        achievementAlerts = settings['achievementAlerts'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Salvează o setare în Firebase
  Future<void> _saveNotificationSetting(String settingKey, bool value) async {
    try {
      await _settingsService.updateNotificationSetting(settingKey, value);
    } catch (e) {
      print('Error saving notification setting: $e');
      // Revert the UI state if save failed
      setState(() {
        switch (settingKey) {
          case 'miningAlerts':
            miningAlerts = !value;
            break;
          case 'boosterReminders':
            boosterReminders = !value;
            break;
          case 'referralUpdates':
            referralUpdates = !value;
            break;
          case 'achievementAlerts':
            achievementAlerts = !value;
            break;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save setting. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Încarcă notificările din Firebase
  void _loadNotifications() {
    _notificationsService.getUserNotifications()
      .timeout(const Duration(seconds: 10))
      .listen((notifications) {
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false; // Important!
          });
        }
      }, onError: (error) {
        print('Error loading notifications: $error');
        if (mounted) {
          setState(() {
            _isLoading = false; // Important!
          });
        }
      });

    _notificationsService.getUnreadCount()
      .timeout(const Duration(seconds: 10))
      .listen((count) {
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      }, onError: (error) {
        print('Error loading unread count: $error');
      });
  }

  // Check push notification permission status
  Future<void> _checkPushNotificationStatus() async {
    try {
      final status = await Permission.notification.status;
      setState(() {
        _pushNotificationsEnabled = status.isGranted;
      });
    } catch (e) {
      print('Error checking notification permission: $e');
    }
  }

    // Enable push notifications
  Future<void> _enablePushNotifications() async {
    try {
      final status = await Permission.notification.request();
      setState(() {
        _pushNotificationsEnabled = status.isGranted;
      });
      
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Push notifications enabled successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Show dialog to open settings
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            return AlertDialog(
              backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              title: Text(
                'Enable Push Notifications',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Text(
                'To receive mining alerts and bonus notifications, please enable push notifications in your phone settings.',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AppSettings.openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error enabling push notifications: $e');
    }
  }

  // Marchează o notificare ca citită și o șterge
  Future<void> _markAsRead(String notificationId) async {
    try {
      // Marchează ca citită
      await _notificationsService.markAsRead(notificationId);
      
      // Șterge notificarea după o scurtă pauză
      await Future.delayed(const Duration(milliseconds: 500));
      await _notificationsService.deleteNotification(notificationId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification marked as read and removed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark notification as read'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Afișează popup cu conținutul complet al notificării
  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(notification['color'] ?? 0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(notification['icon'] ?? 'notifications'),
                  color: Color(notification['color'] ?? 0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification['title'] ?? '',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['message'] ?? '',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatTimestamp(notification['timestamp']),
                style: TextStyle(
                  color: Color(notification['color'] ?? 0xFF4CAF50),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black54,
                ),
              ),
            ),
            if (notification['isUnread'] == true)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markAsRead(notification['id']);
                },
                child: const Text(
                  'Mark as Read',
                  style: TextStyle(color: Colors.green),
                ),
              ),
          ],
        );
      },
    );
  }

  // Formatează timestamp-ul pentru afișare
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      final now = DateTime.now();
      final notificationTime = (timestamp as Timestamp).toDate();
      final difference = now.difference(notificationTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  // Obține iconița pentru tipul de notificare
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'play_circle':
        return Icons.play_circle;
      case 'flash_on':
        return Icons.flash_on;
      case 'person_add':
        return Icons.person_add;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'notifications':
      default:
        return Icons.notifications;
    }
  }

  // Adaugă notificări de test (pentru debugging)
  Future<void> _addTestNotifications() async {
    try {
      await _notificationsService.addNotification(
        title: 'Mining Session Started',
        message: 'Your mining session has begun. You are now earning STC!',
        type: 'mining',
        icon: 'play_circle',
        color: Colors.green,
      );
      
      await _notificationsService.addNotification(
        title: 'Booster Available',
        message: 'You have boosters available. Use them to increase your mining rate!',
        type: 'booster',
        icon: 'flash_on',
        color: Colors.orange,
      );
      
      await _notificationsService.addNotification(
        title: 'New Referral Joined',
        message: 'John Doe joined your team using your referral code!',
        type: 'referral',
        icon: 'person_add',
        color: Colors.purple,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test notifications added',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add test notifications: $e',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2D1B69), // Dark purple
              const Color(0xFF1A1A1A), // Dark gray
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 32, // Account for padding
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    _buildHeader(),
                                    const SizedBox(height: 24),
                                    
                                    // Recent Notifications (FIRST)
                                    _buildNotificationHistory(),
                                    const SizedBox(height: 24),
                                    
                                    // Notification Settings (SECOND)
                                    _buildNotificationSettings(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_unreadCount New',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Settings',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Mining Alerts',
            'Get notified when mining starts/stops',
            Icons.notifications,
            miningAlerts,
            (value) async {
              setState(() {
                miningAlerts = value;
              });
              await _saveNotificationSetting('miningAlerts', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Mining Alerts ${value ? 'Enabled' : 'Disabled'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                  backgroundColor: value ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            'Booster Reminders',
            'Reminders to use boosters',
            Icons.flash_on,
            boosterReminders,
            (value) async {
              setState(() {
                boosterReminders = value;
              });
              await _saveNotificationSetting('boosterReminders', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Booster Reminders ${value ? 'Enabled' : 'Disabled'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                  backgroundColor: value ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            'Referral Updates',
            'When someone joins your team',
            Icons.people,
            referralUpdates,
            (value) async {
              setState(() {
                referralUpdates = value;
              });
              await _saveNotificationSetting('referralUpdates', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Referral Updates ${value ? 'Enabled' : 'Disabled'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                  backgroundColor: value ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            'Achievement Alerts',
            'Milestone and achievement notifications',
            Icons.emoji_events,
            achievementAlerts,
            (value) async {
              setState(() {
                achievementAlerts = value;
              });
              await _saveNotificationSetting('achievementAlerts', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Achievement Alerts ${value ? 'Enabled' : 'Disabled'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                  backgroundColor: value ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Push Notifications Section
          Container(
            padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
               color: _pushNotificationsEnabled ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(
                 color: _pushNotificationsEnabled ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                 width: 1,
               ),
             ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                                         Icon(
                       _pushNotificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                       color: _pushNotificationsEnabled ? Colors.green : Colors.red,
                       size: 24,
                     ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                                     Text(
                             'PUSH NOTIFICATIONS',
                             style: TextStyle(
                               color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             _pushNotificationsEnabled 
                                 ? 'Great Job! We notify you to come back and earn STC!'
                                 : 'Very Important! Let us remind you to come back and earn STC!',
                             style: TextStyle(
                               color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                               fontSize: 12,
                             ),
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enablePushNotifications,
                                         style: ElevatedButton.styleFrom(
                       backgroundColor: _pushNotificationsEnabled ? Colors.green : Colors.red,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                    child: Text(
                      _pushNotificationsEnabled ? 'ENABLED' : 'ENABLE NOW',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, bool enabled, Function(bool) onChanged) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.green : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: enabled 
                      ? (themeProvider.isDarkMode ? Colors.white : Colors.black)
                      : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: enabled 
                      ? (themeProvider.isDarkMode ? Colors.white70 : Colors.grey)
                      : (themeProvider.isDarkMode ? Colors.grey : Colors.grey),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildNotificationHistory() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_notifications.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    try {
                      // Șterge toate notificările
                      await _notificationsService.deleteAllNotifications();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'All notifications deleted',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to delete all notifications',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_notifications.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ..._notifications.map((notification) {
              return Dismissible(
                key: Key(notification['id'] ?? ''),
                direction: DismissDirection.endToStart, // Swipe left to right
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  // Show confirmation dialog
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                      return AlertDialog(
                        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                        title: Text(
                          'Delete Notification',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete this notification?',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await _notificationsService.deleteNotification(notification['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Notification deleted',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete notification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildNotificationItem(
                  notification['title'] ?? '',
                  notification['message'] ?? '',
                  _formatTimestamp(notification['timestamp']),
                  _getIconData(notification['icon'] ?? 'notifications'),
                  Color(notification['color'] ?? 0xFF4CAF50),
                  notification['isUnread'] ?? false,
                  notificationId: notification['id'],
                  notificationData: notification,
                ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    String time,
    IconData icon,
    Color color,
    bool isUnread, {
    String? notificationId,
    Map<String, dynamic>? notificationData,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // Truncate message if it's too long
    String displayMessage = message;
    if (message.length > 50) {
      displayMessage = '${message.substring(0, 50)}...';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (notificationData != null) {
            _showNotificationDetails(notificationData);
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isUnread 
                                ? (themeProvider.isDarkMode ? Colors.white : Colors.black)
                                : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayMessage,
                    style: TextStyle(
                      color: isUnread 
                          ? (themeProvider.isDarkMode ? Colors.white70 : Colors.grey)
                          : (themeProvider.isDarkMode ? Colors.grey : Colors.grey),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isUnread ? color : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 