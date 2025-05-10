import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // تحميل المناطق الزمنية
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        print("🔔 تم الضغط على الإشعار: $payload");
      },
    );
  }

  /// طلب الإذن بالإشعارات (ضروري لأندرويد 13+ و iOS)
  static Future<void> requestPermission() async {
    final FlutterLocalNotificationsPlugin flutterNotifications =
        FlutterLocalNotificationsPlugin();

    final bool? granted = await flutterNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    print('📛 تم منح الإذن؟ $granted');
  }

  /// إرسال إشعار فوري
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Default Notifications',
          channelDescription: 'القناة الافتراضية للإشعارات',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// جدولة إشعار في وقت معين (مثلاً للدواء أو الكشف)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Default Notifications',
          channelDescription: 'القناة الافتراضية للإشعارات',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// إلغاء كل الإشعارات المجدولة
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
