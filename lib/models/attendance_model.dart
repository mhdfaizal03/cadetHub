import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String paradeId;
  final String cadetId;
  final String cadetName;
  final String status; // 'Present', 'Absent', 'Excused'
  final String date; // YYYY-MM-DD
  final String organizationId;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.paradeId,
    required this.cadetId,
    required this.cadetName,
    required this.status,
    required this.date,
    required this.organizationId,
    required this.createdAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      paradeId: data['paradeId'] ?? '',
      cadetId: data['cadetId'] ?? '',
      cadetName: data['cadetName'] ?? '',
      status: data['status'] ?? 'Absent',
      date: data['date'] ?? '',
      organizationId: data['organizationId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paradeId': paradeId,
      'cadetId': cadetId,
      'cadetName': cadetName,
      'status': status,
      'date': date,
      'organizationId': organizationId,
      'createdAt': createdAt,
    };
  }
}
