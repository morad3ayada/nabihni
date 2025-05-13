import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AddExaminationPage extends StatefulWidget {
  const AddExaminationPage({super.key});

  @override
  State<AddExaminationPage> createState() => _AddExaminationPageState();
}

class _AddExaminationPageState extends State<AddExaminationPage> {
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();

  String? selectedType = 'دوري';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isLoading = false;

  final List<String> examinationTypes = ['دوري', 'مستعجل', 'متابعة', 'جديد'];

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'examination_channel_id',
      'مواعيد الكشوفات',
      description: 'إشعارات تذكير بمواعيد الكشوفات',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _scheduleExaminationNotification(DateTime examinationDateTime) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // إشعار قبل يوم من الموعد
      final dayBefore = examinationDateTime.subtract(const Duration(days: 1));
      
      // إشعار قبل ساعتين من الموعد
      final twoHoursBefore = examinationDateTime.subtract(const Duration(hours: 2));

      await FirebaseFirestore.instance.collection('scheduled_notifications').add({
        'userId': user.uid,
        'notificationType': 'examination_reminder',
        'scheduledTime': Timestamp.fromDate(dayBefore),
        'title': 'تذكير بموعد الكشف',
        'body': 'لديك كشف غداً مع الدكتور ${doctorNameController.text}',
        'createdAt': FieldValue.serverTimestamp(),
        'delivered': false,
      });

      await FirebaseFirestore.instance.collection('scheduled_notifications').add({
        'userId': user.uid,
        'notificationType': 'examination_reminder',
        'scheduledTime': Timestamp.fromDate(twoHoursBefore),
        'title': 'تذكير بموعد الكشف',
        'body': 'لديك كشف بعد ساعتين مع الدكتور ${doctorNameController.text}',
        'createdAt': FieldValue.serverTimestamp(),
        'delivered': false,
      });

      debugPrint('تم جدولة إشعارات الكشف بنجاح');
    } catch (e) {
      debugPrint('!!! فشل جدولة إشعارات الكشف: ${e.toString()}');
    }
  }

  Future<void> _showConfirmationNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'examination_channel_id',
      'مواعيد الكشوفات',
      channelDescription: 'إشعارات تذكير بمواعيد الكشوفات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'تمت إضافة الكشف بنجاح',
      'تم جدولة إشعارات للكشف مع الدكتور ${doctorNameController.text}',
      platformChannelSpecifics,
    );
  }

  Future<void> _submitExamination() async {
    if (doctorNameController.text.isEmpty ||
        specialtyController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء جميع الحقول")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى تسجيل الدخول أولاً")),
        );
        return;
      }

      final DateTime examinationDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final Timestamp examinationDateOnly = Timestamp.fromDate(
          DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day));

      final Timestamp examinationDateTimeFull = Timestamp.fromDate(examinationDateTime);

      await FirebaseFirestore.instance.collection('Patient_Records').add({
        'UserID': user.uid,
        'checkup_category': specialtyController.text,
        'checkup_date': examinationDateOnly,
        'checkup_time': examinationDateTimeFull,
        'doctor_name': doctorNameController.text,
        'type_of_examination': selectedType,
        'Created_at': FieldValue.serverTimestamp(),
      });

      // جدولة الإشعارات
      await _scheduleExaminationNotification(examinationDateTime);

      // عرض إشعار تأكيد
      await _showConfirmationNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمت إضافة الكشف بنجاح")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: TextDirection.rtl,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            alignment: Alignment.centerRight,
            items: items.map((value) {
              return DropdownMenuItem<String>(
                value: value,
                alignment: Alignment.centerRight,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("تاريخ الفحص", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedDate == null
                  ? "اختر التاريخ"
                  : "${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}",
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("الوقت", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked =
                await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (picked != null) {
              setState(() => selectedTime = picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedTime == null
                  ? "اختر الوقت"
                  : selectedTime!.format(context),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.teal),
          centerTitle: true,
          title: const Text(
            'إضافة كشف',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildCard(child: _buildTextField("اسم الطبيب", "اكتب هنا...", doctorNameController)),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildTextField("التخصص", "مثلاً: أطفال", specialtyController)),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdownField("طبيعة الفحص", examinationTypes, selectedType, (value) {
                      setState(() => selectedType = value);
                    })),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDatePicker(context)),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildTimePicker(context)),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitExamination,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إضافة', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}