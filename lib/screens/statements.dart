import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_statements.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تحويل Timestamp إلى String
  String _formatDate(dynamic dateField) {
    if (dateField is Timestamp) {
      final date = dateField.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return 'تاريخ غير متوفر';
  }

  Future<void> deleteAppointment(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا الكشف؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('Patient_Records').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
      }
    }
  }

  void showEditDialog(String docId, Map<String, dynamic> data) {
    final TextEditingController doctorNameController =
        TextEditingController(text: data['doctor_name']);
    final TextEditingController categoryController =
        TextEditingController(text: data['checkup_category']);
    final TextEditingController typeController =
        TextEditingController(text: data['type_of_examination']);
    
    // تحويل Timestamp إلى String
    final TextEditingController dateController =
        TextEditingController(text: _formatDate(data['checkup_date']));  // تحويل التاريخ
    final TextEditingController timeController =
        TextEditingController(text: data['checkup_time']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الكشف'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: doctorNameController, decoration: const InputDecoration(labelText: 'اسم الدكتور')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'الفئة')),
              TextField(controller: typeController, decoration: const InputDecoration(labelText: 'النوع')),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'التاريخ')),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: 'الوقت')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('Patient_Records').doc(docId).update({
                'doctor_name': doctorNameController.text,
                'checkup_category': categoryController.text,
                'type_of_examination': typeController.text,
                'checkup_date': dateController.text,  // تخزين التاريخ كـ String
                'checkup_time': timeController.text,
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأطباء', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const Icon(Icons.notifications_none, color: Colors.teal),
        ),
        body: user == null
            ? const Center(child: Text('يجب تسجيل الدخول'))
            : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('Patient_Records')
                          .where('UserID', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('لا توجد كشوفات'));
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return DoctorCard(
                              doctorName: data['doctor_name'] ?? '',
                              category: data['checkup_category'] ?? '',
                              type: data['type_of_examination'] ?? '',
                              date: _formatDate(data['checkup_date']),  // تحويل التاريخ هنا
                              time: _formatDate(data['checkup_time']) ?? '',
                              onDelete: () => deleteAppointment(doc.id),
                              onEdit: () => showEditDialog(doc.id, data),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add_statements');
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('إضافة كشف', style: TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String doctorName;
  final String category;
  final String type;
  final String date;
  final String time;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const DoctorCard({
    super.key,
    required this.doctorName,
    required this.category,
    required this.type,
    required this.date,
    required this.time,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/doctor.jpg'),
                  radius: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('د. $doctorName', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('$category | $type', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(date),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(time),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red,
                    ),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete),
                    label: const Text(''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.teal[100],
                      foregroundColor: Colors.teal[800],
                    ),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text(''),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
