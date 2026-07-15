import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'qr84sqb0';
  static const String _uploadPreset = 'expense_tracker_profiles';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads [imageFile] to Cloudinary and returns the secure CDN URL.
  /// Throws an [Exception] if the upload fails.
  static Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary returned no URL.');
      }
      return secureUrl;
    } else {
      final error = _parseCloudinaryError(responseBody);
      throw Exception('Cloudinary upload failed (${ streamedResponse.statusCode}): $error');
    }
  }

  static String _parseCloudinaryError(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return json['error']?['message'] as String? ?? responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
