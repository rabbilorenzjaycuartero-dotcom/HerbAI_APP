import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/plant_model.dart';

/// Everything notification-related in one place: local on-device reminders
/// (health-check, favorite-revisit) and the FCM 'new_herbs' broadcast topic.
/// Every scheduling/subscribing method is a no-op once the caller has
/// checked Settings' notifications toggle -- ThemeProvider.toggleNotifications
/// is what actually turns these on/off in bulk.
class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Fixed notification ID so re-scheduling replaces rather than stacks.
  static const int _healthCheckNotificationId = 1001;
  static const String _newHerbsTopic = 'new_herbs';

  static const _healthCheckChannel = AndroidNotificationDetails(
    'health_check_reminders',
    'Health Check Reminders',
    channelDescription: 'Reminders to redo your symptom check',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _favoritesChannel = AndroidNotificationDetails(
    'favorite_reminders',
    'Favorite Plant Reminders',
    channelDescription: 'Reminders about plants you favorited',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _newHerbChannel = AndroidNotificationDetails(
    'new_herbs',
    'New Herbs',
    channelDescription: 'Announcements when a new herb is added to HERBAI',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  /// Call once from main() before runApp(). Safe to call even if the user
  /// has notifications disabled -- this only sets up the plumbing; actual
  /// scheduling/subscribing is gated separately by the Settings toggle.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      // Pre-create channels so a backgrounded/killed-app FCM message (which
      // bypasses flutter_local_notifications entirely) lands in a properly
      // named channel instead of Android auto-creating a blank one.
      for (final channel in [_healthCheckChannel, _favoritesChannel, _newHerbChannel]) {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            channel.channelId,
            channel.channelName,
            description: channel.channelDescription,
            importance: channel.importance,
          ),
        );
      }
    } else if (Platform.isIOS) {
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Android suppresses auto-display of foreground notification-payload FCM
    // messages, so the broadcast would be silently swallowed while the app
    // is open unless we show it ourselves via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(android: _newHerbChannel, iOS: DarwinNotificationDetails()),
      );
    });
  }

  static Future<void> scheduleHealthCheckReminder(DateTime lastCheckAt) async {
    await _local.zonedSchedule(
      id: _healthCheckNotificationId,
      title: 'Time for a check-in?',
      body: 'It\'s been a week since your last symptom check -- see if anything has changed.',
      scheduledDate: tz.TZDateTime.from(lastCheckAt.add(const Duration(days: 7)), tz.local),
      notificationDetails: const NotificationDetails(android: _healthCheckChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelHealthCheckReminder() =>
      _local.cancel(id: _healthCheckNotificationId);

  static int _favoriteNotificationId(Plant plant) =>
      2000000000 + (plant.id.hashCode % 100000000).abs();

  static Future<void> scheduleFavoriteRevisitReminder(Plant plant) async {
    await _local.zonedSchedule(
      id: _favoriteNotificationId(plant),
      title: 'Haven\'t tried ${plant.name} yet?',
      body: 'You favorited ${plant.name} a few days ago -- take another look.',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(days: 3)),
      notificationDetails: const NotificationDetails(android: _favoritesChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelFavoriteRevisitReminder(Plant plant) =>
      _local.cancel(id: _favoriteNotificationId(plant));

  static Future<void> cancelAllLocalReminders() => _local.cancelAll();

  static Future<void> subscribeToNewHerbTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(_newHerbsTopic);
    } catch (e) {
      debugPrint('Failed to subscribe to $_newHerbsTopic: $e');
    }
  }

  static Future<void> unsubscribeFromNewHerbTopic() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(_newHerbsTopic);
    } catch (e) {
      debugPrint('Failed to unsubscribe from $_newHerbsTopic: $e');
    }
  }
}
