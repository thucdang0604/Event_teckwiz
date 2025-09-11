import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../constants/cloudinary_config.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool get _useCloudinary => true;

  Future<String> uploadImage(File imageFile) async {
    try {
      if (_useCloudinary) {
        return await _uploadToCloudinary(imageFile, resourceType: 'image');
      }
      final String fileName =
          'images/${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final Reference ref = _storage.ref().child(fileName);

      try {
        // Use byte upload primarily
        final Uint8List bytes = await imageFile.readAsBytes();
        final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=604800',
        );
        final TaskSnapshot snapshot = await ref.putData(bytes, metadata);
        return await snapshot.ref.getDownloadURL();
      } on FirebaseException catch (_) {
        // Fallback to putFile on native if resumable session fails
        if (!kIsWeb) {
          final SettableMetadata metadata = SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=604800',
          );
          final TaskSnapshot snapshot = await ref.putFile(imageFile, metadata);
          return await snapshot.ref.getDownloadURL();
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Lỗi upload hình ảnh: $e');
    }
  }

  Future<String> uploadVideo(File videoFile) async {
    try {
      if (_useCloudinary) {
        return await _uploadToCloudinary(videoFile, resourceType: 'video');
      }
      final String fileName =
          'videos/${DateTime.now().millisecondsSinceEpoch}_${path.basename(videoFile.path)}';
      final Reference ref = _storage.ref().child(fileName);

      try {
        final Uint8List bytes = await videoFile.readAsBytes();
        final SettableMetadata metadata = SettableMetadata(
          contentType: 'video/mp4',
          cacheControl: 'public, max-age=604800',
        );
        final TaskSnapshot snapshot = await ref.putData(bytes, metadata);
        return await snapshot.ref.getDownloadURL();
      } on FirebaseException catch (_) {
        if (!kIsWeb) {
          final SettableMetadata metadata = SettableMetadata(
            contentType: 'video/mp4',
            cacheControl: 'public, max-age=604800',
          );
          final TaskSnapshot snapshot = await ref.putFile(videoFile, metadata);
          return await snapshot.ref.getDownloadURL();
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Lỗi upload video: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Lỗi xóa hình ảnh: $e');
    }
  }

  Future<void> deleteVideo(String videoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(videoUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Lỗi xóa video: $e');
    }
  }

  Future<String> _uploadToCloudinary(
    File file, {
    required String resourceType,
  }) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final folder = CloudinaryConfig.defaultFolder;
    final stringToSign =
        'folder=$folder&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
    final signature = sha1.convert(utf8.encode(stringToSign)).toString();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/$resourceType/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = CloudinaryConfig.apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    } else {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}
