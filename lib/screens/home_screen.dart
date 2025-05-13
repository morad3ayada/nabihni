import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  
  final List<Widget> _pages = [
    const HomeContent(),
    const MedicationPage(),
    const AppointmentsPage(),
    const AppointmentsScreen(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

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
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "كشفواتك"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "الملف الشخصي"),
        ],
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
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
  List<Map<String, dynamic>> allDoses = [];
  List<DocumentSnapshot> todaysAppointments = [];
  Map<String, bool> medicationStatus = {};
  Map<String, bool> checkupStatus = {};
  bool _showAllMeds = false;
  bool _showAllAppointments = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    FirebaseFirestore.instance
        .collection('Medicine_Adherence')
        .where('user_ID', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _updateMedicationStatus(snapshot);
      }
    });

    FirebaseFirestore.instance
        .collection('Checkup_Adherence')
        .where('user_ID', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _updateCheckupStatus(snapshot);
      }
    });
  }

  void _updateMedicationStatus(QuerySnapshot snapshot) {
    final today = DateTime.now();
    setState(() {
      for (var doc in snapshot.docs) {
        final doseTime = doc['dose_time']?.toDate();
        if (doseTime != null && isSameDay(doseTime, today)) {
          medicationStatus['${doc['medication_id']}_${doseTime.toIso8601String()}'] = doc['status'] == true;
        }
      }
      _sortItems();
    });
  }

  void _updateCheckupStatus(QuerySnapshot snapshot) {
    setState(() {
      for (var doc in snapshot.docs) {
        checkupStatus[doc['checkup_id']] = doc['status'] == true;
      }
      _sortItems();
    });
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        fetchUserData(),
        fetchTodayMedications(),
        fetchTodayAppointments(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (mounted && userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['fullName'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> fetchTodayMedications() async {
    try {
      final today = DateTime.now();
      final meds = await FirebaseFirestore.instance
          .collection('Medications')
          .where('UserID', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> doses = [];
      for (var med in meds.docs) {
        final data = med.data();
        final start = (data['start_date'] as Timestamp?)?.toDate();
        final end = (data['end_date'] as Timestamp?)?.toDate();
        
        if (start != null && end != null && 
            today.isAfter(start.subtract(const Duration(days: 1))) &&
            today.isBefore(end.add(const Duration(days: 1)))) {
          
          final doseTimes = data['Dose_times'] as List<dynamic>? ?? [];
          for (var t in doseTimes) {
            final doseTime = t is Timestamp ? t.toDate() : DateTime.tryParse(t.toString());
            if (doseTime != null && isSameDay(doseTime, today)) {
              doses.add({
                'medDoc': med,
                'doseTime': doseTime,
                'title': data['Medicine_name']?.toString() ?? '',
                'type': data['Medicine_form']?.toString() ?? '',
                'category': data['Medication_category']?.toString() ?? '',
              });
            }
          }
        }
      }

      final adherenceSnapshot = await FirebaseFirestore.instance
          .collection('Medicine_Adherence')
          .where('user_ID', isEqualTo: userId)
          .where('time_taken', isGreaterThan: Timestamp.fromDate(DateTime(today.year, today.month, today.day)))
          .get();

      for (var doc in adherenceSnapshot.docs) {
        final doseTime = doc['dose_time']?.toDate();
        if (doseTime != null) {
          medicationStatus['${doc['medication_id']}_${doseTime.toIso8601String()}'] = doc['status'] == true;
        }
      }

      if (mounted) {
        setState(() {
          allDoses = doses;
          _sortItems();
        });
      }
    } catch (e) {
      debugPrint('Error fetching medications: $e');
    }
  }

  Future<void> fetchTodayAppointments() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final appointments = await FirebaseFirestore.instance
          .collection('Patient_Records')
          .where('UserID', isEqualTo: userId)
          .where('checkup_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('checkup_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final checkupAdherence = await FirebaseFirestore.instance
          .collection('Checkup_Adherence')
          .where('user_ID', isEqualTo: userId)
          .where('time_taken', isGreaterThan: Timestamp.fromDate(startOfDay))
          .get();

      for (var doc in checkupAdherence.docs) {
        checkupStatus[doc['checkup_id']] = doc['status'] == true;
      }

      if (mounted) {
        setState(() {
          todaysAppointments = appointments.docs;
          _sortItems();
        });
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  void _sortItems() {
    setState(() {
      allDoses.sort((a, b) {
        final aKey = '${a['medDoc'].id}_${a['doseTime'].toIso8601String()}';
        final bKey = '${b['medDoc'].id}_${b['doseTime'].toIso8601String()}';
        final aTaken = medicationStatus[aKey] ?? false;
        final bTaken = medicationStatus[bKey] ?? false;
        
        if (aTaken && !bTaken) return 1;
        if (!aTaken && bTaken) return -1;
        return a['doseTime'].compareTo(b['doseTime']);
      });

      todaysAppointments.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = (aData['checkup_time'] as Timestamp?)?.toDate() ?? 
                     (aData['checkup_date'] as Timestamp).toDate();
        final bTime = (bData['checkup_time'] as Timestamp?)?.toDate() ?? 
                     (bData['checkup_date'] as Timestamp).toDate();
        
        final aAttended = checkupStatus[a.id] ?? false;
        final bAttended = checkupStatus[b.id] ?? false;
        
        if (aAttended && !bAttended) return 1;
        if (!aAttended && bAttended) return -1;
        return aTime.compareTo(bTime);
      });
    });
  }

  Future<void> markMedicationTaken(Map<String, dynamic> dose) async {
    try {
      final key = '${dose['medDoc'].id}_${dose['doseTime'].toIso8601String()}';
      if (medicationStatus[key] == true) return;

      await FirebaseFirestore.instance.collection('Medicine_Adherence').add({
        'medication_id': dose['medDoc'].id,
        'user_ID': userId,
        'time_taken': Timestamp.now(),
        'status': true,
        'dose_time': Timestamp.fromDate(dose['doseTime']),
        'reminder_sent': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدواء')),
        );
        setState(() {
          medicationStatus[key] = true;
          _sortItems();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
      debugPrint('Error marking medication taken: $e');
    }
  }

  Future<void> markCheckupAttended(DocumentSnapshot apptDoc) async {
    try {
      if (checkupStatus[apptDoc.id] == true) return;

      await FirebaseFirestore.instance.collection('Checkup_Adherence').add({
        'checkup_id': apptDoc.id,
        'user_ID': userId,
        'time_taken': Timestamp.now(),
        'status': true,
        'reminder_sent': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الحضور للكشف')),
        );
        setState(() {
          checkupStatus[apptDoc.id] = true;
          _sortItems();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
      debugPrint('Error marking checkup attended: $e');
    }
  }

  Widget _styledCheckbox(bool? value, Function(bool?) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!(value ?? false)),
      child: Container(
        decoration: BoxDecoration(
          color: (value ?? false) ? Colors.green : Colors.white,
          border: Border.all(color: Colors.teal),
          borderRadius: BorderRadius.circular(8),
        ),
        width: 24,
        height: 24,
        child: (value ?? false)
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _medicineCard(Map<String, dynamic> dose) {
    final key = '${dose['medDoc'].id}_${dose['doseTime'].toIso8601String()}';
    final isTaken = medicationStatus[key] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTaken ? Colors.green.shade50 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTaken ? Colors.green : Colors.teal,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Image.asset("assets/pill.png", width: 50),
          const SizedBox(width: 10),
          _styledCheckbox(isTaken, (_) {
            if (!isTaken) {
              markMedicationTaken(dose);
            }
          }),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(dose['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                if (dose['type'].isNotEmpty) Text("النوع: ${dose['type']}"),
                if (dose['category'].isNotEmpty) Text("التصنيف: ${dose['category']}"),
                Text("الميعاد: ${formatTime(dose['doseTime'])}"),
                if (isTaken) 
                  Text("تم التسجيل", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkupCard(DocumentSnapshot apptDoc) {
    final isAttended = checkupStatus[apptDoc.id] ?? false;
    final data = apptDoc.data() as Map<String, dynamic>;
    final time = (data['checkup_time'] as Timestamp?)?.toDate() ?? 
                (data['checkup_date'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAttended ? Colors.green.shade50 : Colors.teal.shade100.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAttended ? Colors.green : Colors.teal,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/medical-checkup.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          _styledCheckbox(isAttended, (_) {
            if (!isAttended) {
              markCheckupAttended(apptDoc);
            }
          }),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(data['doctor_name']?.toString() ?? '', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (data['checkup_category']?.isNotEmpty ?? false) 
                  Text("التخصص: ${data['checkup_category']}"),
                if (data['type_of_examination']?.isNotEmpty ?? false) 
                  Text("النوع: ${data['type_of_examination']}"),
                Text("الوقت: ${formatTime(time)}"),
                if (isAttended) 
                  Text("تم الحضور", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
          Image.asset("assets/med.png", width: 60),
          Expanded(
            child: Text(
              "مرحباً ${userName.isNotEmpty ? userName : 'مستخدم'} 👋",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final shownDoses = _showAllMeds 
        ? allDoses 
        : allDoses.take(allDoses.length > 3 ? 3 : allDoses.length).toList();

    final shownAppointments = _showAllAppointments 
        ? todaysAppointments 
        : todaysAppointments.take(todaysAppointments.length > 3 ? 3 : todaysAppointments.length).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            
            if (allDoses.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (allDoses.length > 3)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllMeds = !_showAllMeds;
                        });
                      },
                      child: Text(_showAllMeds ? 'عرض أقل' : 'عرض الكل (${allDoses.length})'),
                    ),
                  const Text("علاجاتك اليوم", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: shownDoses.map((dose) => _medicineCard(dose)).toList(),
              ),
              const SizedBox(height: 20),
            ],
            
            if (todaysAppointments.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (todaysAppointments.length > 3)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllAppointments = !_showAllAppointments;
                        });
                      },
                      child: Text(_showAllAppointments ? 'عرض أقل' : 'عرض الكل (${todaysAppointments.length})'),
                    ),
                  const Text("كشفواتك اليوم", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: shownAppointments.map((appt) => _checkupCard(appt)).toList(),
              ),
            ],
            
            if (allDoses.isEmpty && todaysAppointments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("لا يوجد مواعيد أو علاجات لهذا اليوم"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}