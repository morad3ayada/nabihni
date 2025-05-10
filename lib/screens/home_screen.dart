import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final List<Widget> _pages = [
    const HomeContent(),
    const MedicationPage(),
    const AppointmentsPage(),
    const AppointmentsScreen(),
    const ProfilePage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: "علاجاتي"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "مواعيدي"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_ind), label: "كشفواتك"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "الملف الشخصي"),
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
  String userName = '';
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<DocumentSnapshot> todaysMeds = [];
  List<DocumentSnapshot> todaysAppointments = [];
  Map<String, DateTime?> nextDoseTimeMap = {};
  Map<String, bool> medicationStatus = {};
  Map<String, bool> checkupStatus = {};

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTodayMedications();
    fetchTodayAppointments();
  }

  void fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (mounted) {
      setState(() {
        userName = userDoc.data()?['fullName'] ?? '';
      });
    }
  }

  void fetchTodayMedications() async {
    final today = DateTime.now();
    final meds = await FirebaseFirestore.instance
        .collection('Medications')
        .where('UserID', isEqualTo: userId)
        .get();

    final filtered = meds.docs.where((doc) {
      final data = doc.data();
      final start = (data['start_date'] as Timestamp?)?.toDate();
      final end = (data['end_date'] as Timestamp?)?.toDate();
      return start != null && end != null &&
          today.isAfter(start.subtract(const Duration(days: 1))) &&
          today.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    Map<String, DateTime?> nextDoses = {};

    for (var doc in filtered) {
      final data = doc.data();
      if (!data.containsKey('Dose_times')) continue;

      final rawTimes = data['Dose_times'];
      if (rawTimes is! List) continue;

      List<DateTime> parsedTimes = rawTimes
          .map<DateTime?>((t) => DateTime.tryParse(t.toString()))
          .whereType<DateTime>()
          .where((t) =>
              t.year == today.year &&
              t.month == today.month &&
              t.day == today.day)
          .toList()
        ..sort();

      if (parsedTimes.isNotEmpty) {
        final upcoming = parsedTimes.firstWhere(
          (t) => t.isAfter(DateTime.now()),
          orElse: () => parsedTimes.last,
        );
        nextDoses[doc.id] = upcoming;
      } else {
        nextDoses[doc.id] = null;
      }
    }

    if (mounted) {
      setState(() {
        todaysMeds = filtered;
        nextDoseTimeMap = nextDoses;
      });
    }
  }

  void fetchTodayAppointments() async {
    final today = DateTime.now();
    final appointments = await FirebaseFirestore.instance
        .collection('Patient_Records')
        .where('UserID', isEqualTo: userId)
        .get();

    final filtered = appointments.docs.where((doc) {
      final dateField = doc['checkup_date'];
      if (dateField is! Timestamp) return false;
      final date = dateField.toDate();
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();

    if (mounted) {
      setState(() {
        todaysAppointments = filtered;
      });
    }
  }

  void markMedicationTaken(DocumentSnapshot medDoc, String doseTimeStr) async {
    final key = medDoc.id + doseTimeStr;
    if (medicationStatus[key] == true) return;

    final doseTime = DateTime.tryParse(doseTimeStr);
    if (doseTime == null) return;

    await FirebaseFirestore.instance.collection('Medicine_Adherence').add({
      'medication_id': medDoc.id,
      'user_ID': userId,
      'time_taken': Timestamp.now(),
      'status': true,
      'dose_time': Timestamp.fromDate(doseTime),
      'reminder_sent': false,
    });

    medicationStatus[key] = true;

    List<DateTime> upcoming = (medDoc['Dose_times'] as List)
        .map<DateTime?>((t) => DateTime.tryParse(t.toString()))
        .whereType<DateTime>()
        .where((t) =>
            t.year == DateTime.now().year &&
            t.month == DateTime.now().month &&
            t.day == DateTime.now().day &&
            t.isAfter(DateTime.now()))
        .toList()
      ..sort();

    setState(() {
      nextDoseTimeMap[medDoc.id] = upcoming.isNotEmpty ? upcoming.first : null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الدواء')),
    );
  }

  void markCheckupAttended(DocumentSnapshot apptDoc) async {
    if (checkupStatus[apptDoc.id] == true) return;

    await FirebaseFirestore.instance.collection('Checkup_Adherence').add({
      'checkup_id': apptDoc.id,
      'user_ID': userId,
      'time_taken': Timestamp.now(),
      'status': true,
      'reminder_sent': false,
    });

    setState(() {
      checkupStatus[apptDoc.id] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الحضور للكشف')),
    );
  }

  Widget _styledCheckbox(bool value, Function(bool?) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        decoration: BoxDecoration(
          color: value ? Colors.green : Colors.white,
          border: Border.all(color: Colors.teal),
          borderRadius: BorderRadius.circular(8),
        ),
        width: 24,
        height: 24,
        child: value
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _medicineCard(String title, String subtitle, DocumentSnapshot medDoc, DateTime doseTime) {
    final idWithTime = medDoc.id + doseTime.toIso8601String();
    final isTaken = medicationStatus[idWithTime] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset("assets/pill.png", width: 40),
          const SizedBox(width: 10),
          _styledCheckbox(isTaken, (_) {
            if (!isTaken) {
              markMedicationTaken(medDoc, doseTime.toIso8601String());
            }
          }),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                Text(subtitle, textDirection: TextDirection.rtl),
                Text("الميعاد: ${doseTime.hour}:${doseTime.minute.toString().padLeft(2, '0')}", textDirection: TextDirection.rtl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkupCard(String doctor, String specialty, String type, DateTime date, DateTime time, DocumentSnapshot apptDoc) {
    final isAttended = checkupStatus[apptDoc.id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade100.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, size: 40, color: Colors.teal),
          const SizedBox(width: 10),
          isAttended
              ? ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check),
                  label: const Text('تم الذهاب للكشف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade100,
                    foregroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : _styledCheckbox(false, (_) {
                  markCheckupAttended(apptDoc);
                }),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(doctor, style: const TextStyle(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                Text(specialty, textDirection: TextDirection.rtl),
                Text(type, textDirection: TextDirection.rtl),
                Text("التاريخ: ${date.day}/${date.month}/${date.year} - ${time.hour}:${time.minute.toString().padLeft(2, '0')}", textDirection: TextDirection.rtl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset("assets/med.png", width: 50),
          Expanded(
            child: Text(
              "مرحباً $userName 👋",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
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
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              const Text("علاجاتك اليوم", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Column(
                children: todaysMeds.map((med) {
                  final doseTime = nextDoseTimeMap[med.id];
                  if (doseTime == null) return const SizedBox.shrink();
                  return _medicineCard(
                    med['Medicine_name'] ?? '',
                    med['Medication_type'] ?? '',
                    med,
                    doseTime,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text("كشفواتك اليوم", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Column(
                children: todaysAppointments.map((appt) {
                  final date = (appt['checkup_date'] as Timestamp).toDate();
                  final time = (appt['checkup_time'] as Timestamp).toDate();
                  return _checkupCard(
                    appt['doctor_name'] ?? '',
                    appt['checkup_category'] ?? '',
                    appt['type_of_examination'] ?? '',
                    date,
                    time,
                    appt,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
