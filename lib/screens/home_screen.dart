import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'appointments_page.dart';
import 'statements.dart';
import 'medicine_screen.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = const [
    HomeContent(),
    MedicationPage(),
    AppointmentsPage(),
    AppointmentsScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "علاجاتي",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "مواعيدي",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_ind),
            label: "كشفواتك",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "الملف الشخصي",
          ),
        ],
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> userMedicines = [];
  List<DocumentSnapshot> userCheckups = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _getUserMedicines();
    await _getUserCheckups();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  Future<void> _getUserMedicines() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot =
          await _firestore
              .collection('Medications')
              .where('UserID', isEqualTo: user.uid)
              .get();

      setState(() {
        userMedicines = querySnapshot.docs;
      });
    }
  }

  Future<void> _getUserCheckups() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userRef = _firestore.collection('users').doc(user.uid);
      final querySnapshot =
          await _firestore
              .collection('Patient_Records')
              .where('user_id', isEqualTo: userRef)
              .get();

      setState(() {
        userCheckups = querySnapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: getUserData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final userName = snapshot.data?['fullName'] ?? 'بدون اسم';
                  final email = snapshot.data?['email'] ?? 'بلا بريد';
                  return _buildWelcomeCard(userName, email);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "علاجاتك",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              ...userMedicines.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _medicineCard(
                  data['Medicine_name'] ?? '',
                  data['Medication_type'] ?? '',
                  data['Medication_duration'] ?? '',
                  '${data['Dosage_frequency'] ?? ''}',
                  '${data['Pill_count'] ?? ''}',
                  data['ImageURL'] ?? '',
                );
              }),
              const SizedBox(height: 20),
              const Text(
                "كشفواتك",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              ...userCheckups.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _appointmentCard(
                  data['doctor_name'] ?? '',
                  data['checkup_category'] ?? '',
                  data['type_of_examination'] ?? '',
                  data['checkup_date']?.toDate().toString().split(' ')[0] ?? '',
                  '',
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildWelcomeCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/med.png", width: 50),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "مرحباً $name 👋",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    "الإيميل: $email",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "تاريخ تقدمك .. اقتربت من التعافي",
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.8,
            color: Colors.teal,
            backgroundColor: Colors.teal.shade100,
          ),
        ],
      ),
    );
  }

  static Widget _medicineCard(
    String name,
    String type,
    String duration,
    String frequency,
    String count,
    String imageUrl,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: Colors.teal),
          const SizedBox(width: 8),
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
                Text('النوع: $type', textDirection: TextDirection.rtl),
                Text('المدة: $duration', textDirection: TextDirection.rtl),
                Text(
                  'عدد الجرعات: $frequency',
                  textDirection: TextDirection.rtl,
                ),
                Text('عدد الحبات: $count', textDirection: TextDirection.rtl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _appointmentCard(
    String doctor,
    String category,
    String type,
    String date,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  doctor,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
                Text(category, textDirection: TextDirection.rtl),
                Text(type, textDirection: TextDirection.rtl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(date), const SizedBox(width: 6), Text(time)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
