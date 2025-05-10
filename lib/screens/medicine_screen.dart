import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> deleteMedication(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا العلاج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('Medications').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف بنجاح')),
      );
    }
  }

  Future<void> editMedication(String docId, Map<String, dynamic> data) async {
    final nameController =
        TextEditingController(text: data['Medicine_name'] ?? '');
    final durationController = TextEditingController(
        text: data['Medication_duration']?.toString() ?? '');
    final freqController =
        TextEditingController(text: data['Dosage_frequency']?.toString() ?? '');
    final timeController = TextEditingController(
        text: data['Dose_times']?.isNotEmpty == true
            ? (data['Dose_times'][0] as Timestamp).toDate().hour.toString()
            : '8');

    String selectedCategory = data['Medication_category'] ?? 'مسكن';
    String selectedMedicineForm = data['Medicine_form'] ?? 'أقراص';
    int dosageFrequency = data['Dosage_frequency'] ?? 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل العلاج'),
            content: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'اسم الدواء'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'مدة العلاج بالأيام'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'تصنيف العلاج'),
                        items: _categories.map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedCategory = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMedicineForm,
                        decoration: const InputDecoration(labelText: 'نوع العلاج'),
                        items: _medicineForms.map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedMedicineForm = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: timeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'ساعة بداية الجرعات (مثال: 8)'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: dosageFrequency,
                        decoration: const InputDecoration(
                            labelText: 'عدد الجرعات يومياً'),
                        items: [1, 2, 3, 4].map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => dosageFrequency = value!);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('حفظ التعديلات')),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      final int durationDays =
          int.tryParse(durationController.text.trim()) ?? 7;
      final int baseHour = int.tryParse(timeController.text.trim()) ?? 8;

      // حساب مواعيد الجرعات الجديدة
      final List<DateTime> doseTimes = [];
      final double interval = 24 / dosageFrequency;

      for (int day = 0; day < durationDays; day++) {
        for (int i = 0; i < dosageFrequency; i++) {
          int hour = (baseHour + (interval * i).round()) % 24;
          final doseTime = DateTime.now()
              .add(Duration(days: day))
              .copyWith(
                  hour: hour,
                  minute: 0,
                  second: 0,
                  millisecond: 0,
                  microsecond: 0);
          doseTimes.add(doseTime);
        }
      }

      await _firestore.collection('Medications').doc(docId).update({
        'Medicine_name': nameController.text.trim(),
        'Medication_category': selectedCategory,
        'Medicine_form': selectedMedicineForm,
        'Dosage_frequency': dosageFrequency,
        'Medication_duration': durationDays,
        'end_date': Timestamp.fromDate(
            DateTime.now().add(Duration(days: durationDays))),
        'Dose_times': doseTimes.map((e) => Timestamp.fromDate(e)).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التعديل بنجاح')),
      );
    }
  }

  List<TimeOfDay> parseDoseTimes(List<dynamic> doseTimesList) {
    List<TimeOfDay> doseTimes = [];
    for (var dose in doseTimesList) {
      if (dose is Timestamp) {
        final doseDate = dose.toDate();
        doseTimes.add(TimeOfDay(hour: doseDate.hour, minute: doseDate.minute));
      }
    }
    return doseTimes;
  }

  String formatDoseTimes(List<dynamic> doseTimesList) {
    final doseTimes = parseDoseTimes(doseTimesList);
    final now = DateTime.now();

    final filteredDoseTimes = doseTimes.where((time) {
      final doseDate =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return doseDate.isAfter(now.subtract(const Duration(days: 1))) &&
          doseDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    List<String> formattedTimes = [];
    List<String> uniqueTimes = [];

    for (var time in filteredDoseTimes) {
      String timeString = DateFormat('HH:mm', 'ar')
          .format(DateTime(0, 0, 0, time.hour, time.minute));
      if (!uniqueTimes.contains(timeString)) {
        uniqueTimes.add(timeString);
        formattedTimes.add(timeString);
      }
    }

    if (formattedTimes.isNotEmpty) {
      return "مواعيد الجرعات اليوم: ${formattedTimes.join('، ')}";
    }

    return "لم يتم تحديد مواعيد اليوم";
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('علاجك',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 1,
          leading: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.teal),
              onPressed: () {}),
        ),
        body: user == null
            ? const Center(child: Text('يجب تسجيل الدخول'))
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('Medications')
                            .where('UserID', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('لا توجد علاجات'));
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              final doseTimesText =
                                  formatDoseTimes(data['Dose_times']);
                              final startDate =
                                  (data['start_date'] as Timestamp?)?.toDate();
                              final endDate =
                                  (data['end_date'] as Timestamp?)?.toDate();

                              return MedicationCard(
                                name: data['Medicine_name'] ?? '',
                                category: data['Medication_category'] ?? '',
                                form: data['Medicine_form'] ?? '',
                                duration: data['Medication_duration']
                                    ?.toString() ??
                                    '',
                                frequency: data['Dosage_frequency']
                                    ?.toString() ??
                                    '',
                                doseTimesText: doseTimesText,
                                startDate: startDate,
                                endDate: endDate,
                                onEdit: () => editMedication(doc.id, data),
                                onDelete: () => deleteMedication(doc.id),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/add_medicine');
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('إضافة علاج',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class MedicationCard extends StatelessWidget {
  final String name;
  final String category;
  final String form;
  final String duration;
  final String frequency;
  final String doseTimesText;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.name,
    required this.category,
    required this.form,
    required this.duration,
    required this.frequency,
    required this.doseTimesText,
    this.startDate,
    this.endDate,
    required this.onEdit,
    required this.onDelete,
  });

  double calculateProgress() {
    if (startDate == null || endDate == null) return 0.0;
    final totalDays = endDate!.difference(startDate!).inDays;
    final passedDays = DateTime.now().difference(startDate!).inDays;
    if (totalDays <= 0) return 1.0;
    return (passedDays / totalDays).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final startDateText = startDate != null
        ? DateFormat("dd MMM yyyy", "ar").format(startDate!)
        : '';
    final endDateText = endDate != null
        ? DateFormat("dd MMM yyyy", "ar").format(endDate!)
        : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // تم استبدال الأيقونة بصورة الدواء
                Image.asset(
                  'assets/pill.png',
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('النوع: $form | التصنيف: $category',
                          style: const TextStyle(color: Colors.grey)),
                      Text('مدة العلاج: $duration يوم'),
                      Text('عدد الجرعات اليومية: $frequency'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: calculateProgress(),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              color: Colors.teal,
            ),
            const SizedBox(height: 6),
            Text('من $startDateText إلى $endDateText',
                style:
                    const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 6),
            Text(doseTimesText, style: const TextStyle(color: Colors.teal)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: Colors.blue)),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red)),
              ],
            )
          ],
        ),
      ),
    );
  }
}