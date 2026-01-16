import 'package:cloud_firestore/cloud_firestore.dart';

class ParadeModel {
  final String id;
  final String name;
  final String date; // YYYY-MM-DD
  final String time;
  final String location;
  final String description;
  final String targetYear; // 'All', '1st Year', '2nd Year', '3rd Year'
  final String organizationId;
  final DateTime createdAt;

  ParadeModel({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    this.targetYear = 'All',
    required this.organizationId,
    required this.createdAt,
  });

  factory ParadeModel.fromMap(Map<String, dynamic> data, String id) {
    return ParadeModel(
      id: id,
      name: data['name'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      targetYear: data['targetYear'] ?? 'All',
      organizationId: data['organizationId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date,
      'time': time,
      'location': location,
      'description': description,
      'targetYear': targetYear,
      'organizationId': organizationId,
      'createdAt': createdAt,
    };
  }
}
