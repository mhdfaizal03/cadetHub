class ExamModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String type; // 'B Certificate', 'C Certificate', 'Internal'
  final String targetYear; // '2nd Year', '3rd Year', 'All'
  final String organizationId;
  final DateTime createdAt;

  ExamModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
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
      'date': date,
      'time': time,
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
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      type: map['type'] ?? '',
      targetYear: map['targetYear'] ?? '',
      organizationId: map['organizationId'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt']) ?? DateTime.now(),
    );
  }
}
