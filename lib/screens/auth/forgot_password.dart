import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نسيت كلمة المرور'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 24),

              // أيقونة القفل
              Center(
                child: Icon(Icons.lock, size: 80, color: Colors.teal.shade400),
              ),

              const SizedBox(height: 16),

              // العنوان الرئيسي
              const Center(
                child: Text(
                  'نسيت كلمة المرور الخاصة بك',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),

              const SizedBox(height: 8),

              // تعليمات
              const Center(
                child: Text(
                  'قم بإدخال بريدك الإلكتروني بالأسفل لإعادة إدخال كلمة المرور الجديدة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textDirection: TextDirection.rtl,
                ),
              ),

              const SizedBox(height: 10),

              // حقل البريد الإلكتروني
              const Text("البريد الإلكتروني", textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              TextField(
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ضع بريدك الإلكتروني هنا',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    // منطق إرسال الرابط
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إرسال',
                    style: TextStyle(color: Colors.white),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // تسجيل دخول
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // يرجع لصفحة تسجيل الدخول
                  },
                  child: const Text(
                    'تسجيل دخول',
                    style: TextStyle(color: Colors.teal),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
