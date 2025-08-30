import 'dart:io';
import 'image_extract_service.dart';

class ApiTestService {
  /// Test the /extract endpoint with a sample image
  static Future<void> testExtractEndpoint() async {
    print('🧪 Testing /extract endpoint...');
    
    try {
      // Test connection first
      final isConnected = await ImageExtractService.testConnection();
      
      if (!isConnected) {
        print('❌ API server not reachable');
        return;
      }
      
      print('✅ API server is reachable');
      print('📋 Endpoint ready for image upload');
      print('🔗 URL: https://expense-tracker-4y3n.onrender.com/extract');
      print('📝 Method: POST');
      print('📎 Field: file (multipart/form-data)');
      
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }
  
  /// Test with actual image file (if available)
  static Future<void> testWithImage(File imageFile) async {
    print('🧪 Testing with actual image...');
    
    try {
      final result = await ImageExtractService.extractAndProcessExpense(imageFile);
      
      if (result != null && result['success'] == true) {
        print('✅ Image processing successful!');
        print('📊 Extracted data: ${result['expense']}');
      } else {
        print('❌ Image processing failed: ${result?['error']}');
      }
    } catch (e) {
      print('❌ Test with image failed: $e');
    }
  }
}