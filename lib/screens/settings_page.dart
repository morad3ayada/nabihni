import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final ageController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        nameController.text = data['fullName'] ?? '';
        emailController.text = data['email'] ?? '';
        usernameController.text = data['username'] ?? '';
        ageController.text = data['age']?.toString() ?? '';
      }
    }
  }

  Future<void> _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final newPassword = passwordController.text.trim();

    if (user != null && newPassword.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تحديث كلمة المرور بنجاح')),
        );
        passwordController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❗ فشل تحديث كلمة المرور: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        // تحديث البيانات في Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'age': int.tryParse(ageController.text.trim()) ?? 0,
        });

        // تحديث الإيميل في Authentication إذا تغير
        if (emailController.text.trim() != user.email) {
          await user.updateEmail(emailController.text.trim());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ التغييرات بنجاح')),
        );

        // الانتقال إلى الصفحة الرئيسية بعد الحفظ
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❗ فشل في حفظ التغييرات: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    ageController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.teal,
          elevation: 0,
        ),
        body: Container(
          color: const Color(0xFFF6F6F6),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("الاسم الكامل"),
                  _buildTextField(nameController, 'اكتب اسمك بالعربي'),

                  const SizedBox(height: 16),
                  _buildLabel("البريد الإلكتروني"),
                  _buildTextField(emailController, 'ضع بريدك الإلكتروني هنا'),

                  const SizedBox(height: 16),
                  _buildLabel("اسم المستخدم"),
                  _buildTextField(usernameController, 'اكتب اسم المستخدم'),

                  const SizedBox(height: 16),
                  _buildLabel("العمر"),
                  _buildTextField(ageController, 'اكتب عمرك', keyboardType: TextInputType.number),

                  const SizedBox(height: 16),
                  _buildLabel("كلمة المرور الجديدة"),
                  Stack(
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        textAlign: TextAlign.right,
                        decoration: _inputDecoration('أدخل كلمة المرور الجديدة'),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "حفظ التغييرات",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (passwordController.text.isNotEmpty)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            minimumSize: const Size(100, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "حفظ",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}