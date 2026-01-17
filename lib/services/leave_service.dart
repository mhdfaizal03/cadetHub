import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/leave_model.dart';
import 'package:ncc_cadet/models/notification_model.dart';
import 'package:ncc_cadet/services/notification_service.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _leaves => _firestore.collection('leaves');

  // Submit Leave Request
  Future<void> requestLeave(LeaveModel leave) async {
    await _leaves.add(leave.toMap());

    // Notify Officers (Push)
    await NotificationService().sendPushNotification(
      title: 'New Leave Request',
      body: '${leave.cadetName} has requested leave for ${leave.reason}',
      topic: 'organization_${leave.organizationId}_officers',
    );
  }

  // Update Leave Status
  Future<void> updateLeaveStatus(
    String id,
    String status, {
    String? rejectionReason,
  }) async {
    final Map<String, dynamic> data = {'status': status};
    if (rejectionReason != null) {
      data['rejectionReason'] = rejectionReason;
    }

    // update
    await _leaves.doc(id).update(data);

    // Notify Cadet
    try {
      final doc = await _leaves.doc(id).get();
      if (doc.exists) {
        final leaveData = doc.data() as Map<String, dynamic>;
        final cadetId = leaveData['cadetId'];

        await NotificationService().sendNotification(
          NotificationModel(
            id: '',
            title: 'Leave Request $status',
            message:
                'Your leave request has been $status.${status == 'Rejected' && rejectionReason != null ? " Reason: $rejectionReason" : ""}',
            type: 'cadet',
            targetId: cadetId,
            createdAt: DateTime.now(),
          ),
        );

        // Fetch user token for Push logic
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(cadetId)
              .get();
          if (userDoc.exists && userDoc.data()!.containsKey('fcmToken')) {
            final token = userDoc.data()!['fcmToken'];
            await NotificationService().sendPushNotification(
              title: 'Leave Request $status',
              body: 'Your leave request has been $status.',
              token: token,
            );
          }
        } catch (e) {
          debugPrint("Error sending push to cadet: $e");
        }
      }
    } catch (e) {
      // Ignore notification errors
      print("Error sending notification: $e");
    }
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
