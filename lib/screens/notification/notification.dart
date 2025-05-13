import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  static Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final granted = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
        return granted ?? false;
      } catch (e) {
        debugPrint('Error requesting exact alarm permission: $e');
        return false;
      }
    }
    return true;
  }

  static Future<void> showNotification({
    required String? title,
    required String? body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      0,
      title ?? 'Notification',
      body ?? 'You have a new notification',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime medicationTime,
  }) async {
    final scheduledTime = tz.TZDateTime.from(medicationTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (scheduledTime.isBefore(now)) {
      debugPrint('Cannot schedule notification in the past');
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleCheckupReminder({
    required int id,
    required String title,
    required String body,
    required DateTime checkupTime,
  }) async {
    final scheduledTime = tz.TZDateTime.from(checkupTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (scheduledTime.isBefore(now)) {
      debugPrint('Cannot schedule checkup notification in the past');
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      id + 1000, // Different ID range for checkups
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkup_channel',
          'Checkup Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}