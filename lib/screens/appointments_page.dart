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
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _appointments = [];
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadAppointments();
  }

  Future<void> _loadAppointments({bool forceRefresh = false}) async {
    if (_selectedDay == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (forceRefresh) {
        _appointments = [];
      }
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'يجب تسجيل الدخول أولاً';
      });
      return;
    }

    try {
      final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      final nextDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1);
      final List<Map<String, dynamic>> loadedAppointments = [];

      // جلب بيانات الأدوية
      final medsQuery = _firestore
          .collection('Medicine_Adherence')
          .where('user_ID', isEqualTo: user.uid)
          .where('dose_time', isGreaterThanOrEqualTo: selectedDate)
          .where('dose_time', isLessThan: nextDay);

      final medsSnapshot = await medsQuery.get(GetOptions(source: forceRefresh ? Source.server : Source.cache));

      for (var doc in medsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final doseTime = (data['dose_time'] as Timestamp).toDate();
          
          final medDoc = await _firestore
              .collection('Medications')
              .doc(data['medication_id'] as String?)
              .get(GetOptions(source: forceRefresh ? Source.server : Source.cache));

          if (medDoc.exists) {
            final medData = medDoc.data() as Map<String, dynamic>?;
            
            if (!isSameDay(_selectedDay, DateTime.now()) || (data['status'] as bool? ?? false)) {
              loadedAppointments.add({
                "title": medData?['Medicine_name'] ?? 'دواء غير معروف',
                "subtitle": medData?['Medication_type'] ?? '',
                "type": "medicine",
                "isTaken": data['status'] ?? false,
                "time": doseTime,
                "timeTaken": (data['time_taken'] as Timestamp?)?.toDate(),
                "docId": doc.id,
              });
            }
          }
        } catch (e) {
          debugPrint('Error processing medicine document: $e');
        }
      }

      // جلب بيانات الكشوفات
      final checkupQuery = _firestore
          .collection('Checkup_Adherence')
          .where('user_ID', isEqualTo: user.uid)
          .where('time_taken', isGreaterThanOrEqualTo: selectedDate)
          .where('time_taken', isLessThan: nextDay);

      final checkupSnapshot = await checkupQuery.get(GetOptions(source: forceRefresh ? Source.server : Source.cache));

      for (var doc in checkupSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final checkupTime = (data['time_taken'] as Timestamp).toDate();
          
          final checkupDoc = await _firestore
              .collection('Patient_Records')
              .doc(data['checkup_id'] as String?)
              .get(GetOptions(source: forceRefresh ? Source.server : Source.cache));
          
          if (checkupDoc.exists) {
            final checkupData = checkupDoc.data() as Map<String, dynamic>?;
            
            if (!isSameDay(_selectedDay, DateTime.now()) || (data['status'] as bool? ?? false)) {
              loadedAppointments.add({
                "title": checkupData?['doctor_name'] ?? 'طبيب غير معروف',
                "subtitle": checkupData?['checkup_category'] ?? '',
                "type": "checkup",
                "isTaken": data['status'] ?? false,
                "time": checkupTime,
                "timeTaken": checkupTime,
                "docId": doc.id,
              });
            }
          }
        } catch (e) {
          debugPrint('Error processing checkup document: $e');
        }
      }

      loadedAppointments.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

      setState(() {
        _appointments = loadedAppointments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء جلب البيانات: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'حدث خطأ غير معروف'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF3F9),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isSameDay(_selectedDay, DateTime.now()))
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : () => _loadAppointments(forceRefresh: true),
                    color: Colors.teal,
                  ),
                const Expanded(
                  child: Text(
                    "سجل المواعيد",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
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
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _appointments.isNotEmpty
                        ? RefreshIndicator(
                            onRefresh: () => _loadAppointments(forceRefresh: true),
                            child: ListView.builder(
                              itemCount: _appointments.length,
                              itemBuilder: (context, index) {
                                return _buildAppointmentItem(_appointments[index]);
                              },
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/empty.png',
                                  width: 120,
                                  height: 120,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isSameDay(_selectedDay, DateTime.now())
                                      ? "لا يوجد مواعيد تم تنفيذها اليوم"
                                      : "لا يوجد مواعيد مسجلة في هذا اليوم",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(Map<String, dynamic> appointment) {
    final isTaken = appointment['isTaken'] as bool;
    final time = appointment['time'] as DateTime;
    final timeString = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // صورة حسب نوع الموعد
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(
                    appointment['type'] == "medicine" 
                      ? 'assets/pill.png' // صورة الدواء
                      : 'assets/doctor.jpg', // صورة الكشف الطبي
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((appointment['subtitle'] as String?)?.isNotEmpty ?? false)
                    Text(
                      appointment['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    isTaken 
                      ? appointment['timeTaken'] != null 
                          ? 'تم في: ${_formatTime(appointment['timeTaken'] as DateTime)} (مقرر: $timeString)'
                          : 'مقرر في: $timeString'
                      : 'كان مقرراً في: $timeString',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTaken ? "تم التنفيذ" : "لم يتم",
                    style: TextStyle(
                      color: isTaken ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // أيقونة الحالة (صح/خطأ)
            Icon(
              isTaken ? Icons.check_circle : Icons.cancel,
              color: isTaken ? Colors.green : Colors.red,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}