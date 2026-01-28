import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class DocumentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload a document
  Future<String?> uploadDocument({
    required PlatformFile file,
    required String userId,
    required String docType, // 'SSLC', 'Aadhar', 'BankPassbook', 'Other'
    required String userName,
    required String organizationId,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$userId/$fileName';

      // 1. Upload to Supabase Storage
      if (file.bytes != null) {
        // Web or when bytes are available
        await _supabase.storage
            .from('documents')
            .uploadBinary(
              path,
              file.bytes!,
              fileOptions: const FileOptions(upsert: false),
            );
      } else {
        // Mobile
        await _supabase.storage
            .from('documents')
            .upload(
              path,
              File(file.path!),
              fileOptions: const FileOptions(upsert: false),
            );
      }

      final downloadUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(path);

      // 2. Save Metadata to Supabase Database
      await _supabase.from('documents').insert({
        'userId': userId,
        'userName': userName,
        'organizationId': organizationId,
        'docType': docType,
        'fileName': file.name,
        'fileUrl': downloadUrl,
        'status': 'Pending', // Pending, Approved, Rejected
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Get documents for a specific user
  Stream<List<Map<String, dynamic>>> getUserDocuments(String userId) {
    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('userId', userId)
        .order('created_at', ascending: false);
  }

  // Delete a document
  Future<void> deleteDocument(String docId, String fileUrl) async {
    try {
      // 1. Delete from Supabase Database
      await _supabase.from('documents').delete().eq('id', docId);

      // 2. Delete from Supabase Storage
      // Extract path from URL. Assuming standard Supabase Storage URL format.
      // Url format: .../storage/v1/object/public/bucket/folder/file
      // We need 'folder/file'.
      // A better way is to store the storage path in the DB, but parsing works for now if standard.
      try {
        final uri = Uri.parse(fileUrl);
        final segments = uri.pathSegments;
        final storageIndex = segments.indexOf('documents'); // bucket name
        if (storageIndex != -1 && storageIndex + 1 < segments.length) {
          final path = segments.sublist(storageIndex + 1).join('/');
          await _supabase.storage.from('documents').remove([path]);
        }
      } catch (e) {
        debugPrint("Error deleting from storage: $e");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update Status (Officer)
  Future<void> updateDocumentStatus(String docId, String status) async {
    await _supabase
        .from('documents')
        .update({'status': status})
        .eq('id', docId);
  }

  // Update Document (Cadet) - Replaces file and updates metadata
  Future<String?> updateDocument({
    required String docId,
    required PlatformFile file,
    required String userId,
    required String oldFileUrl,
  }) async {
    try {
      // 1. Upload new file
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$userId/$fileName';

      if (file.bytes != null) {
        await _supabase.storage
            .from('documents')
            .uploadBinary(
              path,
              file.bytes!,
              fileOptions: const FileOptions(upsert: false),
            );
      } else {
        await _supabase.storage
            .from('documents')
            .upload(
              path,
              File(file.path!),
              fileOptions: const FileOptions(upsert: false),
            );
      }

      final newDownloadUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(path);

      // 2. Update Database Record
      await _supabase
          .from('documents')
          .update({
            'fileName': file.name,
            'fileUrl': newDownloadUrl,
            'status': 'Pending', // Reset status on update
            // 'created_at': DateTime.now().toIso8601String(), // Optional: Update timestamp
          })
          .eq('id', docId);

      // 3. Delete old file from storage (Cleanup)
      try {
        final uri = Uri.parse(oldFileUrl);
        final segments = uri.pathSegments;
        final storageIndex = segments.indexOf('documents');
        if (storageIndex != -1 && storageIndex + 1 < segments.length) {
          final oldPath = segments.sublist(storageIndex + 1).join('/');
          await _supabase.storage.from('documents').remove([oldPath]);
        }
      } catch (e) {
        debugPrint("Error deleting old file: $e");
        // Proceed even if old file deletion fails
      }

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Get Download URL (Forces Download via Query Param)
  Future<String?> getDownloadUrl(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final filename = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'document';

      // Append 'download' query parameter to force download
      // We merge with existing query params (though public URLs usually have none)
      final newUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'download': filename},
      );

      return newUri.toString();
    } catch (e) {
      debugPrint("Error generating download URL: $e");
      return fileUrl; // Fallback to original
    }
  }
}
