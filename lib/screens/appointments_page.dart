import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _appointments = [];
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final selectedDate = _formatDateTimeForComparison(
      _selectedDay ?? _focusedDay,
    );

    final List<Map<String, dynamic>> loadedAppointments = [];

    // Load medications
    final medsSnapshot =
        await _firestore
            .collection('Medications')
            .where('UserID', isEqualTo: user.uid)
            .get();

    for (var doc in medsSnapshot.docs) {
      final data = doc.data();
      final doseTimes = data['Dose_times'] as List<dynamic>? ?? [];

      for (var doseTime in doseTimes) {
        if (doseTime != null && _isSameDay(doseTime.toDate(), selectedDate)) {
          loadedAppointments.add({
            "title": data['Medicine_name'],
            "subtitle": data['Medication_type'],
            "type": "medicine",
            "isTaken": data['status'] ?? false,
          });
        }
      }
    }

    // Load checkups
    final checkupsSnapshot =
        await _firestore
            .collection('Patient_Records')
            .where('UserID', isEqualTo: user.uid)
            .get();

    for (var doc in checkupsSnapshot.docs) {
      final data = doc.data();
      final checkupDate = data['checkup_date']?.toDate();

      if (checkupDate != null && _isSameDay(checkupDate, selectedDate)) {
        loadedAppointments.add({
          "title": data['doctor_name'],
          "subtitle": data['checkup_category'], // تغيير هنا
          "type": "checkup",
          "isTaken": data['status'] ?? false,
        });
      }
    }

    setState(() {
      _appointments = loadedAppointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDF3F9),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "مواعيد",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              locale: 'ar',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadAppointments();
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekendStyle: TextStyle(fontWeight: FontWeight.bold),
                weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  return Center(
                    child: Text(
                      _getArabicDayName(day.weekday),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _appointments.isNotEmpty
                ? Expanded(
                  child: ListView.builder(
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      var item = _appointments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: _buildSimpleAppointmentItem(item),
                      );
                    },
                  ),
                )
                : const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text(
                    "لا يوجد مواعيد لهذا اليوم",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleAppointmentItem(Map<String, dynamic> appointment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // الصورة
          appointment['type'] == "medicine"
              ? Image.asset("assets/pill.png", width: 40)
              : Image.asset("assets/doctor.jpg", width: 40),

          const SizedBox(width: 16),

          // المحتوى النصي
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (appointment['subtitle'] != null)
                  Text(
                    appointment['subtitle'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          // حالة الموعد
          Icon(
            appointment['isTaken'] ? Icons.check_circle : Icons.cancel,
            color: appointment['isTaken'] ? Colors.green : Colors.red,
            size: 28,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _formatDateTimeForComparison(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _getArabicDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "الإثنين";
      case 2:
        return "الثلاثاء";
      case 3:
        return "الأربعاء";
      case 4:
        return "الخميس";
      case 5:
        return "الجمعة";
      case 6:
        return "السبت";
      case 7:
        return "الأحد";
      default:
        return "";
    }
  }
}
