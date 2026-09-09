import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  Future<String> uploadImage(XFile image, {String folder = 'shopify/products'}) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Cloudinary configuration is missing. Check your .env file.');
    }

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;

    final bytes = await image.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: $responseBody');
    }

    final data = jsonDecode(responseBody);
    final imageUrl = data['secure_url'];

    if (imageUrl == null) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return imageUrl;
  }
}
