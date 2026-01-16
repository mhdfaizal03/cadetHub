import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class DocumentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a document
  Future<String?> uploadDocument({
    required PlatformFile file,
    required String userId,
    required String docType, // 'SSLC', 'Aadhar', 'BankPassbook', 'Other'
    required String userName,
    required String organizationId,
  }) async {
    try {
      // 1. Upload to Storage
      final ref = _storage.ref().child(
        'documents/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );

      UploadTask uploadTask;
      if (file.bytes != null) {
        // Web or when bytes are available
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile
        uploadTask = ref.putFile(File(file.path!));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Save Metadata to Firestore
      await _db.collection('documents').add({
        'userId': userId,
        'userName': userName,
        'organizationId': organizationId,
        'docType': docType,
        'fileName': file.name,
        'fileUrl': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'Pending', // Pending, Approved, Rejected
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Get documents for a specific user
  Stream<QuerySnapshot> getUserDocuments(String userId) {
    return _db
        .collection('documents')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Delete a document
  Future<void> deleteDocument(String docId, String fileUrl) async {
    try {
      // 1. Delete from Firestore
      await _db.collection('documents').doc(docId).delete();

      // 2. Delete from Storage (Optional, but good practice)
      // Extract path from URL is tricky, normally we store storagePath.
      // For now, let's just delete the record. Secure storage usually handles orphaned files or we can store ref path.
      try {
        final ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      } catch (e) {
        // Minimize error if file not found or already deleted
        print("Error deleting from storage: $e");
      }
    } catch (e) {
      throw e;
    }
  }

  // Update Status (Officer)
  Future<void> updateDocumentStatus(String docId, String status) async {
    await _db.collection('documents').doc(docId).update({'status': status});
  }
}
