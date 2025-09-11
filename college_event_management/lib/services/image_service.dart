import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi chọn ảnh từ thư viện: ${e.toString()}');
    }
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi chụp ảnh: ${e.toString()}');
    }
  }

  // Upload image to Firebase Storage
  static Future<String> uploadImage({
    required File imageFile,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Generate unique filename if not provided
      final String finalFileName =
          fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';

      // Create reference
      final Reference ref = _storage.ref().child(folder).child(finalFileName);

      // Upload file
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi upload ảnh: ${e.toString()}');
    }
  }

  // Upload multiple images
  static Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
  }) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i';
        final String url = await uploadImage(
          imageFile: imageFiles[i],
          folder: folder,
          fileName: fileName,
        );
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Lỗi upload nhiều ảnh: ${e.toString()}');
    }
  }

  // Delete image from Firebase Storage
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Lỗi xóa ảnh: ${e.toString()}');
    }
  }

  // Delete multiple images
  static Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      for (String url in imageUrls) {
        await deleteImage(url);
      }
    } catch (e) {
      throw Exception('Lỗi xóa nhiều ảnh: ${e.toString()}');
    }
  }

  // Get image size in MB
  static Future<double> getImageSizeInMB(File imageFile) async {
    try {
      final int bytes = await imageFile.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  // Compress image if needed
  static Future<File> compressImageIfNeeded(
    File imageFile, {
    double maxSizeMB = 5.0,
  }) async {
    try {
      final double sizeInMB = await getImageSizeInMB(imageFile);

      if (sizeInMB <= maxSizeMB) {
        return imageFile;
      }

      // If image is too large, we would need to implement compression
      // For now, just return the original file
      // In a real app, you might want to use packages like flutter_image_compress
      return imageFile;
    } catch (e) {
      return imageFile;
    }
  }

  // Show image picker dialog
  static Future<File?> showImagePickerDialog() async {
    // This would typically be called from a UI context
    // For now, we'll just return null
    // In a real implementation, you'd show a dialog with options
    return null;
  }
}
