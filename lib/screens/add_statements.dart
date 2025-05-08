import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  final List<String> examinationTypes = ['دوري', 'مستعجل','متابعة', 'جديد'];

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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى تسجيل الدخول أولاً")),
      );
      return;
    }

    final DateTime checkupDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    try {
      await FirebaseFirestore.instance.collection('Patient_Records').add({
        'UserID': user.uid,
        'checkup_category': specialtyController.text,
        'checkup_date':
            DateFormat("yMMMMd").add_jm().format(selectedDate!.toLocal()),
        'checkup_time':
            DateFormat("yMMMMd").add_jm().format(checkupDateTime.toLocal()),
        'doctor_name': doctorNameController.text,
        'type_of_examination': selectedType,
        'Created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمت إضافة الكشف بنجاح")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    }
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("تاريخ الفحص",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              selectedDate == null
                  ? "اختر التاريخ"
                  : DateFormat.yMMMMd().format(selectedDate!),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("الوقت",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF3F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('إضافة كشف',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              _buildTextField("اسم الطبيب", "اكتب هنا...", doctorNameController),
              const SizedBox(height: 12),
              _buildTextField("التخصص", "مثلاً: أطفال", specialtyController),
              const SizedBox(height: 12),
              _buildDropdownField("طبيعة الفحص", examinationTypes, selectedType,
                  (value) {
                setState(() => selectedType = value);
              }),
              const SizedBox(height: 12),
              _buildDatePicker(context),
              const SizedBox(height: 12),
              _buildTimePicker(context),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submitExamination,
                  child: const Text("إضافة",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
