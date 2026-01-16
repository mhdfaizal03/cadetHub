class ComplaintModel {
  final String id;
  final String cadetId;
  final String cadetName;
  final String title;
  final String description;
  final String status; // 'Pending', 'Resolved', 'Dismissed'
  final String organizationId;
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.cadetId,
    required this.cadetName,
    required this.title,
    required this.description,
    required this.status,
    required this.organizationId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'cadetId': cadetId,
      'cadetName': cadetName,
      'title': title,
      'description': description,
      'status': status,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      cadetId: map['cadetId'] ?? '',
      cadetName: map['cadetName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      organizationId: map['organizationId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
