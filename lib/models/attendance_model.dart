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
  final String? campId;
  final String type; // 'Parade' or 'Camp'

  AttendanceModel({
    required this.id,
    this.paradeId = '', // Make optional if type is Camp
    this.campId,
    required this.cadetId,
    required this.cadetName,
    required this.status,
    required this.date,
    required this.organizationId,
    required this.createdAt,
    this.type = 'Parade',
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      paradeId: data['paradeId'] ?? '',
      campId: data['campId'],
      cadetId: data['cadetId'] ?? '',
      cadetName: data['cadetName'] ?? '',
      status: data['status'] ?? 'Absent',
      date: data['date'] ?? '',
      organizationId: data['organizationId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'Parade',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paradeId': paradeId,
      'campId': campId,
      'cadetId': cadetId,
      'cadetName': cadetName,
      'status': status,
      'date': date,
      'organizationId': organizationId,
      'createdAt': createdAt,
      'type': type,
    };
  }
}
