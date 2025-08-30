import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/image_text_service.dart';
import '../config/api_config.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from camera or gallery
  static Future<File?> pickImage({
    required ImageSource source,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick any file (PDF, CSV, Images, etc.)
  static Future<File?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  // Pick PDF file specifically
  static Future<File?> pickPdfFile() async {
    return await pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  // Pick CSV file specifically
  static Future<File?> pickCsvFile() async {
    return await pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
  }

  // Pick image file from storage
  static Future<File?> pickImageFile() async {
    return await pickFile(
      type: FileType.image,
    );
  }

  // Show file source selection dialog
  static Future<File?> showFileSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select File Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // First Row - Camera and Gallery
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await pickImage(source: ImageSource.camera);
                        if (context.mounted) {
                          Navigator.pop(context, image);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt, size: 30, color: Colors.blue),
                            SizedBox(height: 8),
                            Text('Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('Take photo', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await pickImageFile();
                        if (context.mounted) {
                          Navigator.pop(context, image);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library, size: 30, color: Colors.green),
                            SizedBox(height: 8),
                            Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('Choose image', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Second Row - PDF and CSV
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final file = await pickPdfFile();
                        if (context.mounted) {
                          Navigator.pop(context, file);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 30, color: Colors.red),
                            SizedBox(height: 8),
                            Text('PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('Upload PDF', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final file = await pickCsvFile();
                        if (context.mounted) {
                          Navigator.pop(context, file);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.table_chart, size: 30, color: Colors.orange),
                            SizedBox(height: 8),
                            Text('CSV', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('Upload CSV', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Third Row - Any File
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickFile();
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.attach_file, size: 30, color: Colors.purple),
                      SizedBox(height: 8),
                      Text('Other Files', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text('Upload any file type', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Keep the old method for backward compatibility
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showFileSourceDialog(context);
  }

  // Upload image to FastAPI for processing and return URL
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Check if server is reachable first
      final isReachable = await ApiConfig.isServerReachable();
      if (!isReachable) {
        print('FastAPI server is not reachable. Please check your backend.');
        return null;
      }
      
      print('Uploading image to FastAPI for text extraction...');
      final imageUrl = await ImageTextService.uploadImage(imageFile.path);
      
      if (imageUrl != null) {
        print('Image uploaded successfully. Backend will process and save to Supabase.');
      }
      
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload any file to FastAPI for processing
  static Future<String?> uploadFile(File file) async {
    try {
      // Check if server is reachable first
      final isReachable = await ApiConfig.isServerReachable();
      if (!isReachable) {
        print('FastAPI server is not reachable. Please check your backend.');
        return null;
      }
      
      print('Uploading file to FastAPI for processing...');
      final fileUrl = await ImageTextService.uploadImage(file.path);
      
      if (fileUrl != null) {
        print('File uploaded successfully. Backend will process and save to Supabase.');
      }
      
      return fileUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Check if string is a valid image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http') || url.startsWith('https');
  }

  // Get image widget based on path/URL
  static Widget getImageWidget(
    String? imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return errorWidget ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
              ),
            ),
          );
    }

    if (isValidImageUrl(imagePath)) {
      // Network image (FastAPI server URL)
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                ),
              );
        },
      );
    } else {
      // Local file
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
        );
      } else {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              ),
            );
      }
    }
  }

  // File validation helpers
  static bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  static bool isValidPdfFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return extension == 'pdf';
  }

  static bool isValidCsvFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return extension == 'csv';
  }

  static String getFileType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return 'Image';
    } else if (extension == 'pdf') {
      return 'PDF';
    } else if (extension == 'csv') {
      return 'CSV';
    } else {
      return 'File';
    }
  }

  static String getFileName(File file) {
    return file.path.split('/').last.split('\\').last;
  }

  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }
}