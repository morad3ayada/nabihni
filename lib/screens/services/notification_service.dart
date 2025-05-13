// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   late FlutterLocalNotificationsPlugin _notificationsPlugin;

//   Future<void> init() async {
//     tz.initializeTimeZones();
    
//     const AndroidInitializationSettings initializationSettingsAndroid = 
//       AndroidInitializationSettings('@mipmap/ic_launcher');
      
//     final InitializationSettings initializationSettings = 
//       InitializationSettings(android: initializationSettingsAndroid);
      
//     _notificationsPlugin = FlutterLocalNotificationsPlugin();
//     await _notificationsPlugin.initialize(initializationSettings);
//   }

//   Future<void> scheduleMedicationNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//   }) async {
//     await _notificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledTime, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'medication_channel',
//           'Medication Reminders',
//           importance: Importance.high,
//           priority: Priority.high,
//         ),
//       ),
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation: 
//         UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   Future<void> scheduleCheckupNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//   }) async {
//     await _notificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledTime.subtract(const Duration(hours: 1)), tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'checkup_channel',
//           'Checkup Reminders',
//           importance: Importance.high,
//           priority: Priority.high,
//         ),
//       ),
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation: 
//         UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   Future<void> cancelAllNotifications() async {
//     await _notificationsPlugin.cancelAll();
//   }
// }