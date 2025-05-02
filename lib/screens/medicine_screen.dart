import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MedicationPage extends StatelessWidget {
  const MedicationPage({super.key});

  Future<List<Map<String, dynamic>>> fetchMedicationsWithAdherence() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final medsSnapshot = await FirebaseFirestore.instance
        .collection('Medications')
        .where('UserID', isEqualTo: '/users/$userId')
        .get();

    List<Map<String, dynamic>> result = [];

    for (var medDoc in medsSnapshot.docs) {
      final medData = medDoc.data();
      final medId = medDoc.reference.path;

      final adherenceSnapshot = await FirebaseFirestore.instance
          .collection('Medicine_Adherence')
          .where('medication_id', isEqualTo: '/$medId')
          .where('user_ID', isEqualTo: '/users/$userId')
          .get();

      int totalTaken = adherenceSnapshot.docs.where((doc) => doc['status'] == true).length;
      int dosagePerDay = medData['Dosage_frequency'] ?? 1;
      DateTime endDate = (medData['Medication_duration'] as Timestamp).toDate();
      int days = endDate.difference(DateTime.now()).inDays;
      days = days > 0 ? days : 1;

      int totalExpected = dosagePerDay * days;
      double adherencePercent = (totalExpected > 0)
          ? (totalTaken / totalExpected * 100).clamp(0, 100)
          : 0;

      result.add({
        'name': medData['Medicine_name'],
        'type': medData['Medication_type'],
        'count': medData['Pill_count'],
        'image': medData['Medicine_image'],
        'duration': endDate,
        'dosage': dosagePerDay,
        'adherence': adherencePercent,
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.teal),
            onPressed: () {},
          ),
          title: const Text(
            'علاجك',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FutureBuilder(
            future: fetchMedicationsWithAdherence(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final meds = snapshot.data as List<Map<String, dynamic>>;
              if (meds.isEmpty) {
                return const Center(child: Text('لا توجد بيانات علاج.'));
              }

              return ListView.builder(
                itemCount: meds.length,
                itemBuilder: (context, index) {
                  final med = meds[index];
                  return MedicationCard(
                    name: med['name'],
                    imageUrl: med['image'],
                    dosage: med['dosage'],
                    duration: med['duration'],
                    count: med['count'],
                    adherence: med['adherence'],
                  );
                },
              );
            },
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/add_medicine');
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'إضافة علاج',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MedicationCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final int dosage;
  final DateTime duration;
  final int count;
  final double adherence;

  const MedicationCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.dosage,
    required this.duration,
    required this.count,
    required this.adherence,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Image.network(
                    imageUrl,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('الجرعة : $dosage مرات / يومياً'),
                      Text('مدة العلاج : ${duration.toLocal().toString().split(' ')[0]}'),
                      Text('عدد الأقراص : $count قرص'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * (adherence / 100),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('٪${adherence.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
