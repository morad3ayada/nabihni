import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _pillCountController = TextEditingController();

  String _selectedDuration = 'دائم';
  File? _selectedImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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
          centerTitle: true, // وسط العنوان
          title: const Text(
            'إضافة علاج',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold, // تخين
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
                        _nameController,
                        'اسم الدواء',
                        'اكتب هنا...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: _buildTextField(
                        _doseController,
                        'الجرعة يومياً',
                        '2',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildDropdown()),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: _buildTextField(
                        _pillCountController,
                        'عدد الأقراص',
                        '12',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildImagePicker()),
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
                  onPressed: () {},
                  child: const Text(
                    'إضافة',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // لبدء من اليمين
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textAlign: TextAlign.right, // النص داخل الـ TextField يبدأ من اليمين
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: TextDirection.rtl,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // محاذاة يمين
      children: [
        const Text('مدة العلاج', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedDuration,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            alignment: Alignment.centerRight,
            style: const TextStyle(color: Colors.black),
            items:
                ['دائم', 'أسبوع', 'شهر'].map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    alignment: Alignment.centerRight,
                    child: Text(value, textAlign: TextAlign.right),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDuration = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            _selectedImage == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload, size: 40, color: Colors.teal),
                    SizedBox(height: 8),
                    Text('اختر الملف', style: TextStyle(color: Colors.teal)),
                    SizedBox(height: 4),
                    Text(
                      'أقصى حجم للصورة 5 ميغابايت',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
      ),
    );
  }
}
