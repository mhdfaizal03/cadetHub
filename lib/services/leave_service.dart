import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/leave_model.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _leaves => _firestore.collection('leaves');

  // Submit Leave Request
  Future<void> requestLeave(LeaveModel leave) async {
    await _leaves.add(leave.toMap());
  }

  // Update Leave Status
  Future<void> updateLeaveStatus(String id, String status) async {
    await _leaves.doc(id).update({'status': status});
  }

  // Get Pending Leaves for Organization
  Stream<QuerySnapshot> getPendingLeaves(String organizationId) {
    return _leaves
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: 'Pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching pending leaves: $e');
          throw e;
        });
  }

  // Get All Leaves for Organization (for history/reports)
  Stream<QuerySnapshot> getAllLeaves(String organizationId) {
    return _leaves
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching all leaves: $e');
          throw e;
        });
  }

  // Get Cadet's Leaves
  Stream<QuerySnapshot> getCadetLeaves(String cadetId) {
    return _leaves
        .where('cadetId', isEqualTo: cadetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching cadet leaves: $e');
          throw e;
        });
  }
}
