// الاستيرادات كما هي...
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String _selectedCategory = 'مسكن';
  String _selectedMedicineForm = 'أقراص';
  bool _isLoading = false;
  int _dosageFrequency = 1;
  final List<DateTime> _doseTimes = [];

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

  Future<void> _addMedicine() async {
    if (_nameController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("لم يتم العثور على المستخدم");

      final int durationDays = int.tryParse(_durationController.text.trim()) ?? 7;

      final Timestamp startDate = Timestamp.now();
      final Timestamp endDate =
          Timestamp.fromDate(DateTime.now().add(Duration(days: durationDays)));

      // توليد مواعيد الجرعات
      _doseTimes.clear();
      final int baseHour = int.tryParse(_timeController.text.trim()) ?? 8;
      final double interval = 24 / _dosageFrequency;

      for (int day = 0; day < durationDays; day++) {
        for (int i = 0; i < _dosageFrequency; i++) {
          int hour = (baseHour + (interval * i).round()) % 24;
          final doseTime = DateTime.now()
              .add(Duration(days: day))
              .copyWith(hour: hour, minute: 0, second: 0, millisecond: 0, microsecond: 0);
          _doseTimes.add(doseTime);
        }
      }

      await FirebaseFirestore.instance.collection('Medications').add({
        'UserID': user.uid,
        'Medicine_name': _nameController.text,
        'Medication_category': _selectedCategory,
        'Medicine_form': _selectedMedicineForm,
        'Dosage_frequency': _dosageFrequency,
        'Medication_duration': durationDays,
        'start_date': startDate,
        'end_date': endDate,
        'Dose_times': _doseTimes.map((e) => Timestamp.fromDate(e)).toList(),
        'Created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة العلاج بنجاح')),
      );

      Navigator.pop(context);
    } catch (e) {
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
                    _buildCard(child: _buildTextField(_nameController, 'اسم الدواء', 'اكتب هنا...')),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildTextField(_durationController, 'مدة العلاج بالأيام', 'مثال: 7', isNumber: true)),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdownCategory()),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdownMedicineForm()),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildTextField(_timeController, 'ساعة بداية الجرعات (مثال: 8)', '8', isNumber: true)),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdownFrequency()),
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
                      : const Text('إضافة', style: TextStyle(fontSize: 16, color: Colors.white)),
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

  Widget _buildTextField(TextEditingController controller, String label, String hint,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تصنيف العلاج', style: TextStyle(fontWeight: FontWeight.bold)),
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
        const Text('عدد الجرعات يومياً', style: TextStyle(fontWeight: FontWeight.bold)),
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
