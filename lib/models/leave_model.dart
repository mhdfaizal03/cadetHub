import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String id;
  final String cadetId;
  final String cadetName;
  final String reason;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String organizationId;
  final DateTime createdAt;
  final String cadetYear; // e.g. "1st Year"
  final String? rejectionReason;

  LeaveModel({
    required this.id,
    required this.cadetId,
    required this.cadetName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.organizationId,
    required this.createdAt,
    required this.cadetYear,
    this.rejectionReason,
  });

  factory LeaveModel.fromMap(Map<String, dynamic> data, String id) {
    return LeaveModel(
      id: id,
      cadetId: data['cadetId'] ?? '',
      cadetName: data['cadetName'] ?? '',
      reason: data['reason'] ?? '',
      startDate: data['startDate'] ?? '',
      endDate: data['endDate'] ?? '',
      status: data['status'] ?? 'Pending',
      organizationId: data['organizationId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cadetYear: data['cadetYear'] ?? 'Unknown',
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cadetId': cadetId,
      'cadetName': cadetName,
      'reason': reason,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'organizationId': organizationId,
      'createdAt': createdAt,
      'cadetYear': cadetYear,
      'rejectionReason': rejectionReason,
    };
  }
}
