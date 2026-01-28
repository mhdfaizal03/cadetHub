import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/attendance_model.dart';
import 'package:ncc_cadet/models/notification_model.dart';
import 'package:ncc_cadet/services/notification_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _attendance => _firestore.collection('attendance');

  // Mark/Update Attendance Batch
  Future<void> markBatchAttendance(List<AttendanceModel> records) async {
    final batch = _firestore.batch();

    for (var record in records) {
      if (record.id.isEmpty) {
        // New record
        final docRef = _attendance.doc(); // Auto-ID
        // We need to preserve the ID in the object if we were to return it,
        // but here we just write to Firestore.
        // We must strip 'id' from toMap if it's empty in model, OR the model handles it.
        // My AttendanceModel.toMap includes all fields. Firestore doesn't need 'id' in the body usually.
        // Let's just create a new map or rely on doc ref.
        batch.set(docRef, record.toMap());
      } else {
        // Update existing (though typically we might query first)
        final docRef = _attendance.doc(record.id);
        batch.update(docRef, {'status': record.status});
      }
    }

    await batch.commit();

    // Notify Organization
    if (records.isNotEmpty) {
      final orgId = records.first.organizationId;
      await NotificationService().sendNotification(
        NotificationModel(
          id: '',
          title: 'Attendance Updated',
          message: 'Attendance for the recent parade has been updated.',
          type: 'organization',
          targetId: orgId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // Mark Single Attendance (Upsert logic)
  Future<void> markAttendance(AttendanceModel record) async {
    Query query;
    if (record.type == 'Camp' && record.campId != null) {
      query = _attendance
          .where('campId', isEqualTo: record.campId)
          .where('cadetId', isEqualTo: record.cadetId);
    } else {
      query = _attendance
          .where('paradeId', isEqualTo: record.paradeId)
          .where('cadetId', isEqualTo: record.cadetId);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      await _attendance.doc(snapshot.docs.first.id).update({
        'status': record.status,
      });
    } else {
      await _attendance.add(record.toMap());
    }
  }

  // Get Attendance for a specific Parade
  Stream<QuerySnapshot> getAttendanceForParade(String paradeId) {
    return _attendance
        .where('paradeId', isEqualTo: paradeId)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching attendance for parade $paradeId: $e');
          throw e;
        });
  }

  // Get Attendance for a specific Camp
  Stream<QuerySnapshot> getAttendanceForCamp(String campId) {
    return _attendance
        .where('campId', isEqualTo: campId)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching attendance for camp $campId: $e');
          throw e;
        });
  }

  // Get Attendance Reports (by Cadet)
  Stream<QuerySnapshot> getCadetAttendance(String cadetId) {
    return _attendance
        .where('cadetId', isEqualTo: cadetId)
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching cadet attendance $cadetId: $e');
          throw e;
        });
  }

  // Get All Attendance for Organization (for Officer Dashboard stats)
  Stream<QuerySnapshot> getOrganizationAttendance(String organizationId) {
    return _attendance
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .handleError((e) {
          debugPrint(
            'Error fetching organization attendance $organizationId: $e',
          );
          throw e;
        });
  }
}
