class CampModel {
  final String id;
  final String name;
  final String location;
  final String startDate;
  final String endDate;
  final String description;
  final String organizationId;
  final DateTime createdAt;

  CampModel({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.organizationId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CampModel.fromMap(Map<String, dynamic> map, String id) {
    return CampModel(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      description: map['description'] ?? '',
      organizationId: map['organizationId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
