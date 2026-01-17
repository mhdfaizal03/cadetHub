import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/services/notification_service.dart';

class ExamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Create Exam
  Future<void> createExam(ExamModel exam) async {
    try {
      // 1. Save to Firestore
      await _db.collection('exams').doc(exam.id).set(exam.toMap());

      // 2. Send Notification
      // Topic format: organization_{orgId}_year_{year}
      // Example: organization_NCC123_year_2nd Year
      String topic;
      if (exam.targetYear == 'All') {
        topic = 'organization_${exam.organizationId}';
      } else {
        topic = 'organization_${exam.organizationId}_year_${exam.targetYear}';
      }

      await _notificationService.sendPushNotification(
        topic: topic,
        title: "New Exam Scheduled: ${exam.title}",
        body: "Date: ${exam.date} | Time: ${exam.time}. Tap to view details.",
      );

      debugPrint("Exam created and notification sent to topic: $topic");
    } catch (e) {
      debugPrint("Error creating exam: $e");
      rethrow;
    }
  }

  // Get Exams (Stream) - For Cadets & Officers
  Stream<QuerySnapshot> getExamsStream(String organizationId, {String? year}) {
    Query query = _db
        .collection('exams')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true);

    if (year != null && year != 'All') {
      // Filter by year if specific year is provided (For Cadets)
      // Note: This requires an index if combining multiple fields in order/where.
      // But we can filter client side or handle 'All' logic.
      // A cadet should see exams for their year AND 'All'
      // Ideally we query exams where targetYear IN [year, 'All']
      query = query.where('targetYear', whereIn: [year, 'All']);
    }

    return query.snapshots();
  }

  // Get Exams for Officer (All exams in Org)
  Stream<QuerySnapshot> getOfficerExams(String organizationId) {
    return _db
        .collection('exams')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete Exam
  Future<void> deleteExam(String examId) async {
    try {
      await _db.collection('exams').doc(examId).delete();
    } catch (e) {
      debugPrint("Error deleting exam: $e");
      rethrow;
    }
  }
}
