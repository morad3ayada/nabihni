import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'screens/auth/sign_in.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/add_statements.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(); // ✅ تهيئة Firebase
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }

  await initializeDateFormatting('ar', null); // ✅ تهيئة التاريخ بالعربية

  // ✅ تهيئة timezone

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
      locale: const Locale('ar'), // ✅ اللغة الافتراضية العربية
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
          textDirection: TextDirection.rtl, // ✅ دعم RTL
          child: child ?? const SizedBox(),
        );
      },
      home: const AuthWrapper(), // ✅ التوجيه على حسب حالة المستخدم
      routes: {
        '/signin': (context) => const SignInPage(),
        '/home': (context) => const HomePage(),
        '/add_medicine': (context) => const AddMedicineScreen(),
        '/add_statements': (context) => const AddExaminationPage(), // ✅ أضفنا ده

      },
    );
  }
}
