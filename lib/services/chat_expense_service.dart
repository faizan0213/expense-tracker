import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ChatExpenseService {
  // Categories mapping for Hindi/English words
  static const Map<String, List<String>> categoryKeywords = {
    'food': [
      'khana', 'food', 'restaurant', 'meal', 'breakfast', 'lunch', 'dinner',
      'snacks', 'coffee', 'tea', 'chai', 'nashta', 'khane', 'pizza', 'burger',
      'biryani', 'dal', 'rice', 'roti', 'sabzi', 'sweets', 'mithai'
    ],
    'transport': [
      'transport', 'taxi', 'uber', 'ola', 'bus', 'metro', 'train', 'petrol',
      'diesel', 'fuel', 'auto', 'rickshaw', 'bike', 'car', 'travel', 'safar',
      'yatra', 'ticket', 'parking'
    ],
    'shopping': [
      'shopping', 'clothes', 'kapde', 'shirt', 'pant', 'shoes', 'jute',
      'market', 'mall', 'online', 'amazon', 'flipkart', 'dress', 'saree',
      'kurta', 'accessories', 'bag', 'purse'
    ],
    'entertainment': [
      'movie', 'cinema', 'film', 'entertainment', 'game', 'party', 'club',
      'concert', 'music', 'book', 'magazine', 'netflix', 'subscription',
      'youtube', 'spotify', 'manoranjan'
    ],
    'bills': [
      'bill', 'electricity', 'bijli', 'water', 'pani', 'gas', 'internet',
      'wifi', 'mobile', 'phone', 'recharge', 'rent', 'kiraya', 'maintenance',
      'society', 'utility'
    ],
    'medical': [
      'medical', 'doctor', 'hospital', 'medicine', 'dawa', 'dawai', 'clinic',
      'checkup', 'treatment', 'ilaj', 'pharmacy', 'health', 'sehat', 'dentist',
      'eye', 'test', 'lab', 'x-ray', 'scan'
    ],
    'education': [
      'education', 'school', 'college', 'university', 'course', 'book', 'kitab',
      'fees', 'tuition', 'coaching', 'class', 'study', 'padhai', 'exam',
      'stationery', 'pen', 'pencil', 'notebook'
    ],
  };

  // Amount extraction patterns
  static final List<RegExp> amountPatterns = [
    RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupees?|rs\.?|₹)', caseSensitive: false),
    RegExp(r'₹\s*(\d+(?:\.\d+)?)', caseSensitive: false),
    RegExp(r'rs\.?\s*(\d+(?:\.\d+)?)', caseSensitive: false),
    RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupaiye)', caseSensitive: false),
    RegExp(r'(\d+(?:\.\d+)?)', caseSensitive: false), // fallback for any number
  ];

  // Expense action words
  static final List<String> expenseActions = [
    'spent', 'spend', 'kharch', 'kharcha', 'kiye', 'kiya', 'gaye', 'gaya',
    'paid', 'pay', 'diye', 'diya', 'bought', 'buy', 'kharida', 'kharide',
    'liya', 'liye', 'cost', 'costed', 'lagaye', 'laga', 'bill', 'expense'
  ];

  static Future<Map<String, dynamic>?> processExpenseMessage(String message) async {
    try {
      // First try to use API for better processing
      final apiResult = await _processWithAPI(message);
      if (apiResult != null) {
        return apiResult;
      }
      
      // Fallback to local processing
      return _processLocally(message);
    } catch (e) {
      print('Error in processExpenseMessage: $e');
      // Fallback to local processing
      return _processLocally(message);
    }
  }

  static Future<Map<String, dynamic>?> _processWithAPI(String message) async {
    try {
      // Check if server is reachable
      final isReachable = await ApiConfig.isServerReachable();
      if (!isReachable) {
        print('API server not reachable, using local processing');
        return null;
      }

      // Send request to backend API for NLP processing
      // Backend team ka endpoint
      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.chatExpenseEndpoint)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'language': 'mixed', // Hindi + English
        }),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validate response structure
        if (data['success'] == true && data['expense'] != null) {
          final expense = data['expense'];
          
          // Validate required fields
          if (expense['amount'] != null && 
              expense['category'] != null && 
              expense['description'] != null) {
            return {
              'amount': expense['amount'].toDouble(),
              'category': expense['category'].toString(),
              'description': expense['description'].toString(),
            };
          }
        }
      }
      
      return null;
    } catch (e) {
      print('API processing failed: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _processLocally(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check if message contains expense-related words
    bool hasExpenseAction = expenseActions.any((action) => 
        lowerMessage.contains(action.toLowerCase()));
    
    if (!hasExpenseAction) {
      return null;
    }

    // Extract amount
    double? amount = _extractAmount(lowerMessage);
    if (amount == null || amount <= 0) {
      return null;
    }

    // Extract category
    String category = _extractCategory(lowerMessage);

    // Generate description
    String description = _generateDescription(message, category, amount);

    return {
      'amount': amount,
      'category': category,
      'description': description,
    };
  }

  static double? _extractAmount(String message) {
    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }
    return null;
  }

  static String _extractCategory(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check each category's keywords
    for (final entry in categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          return category;
        }
      }
    }
    
    return 'other'; // default category
  }

  static String _generateDescription(String originalMessage, String category, double amount) {
    // Clean up the message to create a description
    String description = originalMessage.trim();
    
    // Remove common expense action words for cleaner description
    final wordsToRemove = [
      'maine', 'main', 'ne', 'mein', 'me', 'i', 'spent', 'spend', 'paid', 'pay',
      'kiye', 'kiya', 'gaye', 'gaya', 'diye', 'diya', 'kharch', 'kharcha',
      'rupees', 'rupaye', 'rupaiye', 'rs', '₹'
    ];
    
    List<String> words = description.split(' ');
    words = words.where((word) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      return !wordsToRemove.contains(cleanWord) && 
             !RegExp(r'^\d+(\.\d+)?$').hasMatch(cleanWord);
    }).toList();
    
    description = words.join(' ').trim();
    
    // If description is too short or empty, generate based on category
    if (description.length < 5) {
      switch (category) {
        case 'food':
          description = 'Food expense';
          break;
        case 'transport':
          description = 'Transportation expense';
          break;
        case 'shopping':
          description = 'Shopping expense';
          break;
        case 'entertainment':
          description = 'Entertainment expense';
          break;
        case 'bills':
          description = 'Bill payment';
          break;
        case 'medical':
          description = 'Medical expense';
          break;
        case 'education':
          description = 'Education expense';
          break;
        default:
          description = 'General expense';
      }
    }
    
    return description;
  }

  // Helper method to get category suggestions
  static List<String> getCategorySuggestions() {
    return categoryKeywords.keys.toList();
  }

  // Helper method to get example messages
  static List<String> getExampleMessages() {
    return [
      'Maine 500 rupees khana pe kharch kiye',
      'Transport mein 200 rupees gaye',
      'Shopping ke liye 1500 spend kiye',
      'Medical bill 800 rupees ka tha',
      'Petrol mein 2000 rupees bharwaye',
      'Movie ticket ke liye 300 paid kiye',
      'Electricity bill 1200 rupees ka aaya',
      'Books ke liye 800 rupees kharche',
    ];
  }
}