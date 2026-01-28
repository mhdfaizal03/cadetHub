import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProfileImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Optimize size
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint("Error picking image: $e");
      return null;
    }
  }

  /// Uploads the image to Supabase Storage and returns the public URL
  /// [userId] is used to organize files
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${userId}_${const Uuid().v4()}.$fileExt';
      final filePath =
          'profiles/$fileName'; // Changed to 'profiles' folder inside bucket

      // Assuming 'avatars' is the bucket name.
      // If it doesn't exist, this will throw an error.
      // Commonly used buckets are 'avatars' or 'images'.
      const bucketName = 'avatars';

      await _supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get Public URL
      final String publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading image to Supabase: $e");
      // Throwing error so UI can show it if needed, or returning null
      debugPrint(
        "Hint: Ensure the bucket 'avatars' exists and has public policies.",
      );
      return null;
    }
  }
}
