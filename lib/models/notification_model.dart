class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'global', 'organization', 'cadet'
  final String targetYear; // 'All', '1st Year', '2nd Year', '3rd Year'
  final String? targetId; // organizationId or cadetId
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetYear = 'All',
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'targetYear': targetYear,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      targetYear: map['targetYear'] ?? 'All',
      targetId: map['targetId'],
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
