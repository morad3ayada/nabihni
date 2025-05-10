import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/auth/sign_in.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/add_statements.dart';

// خلفية: التعامل مع رسائل Firebase عندما يكون التطبيق في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 رسالة في الخلفية: ${message.notification?.title}");
  // هنا يمكن إرسال إشعار أو التعامل مع الرسالة كما تريد
}

// تهيئة الإشعارات
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  // إعدادات القناة للإشعارات في أندرويد
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel_id', // المعرف الخاص بالقناة
    'Default Notifications', // اسم القناة
    description: 'القناة الافتراضية للإشعارات', // وصف القناة
    importance: Importance.high, // مستوى الإشعارات
  );

  // إنشاء القناة على أندرويد
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // تهيئة الإشعارات
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      print("🔗 تم الضغط على الإشعار: $payload");
      // يمكن إضافة تعامل مع الاستجابة مثل التوجيه لصفحة معينة
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initializeDateFormatting('ar', null);
  tz.initializeTimeZones();

  // إعداد Firebase Messaging لتعامل مع الرسائل في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // تهيئة الإشعارات
  await initializeNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nabihni',
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
      home: const AuthWrapper(),
      routes: {
        '/signin': (context) => const SignInPage(),
        '/home': (context) => const HomePage(),
        '/add_medicine': (context) => const AddMedicineScreen(),
        '/add_statements': (context) => const AddExaminationPage(),

      },
    );
  }
}
