import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password.dart';
import 'package:nabihni/screens/home_screen.dart';
import 'package:nabihni/screens/auth/sign_up.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isPasswordObscured = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 40),
              const Text("البريد الإلكتروني", textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'ضع بريدك الإلكتروني هنا',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              const Text("كلمة المرور", textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                decoration: InputDecoration(
                  hintText: 'ضع كلمة المرور هنا',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                    );
                  },
                  child: const Text(
                    "نسيت كلمة المرور",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "تسجيل الدخول",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // لم يتم تنفيذ الدخول كزائر بعد
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("الدخول كزائر"),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("أو سجل من خلال"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  socialButton('assets/google.png'),
                  socialButton('assets/facebook.png'),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  children: [
                    const Text("ليس لديك حساب؟ "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        "أنشئ حساب جديد",
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget socialButton(String path) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: Image.asset(path, width: 30, height: 30, fit: BoxFit.contain),
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ البريد الإلكتروني وكلمة المرور مطلوبين')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ حل مشكلة الرجوع لتسجيل الدخول بعد تسجيل الدخول:
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeContent()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
      if (e.code == 'user-not-found') {
        errorMessage = '❗ المستخدم غير موجود';
      } else if (e.code == 'wrong-password') {
        errorMessage = '❗ كلمة المرور خاطئة';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
