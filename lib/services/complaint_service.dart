import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/complaint_model.dart';

class ComplaintService {
  final CollectionReference _db = FirebaseFirestore.instance.collection(
    'complaints',
  );

  // Submit a complaint
  Future<void> submitComplaint(ComplaintModel complaint) async {
    await _db.add(complaint.toMap());
  }

  // Get complaints for a cadet
  Stream<QuerySnapshot> getCadetComplaints(String cadetId) {
    return _db
        .where('cadetId', isEqualTo: cadetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching cadet complaints: $e');
          throw e;
        });
  }

  // Get all complaints for an organization (Officer view)
  Stream<QuerySnapshot> getOrganizationComplaints(String organizationId) {
    return _db
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching organization complaints: $e');
          throw e;
        });
  }

  // Update complaint status (e.g. Resolved, Dismissed)
  Future<void> updateComplaintStatus(String id, String status) async {
    await _db.doc(id).update({'status': status});
  }
}
