
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = "z1swumqg";
  static const String uploadPreset = "motofind_upload";

  static const int maxFileSize = 5 * 1024 * 1024;

  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  static Future<String?> uploadImage(XFile image) async {
    try {
      // Validate image format
      final extension = image.name.split('.').last.toLowerCase();

      if (!allowedExtensions.contains(extension)) {
        print("Upload rejected: Unsupported image format.");
        return null;
      }

      // Validate file size
      final fileSize = await image.length();

      if (fileSize == 0 || fileSize > maxFileSize) {
        print("Upload rejected: Image must be between 1 byte and 5 MB.");
        return null;
      }

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url);

      request.fields["upload_preset"] = uploadPreset;

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          await image.readAsBytes(),
          filename: image.name,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final imageUrl = data["secure_url"];

        if (imageUrl is String && imageUrl.isNotEmpty) {
          print("Image Uploaded Successfully");
          return imageUrl;
        }
      }

      print("Cloudinary Upload Failed: ${response.statusCode}");
      return null;
    } catch (e) {
      print("Cloudinary Exception: $e");
      return null;
    }
  }
}
