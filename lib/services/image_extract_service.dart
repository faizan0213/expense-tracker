import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ImageExtractService {
  /// Upload image and extract expense data using /extract endpoint
  static Future<Map<String, dynamic>?> extractExpenseFromImage(File imageFile) async {
    try {
      print('🚀 Starting image extraction...');
      print('📁 Image file path: ${imageFile.path}');
      print('📁 Image file exists: ${imageFile.existsSync()}');
      
      // Create multipart request
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.extractEndpoint));
      print('🔗 Uploading to: $uri');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add image file
      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();
      
      print('📁 Image size: ${(imageLength / 1024).toStringAsFixed(1)} KB');
      
      final multipartFile = http.MultipartFile(
        'file', // FastAPI expects 'file' field
        imageStream,
        imageLength,
        filename: 'expense_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      request.files.add(multipartFile);
      
      print('📤 Uploading image...');
      print('🔧 Request headers: ${request.headers}');
      print('🔧 Request files count: ${request.files.length}');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(ApiConfig.uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Response received: ${data.toString()}');
        
        // Check if extraction was successful
        if (data['extracted_data'] != null && data['extracted_data'] is List) {
          final extractedData = data['extracted_data'] as List;
          
          if (extractedData.isNotEmpty) {
            final expenseItem = extractedData[0];
            
            // Validate required fields
            final amount = expenseItem['amount'];
            if (amount == null || amount == 0) {
              return {
                'success': false,
                'error': 'No valid amount found in image',
              };
            }
            
            return {
              'success': true,
              'expense': {
                'amount': (amount is String) ? double.tryParse(amount) ?? 0.0 : (amount as num).toDouble(),
                'category': expenseItem['category'] ?? 'Other',
                'description': expenseItem['expence_name'] ?? 'Expense from Image',
                'bill_no': expenseItem['bill_no'],
                'mode': expenseItem['mode'] ?? 'Cash',
              },
            };
          } else {
            return {
              'success': false,
              'error': 'No expense data found in image',
            };
          }
        } else {
          return {
            'success': false,
            'error': 'Invalid response format from server',
          };
        }
      } else {
        final errorMsg = 'Server error: ${response.statusCode}';
        print('❌ $errorMsg');
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      
      String errorMessage = 'Failed to extract expense from image';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout - Server is slow';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error - Check internet connection';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Quick method for direct expense extraction (main method to use)
  static Future<Map<String, dynamic>?> extractAndProcessExpense(File imageFile) async {
    return await extractExpenseFromImage(imageFile);
  }

  /// Test API connectivity
  static Future<bool> testConnection() async {
    try {
      print('🧪 Testing API connection...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
      ).timeout(const Duration(seconds: 5));
      
      final isConnected = response.statusCode == 200;
      print(isConnected ? '✅ API Connected' : '❌ API Not Connected');
      return isConnected;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}