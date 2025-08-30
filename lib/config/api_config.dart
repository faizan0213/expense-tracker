import 'package:http/http.dart' as http;

class ApiConfig {
  // FastAPI server configuration
  static const String baseUrl = 'https://expense-tracker-4y3n.onrender.com'; // Change this to your FastAPI server URL
  
  // API endpoints
  static const String uploadEndpoint = '/upload-image';
  static const String extractEndpoint = '/extract'; // Image upload and text extraction
  static const String statusEndpoint = '/status'; // For checking processing status
  static const String chatExpenseEndpoint = '/process-expense-text'; // Chat expense processing
  
  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60); // Longer timeout for uploads
  
  // Get full URL for endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Helper method to check if server is reachable
  static Future<bool> isServerReachable() async {
    try {
      print('🔍 Checking server reachability: $baseUrl/health');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      print('🔍 Server response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('🔍 Server unreachable: $e');
      return false;
    }
  }
}