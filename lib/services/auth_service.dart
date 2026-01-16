import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/user_model.dart';
// ... (rest of imports or class def)

// ... inside class

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Fetch User Profile
  Future<UserModel?> getUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
    } catch (e) {
      // print("Error fetching user profile: $e");
      return null;
    }
  }

  // Register
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String roleId,
    required String organizationId,
    String year = '1st Year',
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return "Registration failed";

      UserModel newUser = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        role: role,
        roleId: roleId,
        organizationId: organizationId,
        year: year,
        status: role == 'officer'
            ? 1
            : 0, // Officers auto-approved for now, Cadets pending
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get Pending Cadets Stream (Filtered by Organization)
  Stream<QuerySnapshot> pendingCadets(String organizationId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'cadet')
        .where('status', isEqualTo: 0)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .handleError((error) {
          debugPrint('Error in pendingCadets: $error');
          throw error;
        });
  }

  // Update Cadet Status (Approve: 1, Reject: -1)
  Future<void> updateCadetStatus(String uid, int status) async {
    try {
      await _firestore.collection('users').doc(uid).update({'status': status});
    } catch (e) {
      debugPrint("Error updating cadet status: $e");
    }
  }

  // Get All Cadets Stream (Filtered by Organization)
  Stream<QuerySnapshot> getCadetsStream(String organizationId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'cadet')
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .handleError((error) {
          debugPrint('Error in getCadetsStream: $error');
          throw error;
        });
  }

  // Update User Data (for editing cadets)
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Delete User (Note: This only deletes Firestore doc, not Auth user if using client SDK)
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
