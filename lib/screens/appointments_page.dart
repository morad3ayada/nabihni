import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, List<Map<String, dynamic>>> _appointments = {
    "2025-04-17": [
      {"name": "Aspirin 100 mg", "isTaken": true},
      {"name": "Panadol 500 mg", "isTaken": false},
    ],
    "2025-04-18": [
      {"name": "Vitamin C", "isTaken": true},
    ],
  };

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> todayAppointments =
        _appointments[_formatDate(_selectedDay ?? _focusedDay)] ?? [];

    return Container(
      color: const Color(0xFFFDF3F9), // خلفية وردية خفيفة
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
            todayAppointments.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: todayAppointments.length,
                      itemBuilder: (context, index) {
                        var item = todayAppointments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child:
                              _buildMedicineItem(item["name"], item["isTaken"]),
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

  Widget _buildMedicineItem(String name, bool isTaken) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset("assets/pill.png", width: 32),
          Text(name),
          Icon(
            isTaken ? Icons.check_circle : Icons.cancel,
            color: isTaken ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
