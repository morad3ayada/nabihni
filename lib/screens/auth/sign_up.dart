import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _patientCompanionEmailController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                _buildLabel("الاسم الكامل"),
                _buildTextField(_fullNameController, 'اكتب اسمك بالعربي'),

                const SizedBox(height: 16),
                _buildLabel("البريد الإلكتروني"),
                _buildTextField(_emailController, 'ضع بريدك الإلكتروني هنا'),

                const SizedBox(height: 16),
                _buildLabel("كلمة المرور"),
                _buildPasswordField(_passwordController, 'اكتب كلمة المرور', true),

                const SizedBox(height: 16),
                _buildLabel("تأكيد كلمة المرور"),
                _buildPasswordField(_confirmPasswordController, 'أعد إدخال كلمة المرور', false),

                const SizedBox(height: 16),
                _buildLabel("اسم المستخدم"),
                _buildTextField(_usernameController, 'اكتب اسم المستخدم'),

                const SizedBox(height: 16),
                _buildLabel("العمر"),
                _buildTextField(_ageController, 'اكتب عمرك', keyboardType: TextInputType.number),

                const SizedBox(height: 16),
                _buildLabel("البريد الإلكتروني للمرافق"),
                _buildTextField(_patientCompanionEmailController, 'اكتب إيميل المرافق'),

                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "تسجيل حساب",
                          style: TextStyle(color: Colors.white),
                        ),
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
                      const Text("لديك حساب بالفعل؟ "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                        child: const Text(
                          "تسجيل الدخول",
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
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

  Widget _buildPasswordField(TextEditingController controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isPasswordObscured : _isConfirmPasswordObscured,
      textAlign: TextAlign.right,
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            isPassword ? (_isPasswordObscured ? Icons.visibility_off : Icons.visibility) :
                          (_isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility),
          ),
          onPressed: () => setState(() {
            if (isPassword) {
              _isPasswordObscured = !_isPasswordObscured;
            } else {
              _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
            }
          }),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final username = _usernameController.text.trim();
    final age = _ageController.text.trim();
    final patientCompanionEmail = _patientCompanionEmailController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || username.isEmpty || age.isEmpty || patientCompanionEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ كل الحقول مطلوبة')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ كلمتا السر غير متطابقتين')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // ✅ هنا عدلنا اسم الـ Collection إلى users
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fullName': fullName,
        'email': email,
        'username': username,
        'age': int.parse(age),
        'patient_companion_Email': patientCompanionEmail,
        'createdAt': Timestamp.now(),
        'userID': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إنشاء الحساب بنجاح')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ خطأ أثناء التسجيل: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
}
