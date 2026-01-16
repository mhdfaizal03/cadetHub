import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/notification_model.dart';

class NotificationService {
  final CollectionReference _db = FirebaseFirestore.instance.collection(
    'notifications',
  );

  // Send a notification
  Future<void> sendNotification(NotificationModel notification) async {
    await _db.add(notification.toMap());
  }

  // Get notifications for a cadet (Organization broadcast + Personal)
  Stream<QuerySnapshot> getNotifications(
    String organizationId,
    String cadetId,
  ) {
    return _db
        .where(
          Filter.or(
            Filter.and(
              Filter('type', isEqualTo: 'organization'),
              Filter('targetId', isEqualTo: organizationId),
            ),
            Filter.and(
              Filter('type', isEqualTo: 'cadet'),
              Filter('targetId', isEqualTo: cadetId),
            ),
          ),
        )
        // Note: Ordering by createdAt with OR queries typically requires composite index.
        // If query fails, we might need to sort client-side or modify query.
        // For now, let's try basic query or just organization notifications first if complex index is needed.
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching notifications: $e');
          throw e;
        });
  }
}
