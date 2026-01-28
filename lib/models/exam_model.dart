class ExamModel {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String place;
  final String type; // 'B Certificate', 'C Certificate', 'Internal'
  final String targetYear; // '2nd Year', '3rd Year', 'All'
  final String organizationId;
  final DateTime createdAt;

  ExamModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.place,
    required this.type,
    required this.targetYear,
    required this.organizationId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'startTime': startTime,
      'endTime': endTime,
      'place': place,
      'type': type,
      'targetYear': targetYear,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: map['startDate'] ?? map['date'] ?? '', // Fallback for old data
      endDate: map['endDate'] ?? map['date'] ?? '', // Fallback for old data
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      place: map['place'] ?? '',
      type: map['type'] ?? '',
      targetYear: map['targetYear'] ?? '',
      organizationId: map['organizationId'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt']) ?? DateTime.now(),
    );
  }
}
