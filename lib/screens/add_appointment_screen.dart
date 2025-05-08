import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController pillsController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();

  DateTime? selectedStartDate;
  TimeOfDay? selectedTime;

  final String userId = "/users/NDE3kwLTd6MRN2HLvUD1HnwdLYI2";

  Future<void> _submitMedicine() async {
    if (nameController.text.isEmpty ||
        typeController.text.isEmpty ||
        pillsController.text.isEmpty ||
        selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء جميع الحقول المطلوبة")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('Medicines').add({
        'UserID': userId,
        'name': nameController.text,
        'type': typeController.text,
        'pills_count': pillsController.text,
        'instructions': instructionsController.text,
        'start_date': DateFormat("yMMMMd").format(selectedStartDate!),
        'time': selectedTime != null ? selectedTime!.format(context) : '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمت إضافة العلاج بنجاح")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    }
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("تاريخ البدء", style: TextStyle(fontWeight: FontWeight.bold)),
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
              setState(() => selectedStartDate = picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              selectedStartDate == null
                  ? "اختر التاريخ"
                  : DateFormat.yMMMMd().format(selectedStartDate!),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("وقت الاستخدام (اختياري)",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() => selectedTime = picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
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
        title: const Text('إضافة علاج',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildTextField("اسم العلاج", "مثلاً: بنادول", nameController),
              const SizedBox(height: 12),
              _buildTextField("نوع العلاج", "شراب / حبوب / مرهم", typeController),
              const SizedBox(height: 12),
              _buildTextField("الكمية / عدد الحبوب", "مثلاً: 10", pillsController),
              const SizedBox(height: 12),
              _buildTextField("تعليمات الاستخدام", "مثلاً: كل 8 ساعات", instructionsController, maxLines: 3),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 12),
              _buildTimePicker(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submitMedicine,
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
