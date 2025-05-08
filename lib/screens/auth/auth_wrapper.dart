import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in.dart';
import '../home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const HomePage(); // ✅ المستخدم مسجل دخول
    } else {
      return const SignInPage(); // ❌ المستخدم مش مسجل دخول
    }
  }
}
