import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ncc_cadet/models/parade_model.dart';

class ParadeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference get _parades => _firestore.collection('parades');

  // Add Parade
  Future<void> addParade(ParadeModel parade) async {
    await _parades.add(parade.toMap());
  }

  // Update Parade
  Future<void> updateParade(String id, Map<String, dynamic> data) async {
    await _parades.doc(id).update(data);
  }

  // Delete Parade
  Future<void> deleteParade(String id) async {
    await _parades.doc(id).delete();
  }

  // Get Parades Stream (Filtered by Organization)
  Stream<QuerySnapshot> getParadesStream(String organizationId) {
    return _parades
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('date', descending: false) // Upcoming first
        .snapshots();
  }

  // Get Recent Parades (for dashboard limit presumably, or just general list)
  Stream<QuerySnapshot> getUpcomingParades(String organizationId) {
    final String today = DateTime.now().toIso8601String().split('T')[0];

    return _parades
        .where('organizationId', isEqualTo: organizationId)
        .where('date', isGreaterThanOrEqualTo: today)
        .orderBy('date')
        .snapshots();
  }
}
