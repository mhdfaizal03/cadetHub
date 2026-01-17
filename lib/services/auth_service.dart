import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user profile stream (for real-time updates & offline cache)
  Stream<UserModel?> getUserStream() {
    final User? user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots().map((
        doc,
      ) {
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
        return null;
      });
    }
    return Stream.value(null);
  }

  // Get current user profile
  Future<UserModel?> getUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        return getUserData(user.uid);
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null;
  }

  // Get user data by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  // Stream of pending cadets for a specific organization
  Stream<QuerySnapshot> pendingCadets(String organizationId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'cadet')
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: 0) // 0 for pending
        .snapshots();
  }

  // Stream of ALL cadets (approved) for a specific organization
  Stream<QuerySnapshot> getCadetsStream(String organizationId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'cadet')
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: 1) // 1 for approved
        .snapshots();
  }

  // Update cadet status (Approve/Reject)
  Future<void> updateCadetStatus(String uid, int status) async {
    try {
      await _firestore.collection('users').doc(uid).update({'status': status});
    } catch (e) {
      print("Error updating cadet status: $e");
      rethrow;
    }
  }

  // Update generic user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print("Error updating user data: $e");
      rethrow;
    }
  }

  // Current User Getter
  User? get currentUser => _auth.currentUser;

  // Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await NotificationService().saveTokenToDatabase();

      // Subscribe to topics
      final user = await getUserData(_auth.currentUser!.uid);
      if (user != null) {
        await NotificationService().subscribeToTopic(
          'organization_${user.organizationId}',
        );
        if (user.role == 'cadet') {
          await NotificationService().subscribeToTopic(
            'organization_${user.organizationId}_year_${user.year}',
          );
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login failed";
    } catch (e) {
      return "An unexpected error occurred";
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
    required String year,
  }) async {
    try {
      // 0. Organization Logic
      if (role == 'cadet') {
        // CADET: Validate Org Exists
        final orgDoc = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .get();

        if (!orgDoc.exists) {
          return "There is no organization found with this Organization ID";
        }
      } else if (role == 'officer') {
        // OFFICER: Create Organization
        // We use set with merge: true to avoid overwriting if it somehow exists (though logic implies ownership)
        // Or if we want to FAIL if it exists to prevent hijacking?
        // User requested: "officer create organization id when create"
        // Let's create it.
        await _firestore.collection('organizations').doc(organizationId).set({
          'organizationId': organizationId,
          'createdBy': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 0.5 Validate Unique Role ID (Only for Cadets as Officers check Org)
      if (role == 'cadet') {
        final existingUserDocs = await _firestore
            .collection('users')
            .where('cadetId', isEqualTo: roleId)
            .limit(1)
            .get();

        if (existingUserDocs.docs.isNotEmpty) {
          return "This Cadet ID is already in use.";
        }
      }

      // 1. Create User in Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user == null) {
        return "Failed to create user";
      }

      final uid = cred.user!.uid;

      // 2. Create User Model
      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: role,
        roleId: roleId,
        organizationId: organizationId,
        year: year,
        status: 0, // Default to pending
      );

      // 3. Save to Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      await NotificationService().saveTokenToDatabase();

      // Subscribe to topics
      await NotificationService().subscribeToTopic(
        'organization_$organizationId',
      );
      if (role == 'cadet') {
        await NotificationService().subscribeToTopic(
          'organization_${organizationId}_year_$year',
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Registration failed";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  // Delete User (Firestore only for now, as Admin SDK needed for Auth deletion)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }

  // Reset Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to send reset email";
    } catch (e) {
      return "An unexpected error occurred";
    }
  }

  // Register Cadet by Officer (Secondary App to avoid logout)
  Future<String?> registerCadetByOfficer({
    required String name,
    required String email,
    required String password,
    required String cadetId,
    required String organizationId,
    required String year,
    required String rank,
    required int status,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Check if Organization Exists (Should be valid as Officer is logged in)
      // 2. Check if Cadet ID is unique
      final existingUserDocs = await _firestore
          .collection('users')
          .where('cadetId', isEqualTo: cadetId)
          .limit(1)
          .get();

      if (existingUserDocs.docs.isNotEmpty) {
        return "This Cadet ID is already in use.";
      }

      // 3. Create User in Auth using Secondary App
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user == null) {
        return "Failed to create user in Auth";
      }

      final uid = cred.user!.uid;

      // 4. Create User Model and Save to Firestore
      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: 'cadet',
        roleId: cadetId,
        organizationId: organizationId,
        year: year,
        status: status, // Officer sets status (Active/Pending)
        rank: rank,
      );

      // We use the MAIN firestore instance to save the data
      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      await secondaryAuth.signOut();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Registration failed";
    } catch (e) {
      return "An unexpected error occurred: $e";
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
