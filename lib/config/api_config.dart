import 'package:http/http.dart' as http;

class ApiConfig {
  // FastAPI server configuration
  static const String baseUrl = 'http://localhost:8000'; // Change this to your FastAPI server URL
  
  // API endpoints
  static const String uploadEndpoint = '/upload-image';
  static const String statusEndpoint = '/status'; // For checking processing status
  static const String chatExpenseEndpoint = '/api/v1/process-expense-message'; // Chat expense processing
  
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
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}