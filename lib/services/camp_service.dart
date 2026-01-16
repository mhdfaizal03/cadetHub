import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/models/notification_model.dart';
import 'package:ncc_cadet/services/notification_service.dart';

class CampService {
  final CollectionReference _db = FirebaseFirestore.instance.collection(
    'camps',
  );

  // Create a new camp (Officer only - typically)
  Future<void> createCamp(CampModel camp) async {
    await _db.add(camp.toMap());

    await NotificationService().sendNotification(
      NotificationModel(
        id: '',
        title: 'New Camp Announced',
        message: 'New camp: ${camp.name} starting on ${camp.startDate}.',
        type: 'organization',
        targetId: camp.organizationId,
        createdAt: DateTime.now(),
      ),
    );
  }

  // Get all camps for an organization
  Stream<QuerySnapshot> getCamps(String organizationId) {
    return _db
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('startDate', descending: false)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching camps: $e');
          throw e;
        });
  }

  // Update an existing camp
  Future<void> updateCamp(CampModel camp) async {
    await _db.doc(camp.id).update(camp.toMap());
  }

  // Delete a camp
  Future<void> deleteCamp(String id) async {
    await _db.doc(id).delete();
  }
}
