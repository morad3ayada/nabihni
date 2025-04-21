import 'package:flutter/material.dart';
import 'appointments_page.dart';
import 'statements.dart'; // ✅ تم تعديل المسار هنا
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

  final List<Widget> _pages = [
    const HomeContent(), // الصفحة الرئيسية
    const MedicationPage(), // صفحة علاجاتي
    const AppointmentsPage(), // صفحة مواعيدي
    const AppointmentsScreen(), // ✅ تم التبديل إلى صفحة statements.dart
    const ProfilePage(), // صفحة الملف الشخصي
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
              icon: Icon(Icons.medical_services), label: "علاجاتي"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "مواعيدي"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_ind), label: "كشفواتك"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "الملف الشخصي"),
        ],
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              const Text(
                "علاجاتك",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _medicineCard("Ibuprofen", "مضاد حيوي", 0.5)),
                  const SizedBox(width: 12),
                  Expanded(child: _medicineCard("Parastomal", "مسكن عام", 0.5)),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "كشفواتك",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              _appointmentCard(
                "د. محمد حسن",
                "تخصص باطنة",
                "فحص دوري",
                "28/02/2025",
                "09:00 م",
              ),
              _appointmentCard(
                "د. محمد حسن",
                "تخصص باطنة",
                "فحص دوري",
                "28/02/2025",
                "09:00 م",
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildWelcomeCard() {
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
              const Text(
                "مرحباً شهد 👋",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
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

  static Widget _medicineCard(String title, String subtitle, double progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
          Text(subtitle, textDirection: TextDirection.rtl),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            color: Colors.teal,
            backgroundColor: Colors.teal.shade100,
          ),
        ],
      ),
    );
  }

  static Widget _appointmentCard(
    String doctor,
    String specialty,
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
                Text(specialty, textDirection: TextDirection.rtl),
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
