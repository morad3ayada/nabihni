import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/add_medicine_screen.dart'; // استورد ملف إضافة علاج
import 'screens/auth/sign_in.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null); // تهيئة التاريخ للغة العربية
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
      initialRoute: '/signin',
      routes: {
        '/signin': (context) => const SignInPage(),
        '/home': (context) => const HomePage(),
        '/add_medicine': (context) => const AddMedicineScreen(), // ✅ أضفنا الراوت هنا
      },
    );
  }
}
