import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  String _selectedCategory = 'مسكن';
  String _selectedMedicineForm = 'أقراص';
  bool _isLoading = false;
  int _dosageFrequency = 1;
  bool _isChronic = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  final List<String> _categories = [
    'مسكن',
    'مضاد حيوي',
    'فيتامين',
    'دواء مزمن',
    'مضاد التهاب',
    'مضاد اكتئاب',
    'مهدئ',
    'دواء للضغط',
    'دواء للسكر',
    'أخرى'
  ];

  final List<String> _medicineForms = [
    'أقراص',
    'شراب',
    'حقن',
    'مرهم',
    'كبسولات',
    'قطرات',
    'بخاخ',
    'تحاميل',
    'جل',
    'أخرى'
  ];

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _timeController.text = '8:00';
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medicine_channel_id',
      'مواعيد الأدوية',
      description: 'إشعارات تذكير بمواعيد الأدوية',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _scheduleFirebaseNotifications(
      String medicineName, List<DateTime> doseTimes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final notificationsRef =
          FirebaseFirestore.instance.collection('scheduled_notifications');

      for (final doseTime in doseTimes) {
        if (doseTime.isAfter(DateTime.now())) {
          // إشعار قبل 15 دقيقة
          final reminderTime = doseTime.subtract(const Duration(minutes: 15));
          final reminderDoc = notificationsRef.doc();

          batch.set(reminderDoc, {
            'userId': user.uid,
            'medicineName': medicineName,
            'notificationType': 'reminder',
            'scheduledTime': Timestamp.fromDate(reminderTime),
            'title': 'تذكير بموعد الدواء',
            'body': 'ستتناول جرعة $medicineName بعد 15 دقيقة',
            'createdAt': FieldValue.serverTimestamp(),
            'delivered': false,
          });

          // إشعار الموعد نفسه
          final mainDoc = notificationsRef.doc();
          batch.set(mainDoc, {
            'userId': user.uid,
            'medicineName': medicineName,
            'notificationType': 'main',
            'scheduledTime': Timestamp.fromDate(doseTime),
            'title': 'موعد جرعة الدواء',
            'body': 'حان وقت تناول جرعة $medicineName الآن',
            'createdAt': FieldValue.serverTimestamp(),
            'delivered': false,
          });
        }
      }

      await batch.commit();
      debugPrint('تم جدولة ${doseTimes.length * 2} إشعار في Firebase');
    } catch (e) {
      debugPrint('!!! فشل جدولة إشعارات Firebase: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _showConfirmationNotification(String medicineName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medicine_channel_id',
      'مواعيد الأدوية',
      channelDescription: 'إشعارات تذكير بمواعيد الأدوية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'تمت إضافة العلاج بنجاح',
      'تم جدولة إشعارات لـ $medicineName',
      platformChannelSpecifics,
    );
  }

  Future<void> _addMedicine() async {
    if (_nameController.text.isEmpty ||
        (!_isChronic && _durationController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("لم يتم العثور على المستخدم");

      final int durationDays =
          _isChronic ? 365 : int.tryParse(_durationController.text.trim()) ?? 7;

      final Timestamp startDate = Timestamp.now();
      final Timestamp endDate =
          Timestamp.fromDate(DateTime.now().add(Duration(days: durationDays)));

      // توليد مواعيد الجرعات
      final List<DateTime> doseTimes = [];
      final double interval = 24 / _dosageFrequency;
      final now = DateTime.now();

      for (int day = 0; day < durationDays; day++) {
        for (int i = 0; i < _dosageFrequency; i++) {
          final hour = (_selectedTime.hour + (interval * i).round()) % 24;
          final minute = _selectedTime.minute;

          final doseTime = DateTime(
            now.year,
            now.month,
            now.day + day,
            hour,
            minute,
          );

          doseTimes.add(doseTime);
        }
      }

      // تسجيل الدواء في Firestore
      final medRef = await FirebaseFirestore.instance
          .collection('Medications')
          .add({
        'UserID': user.uid,
        'Medicine_name': _nameController.text,
        'Medication_category': _selectedCategory,
        'Medicine_form': _selectedMedicineForm,
        'Dosage_frequency': _dosageFrequency,
        'Medication_duration': durationDays,
        'start_date': startDate,
        'end_date': endDate,
        'Dose_times': doseTimes.map((e) => Timestamp.fromDate(e)).toList(),
        'is_chronic': _isChronic,
        'Created_at': FieldValue.serverTimestamp(),
        'notification_scheduled': true,
      });

      // جدولة الإشعارات
      await _scheduleFirebaseNotifications(_nameController.text, doseTimes);

      // إظهار إشعار تأكيد محلي
      await _showConfirmationNotification(_nameController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة العلاج وجدولة الإشعارات بنجاح')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error adding medicine: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
            'إضافة علاج',
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
                    _buildCard(
                        child: _buildTextField(
                            _nameController, 'اسم الدواء', 'اكتب هنا...')),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('مدة العلاج',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _isChronic
                                    ? const Text('مزمن (سنة واحدة)',
                                        style: TextStyle(color: Colors.grey))
                                    : _buildTextField(_durationController, '',
                                        'عدد الأيام', isNumber: true),
                              ),
                              Checkbox(
                                value: _isChronic,
                                onChanged: (value) {
                                  setState(() {
                                    _isChronic = value!;
                                    if (_isChronic) {
                                      _durationController.clear();
                                    }
                                  });
                                },
                              ),
                              const Text('مزمن'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdownCategory()),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdownMedicineForm()),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وقت الجرعة الأولى',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: IgnorePointer(
                              child: TextField(
                                controller: _timeController,
                                decoration: InputDecoration(
                                  hintText: 'اختر الوقت',
                                  suffixIcon: const Icon(Icons.access_time),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdownFrequency()),
                    const SizedBox(height: 12),
                  
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
                  onPressed: _isLoading ? null : _addMedicine,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إضافة',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (label.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تصنيف العلاج',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedCategory,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            alignment: Alignment.centerRight,
            items: _categories.map((value) {
              return DropdownMenuItem<String>(
                value: value,
                alignment: Alignment.centerRight,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownMedicineForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('نوع العلاج', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedMedicineForm,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            alignment: Alignment.centerRight,
            items: _medicineForms.map((value) {
              return DropdownMenuItem<String>(
                value: value,
                alignment: Alignment.centerRight,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedMedicineForm = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('عدد الجرعات يومياً',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: _dosageFrequency,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            alignment: Alignment.centerRight,
            items: [1, 2, 3, 4].map((value) {
              return DropdownMenuItem<int>(
                value: value,
                alignment: Alignment.centerRight,
                child: Text('$value'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _dosageFrequency = value!),
          ),
        ),
      ],
    );
  }
}