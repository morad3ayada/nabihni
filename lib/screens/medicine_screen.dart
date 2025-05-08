import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({Key? key}) : super(key: key);

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteMedication(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا العلاج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
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
    final nameController = TextEditingController(text: data['Medicine_name'] ?? '');
    final typeController = TextEditingController(text: data['Medication_type'] ?? '');
    final durationController = TextEditingController(text: data['Medication_duration'] ?? '');
    final freqController = TextEditingController(
  text: data['Dosage_frequency']?.toString() ?? '',
);
    final countController = TextEditingController(
      text: data['Pill_count'] != null ? data['Pill_count'].toString() : '',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل العلاج'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العلاج')),
              TextField(controller: typeController, decoration: const InputDecoration(labelText: 'النوع')),
              TextField(controller: durationController, decoration: const InputDecoration(labelText: 'المدة')),
              TextField(controller: freqController, decoration: const InputDecoration(labelText: 'عدد الجرعات')),
              TextField(controller: countController, decoration: const InputDecoration(labelText: 'عدد الحبات'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تعديل')),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('Medications').doc(docId).update({
        'Medicine_name': nameController.text.trim(),
        'Medication_type': typeController.text.trim(),
        'Medication_duration': durationController.text.trim(),
        'Dosage_frequency': freqController.text.trim(),
        'Pill_count': int.tryParse(countController.text.trim()) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التعديل بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('علاجك', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.teal),
            onPressed: () {},
          ),
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
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('لا توجد علاجات'));
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              return MedicationCard(
                                name: data['Medicine_name'] ?? '',
                                type: data['Medication_type'] ?? '',
                                duration: data['Medication_duration'] ?? '',
                                frequency: '${data['Dosage_frequency'] ?? ''}',
                                count: data['Pill_count']?.toString() ?? '',
                                imageUrl: data['ImageURL'],
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/add_medicine');
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('إضافة علاج', style: TextStyle(fontSize: 20, color: Colors.white)),
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
  final String type;
  final String duration;
  final String frequency;
  final String count;
  final String? imageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.name,
    required this.type,
    required this.duration,
    required this.frequency,
    required this.count,
    this.imageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(imageUrl!, height: 60, width: 60, fit: BoxFit.cover)
                      : Image.asset('assets/pill.png', height: 60, width: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('النوع: $type'),
                      Text('المدة: $duration'),
                      Text('عدد الجرعات: $frequency'),
                      Text('عدد الحبات: $count'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check),
                  label: const Text('تم أخذ العلاج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade100,
                    foregroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                Row(
                  children: [
                    IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Colors.teal)),
                    IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
