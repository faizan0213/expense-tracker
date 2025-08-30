import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ImageTextService {
  
  // Upload image to FastAPI endpoint for processing
  static Future<String?> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('Error: File not found at path: $filePath');
        return null;
      }

      // Get file info
      final originalFileName = filePath.split('/').last.split('\\').last;
      final bytes = await file.readAsBytes();
      
      print('Uploading file for processing: $originalFileName');
      print('File size: ${bytes.length} bytes');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.uploadEndpoint)),
      );

      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: originalFileName,
        ),
      );

      // Add timeout
      final streamedResponse = await request.send().timeout(
        ApiConfig.requestTimeout,
        onTimeout: () {
          throw Exception('Upload timeout - please try again');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final fileUrl = responseData['file_url'] ?? responseData['url'] ?? responseData['image_url'];
        
        if (fileUrl != null) {
          print('File uploaded successfully for processing: $fileUrl');
          print('Backend will process and save to Supabase automatically');
          return fileUrl;
        } else {
          print('No file URL in response: ${response.body}');
          return null;
        }
      } else {
        print('Upload failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Check upload status (optional - if your backend provides status endpoint)
  static Future<bool> checkProcessingStatus(String uploadId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getFullUrl('/status/$uploadId')),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['processed'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking processing status: $e');
      return false;
    }
  }
}