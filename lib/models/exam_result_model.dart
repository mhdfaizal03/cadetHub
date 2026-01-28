class ExamResultModel {
  final String id;
  final String examId;
  final String cadetId;
  final String cadetName;
  final String status; // 'Pass', 'Fail', 'Absent'
  final double? marks; // Optional
  final String remarks;
  final DateTime createdAt;

  ExamResultModel({
    required this.id,
    required this.examId,
    required this.cadetId,
    required this.cadetName,
    required this.status,
    this.marks,
    required this.remarks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'cadetId': cadetId,
      'cadetName': cadetName,
      'status': status,
      'marks': marks,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamResultModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamResultModel(
      id: id,
      examId: map['examId'] ?? '',
      cadetId: map['cadetId'] ?? '',
      cadetName: map['cadetName'] ?? '',
      status: map['status'] ?? 'Absent',
      marks: map['marks'] != null ? (map['marks'] as num).toDouble() : null,
      remarks: map['remarks'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
