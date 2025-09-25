import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'notifications_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final NotificationsService _appNotifications = NotificationsService();

  static Future<void> init() async {
    print('🔄 Initializing NotificationService...');
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit =
        DarwinInitializationSettings();

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(initSettings);
    print('✅ Local notifications plugin initialized');

    // Cerere permisiune notificări iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Cerere permisiune notificări Android (Android 13+)
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    print('✅ NotificationService initialized successfully');
  }

  static Future<void> scheduleMiningNotifications() async {
    print('🔄 Scheduling mining notifications...');
    await _notifications.cancelAll();

    // 0h - imediat după oprire
    await _notifications.zonedSchedule(
      0,
      'Welcome back to Stela Network!',
      'Keep mining daily and grow your STC balance!',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'stc_channel',
          'STC Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    // Add to app notifications with red background
    await _appNotifications.addNotification(
      title: 'Welcome back to Stela Network!',
      message: 'Keep mining daily and grow your STC balance!',
      type: 'reminder',
      icon: 'warning',
      color: Colors.red,
    );
    
    print('✅ Immediate notification shown');

    // DEZACTIVAT: Notificările de la 1h, 2h și 7 zile
    // Doar prima notificare (immediată) este activă
  }

  static Future<void> cancelMiningNotifications() async {
    print('🔄 Cancelling all mining notifications...');
    await _notifications.cancelAll();
    print('✅ All notifications cancelled');
  }
}
