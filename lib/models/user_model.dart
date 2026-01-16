class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'officer' or 'cadet'
  final String roleId; // Officer ID or Cadet ID
  final String organizationId; // Unit/Org Code
  final String year; // '1st Year', '2nd Year', '3rd Year'
  final int status; // 0: Pending, 1: Approved, -1: Rejected

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.roleId,
    required this.organizationId,
    this.year = '1st Year', // Default for now
    required this.status,
  });

  // Factory constructor to create a User from Firestore data
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'cadet',
      roleId: data['role'] == 'officer'
          ? (data['officerId'] ?? '')
          : (data['cadetId'] ?? ''),
      organizationId: data['organizationId'] ?? '',
      year: data['year'] ?? '1st Year',
      status: data['status'] ?? 0,
    );
  }

  // Convert User to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'year': year,
      'status': status,
      'organizationId': organizationId,
      role == 'officer' ? 'officerId' : 'cadetId': roleId,
    };
  }
}
