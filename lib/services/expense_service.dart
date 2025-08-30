import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _expensesKey = 'expenses';
  static const String _lastSyncKey = 'last_sync';

  // Local storage methods (backup ke liye)
  static Future<List<Expense>> getExpensesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_expensesKey) ?? [];
    
    return expensesJson
        .map((json) => Expense.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveExpensesLocal(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = expenses
        .map((expense) => jsonEncode(expense.toJson()))
        .toList();
    
    await prefs.setStringList(_expensesKey, expensesJson);
  }

  static Future<void> updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey);
    return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
  }

  // Main methods - Local storage only
  static Future<List<Expense>> getExpenses() async {
    return await getExpensesLocal();
  }

  static Future<void> addExpense(Expense expense) async {
    final expenses = await getExpensesLocal();
    expenses.add(expense);
    await saveExpensesLocal(expenses);
    await updateLastSync();
    print('✅ Expense added to local storage: ${expense.name}');
  }

  static Future<void> updateExpense(Expense updatedExpense) async {
    final expenses = await getExpensesLocal();
    final index = expenses.indexWhere((expense) => expense.id == updatedExpense.id);
    if (index != -1) {
      expenses[index] = updatedExpense;
      await saveExpensesLocal(expenses);
      await updateLastSync();
      print('✅ Expense updated in local storage: ${updatedExpense.name}');
    }
  }

  static Future<void> deleteExpense(String id) async {
    final expenses = await getExpensesLocal();
    expenses.removeWhere((expense) => expense.id == id);
    await saveExpensesLocal(expenses);
    await updateLastSync();
    print('✅ Expense deleted from local storage');
  }

  static Future<double> getTotalExpenses() async {
    final expenses = await getExpensesLocal();
    return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  static Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getExpensesLocal();
    final Map<String, double> categoryTotals = {};
    
    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    return categoryTotals;
  }

  // Advanced filtering methods
  static Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    final expenses = await getExpensesLocal();
    return expenses.where((expense) {
      return expense.date.isAfter(startDate) && expense.date.isBefore(endDate);
    }).toList();
  }

  static Future<List<Expense>> getExpensesByCategoryName(String category) async {
    final expenses = await getExpensesLocal();
    return expenses.where((expense) => expense.category == category).toList();
  }

  static Future<List<Expense>> searchExpenses(String query) async {
    final expenses = await getExpensesLocal();
    return expenses.where((expense) => 
      expense.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get storage status
  static Future<Map<String, dynamic>> getStorageStatus() async {
    try {
      final lastSync = await getLastSync();
      final localCount = (await getExpensesLocal()).length;
      
      return {
        'storageType': 'Local Storage',
        'totalExpenses': localCount,
        'lastUpdated': lastSync?.toIso8601String(),
        'isOnline': false,
        'message': 'Using local storage only - all data saved on device',
      };
    } catch (e) {
      return {
        'storageType': 'Local Storage',
        'totalExpenses': 0,
        'lastUpdated': null,
        'isOnline': false,
        'error': e.toString(),
      };
    }
  }

  // Sync status method
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final localCount = (await getExpensesLocal()).length;
      final lastSync = await getLastSync();
      
      return {
        'isConnected': false, // Currently only local storage
        'localCount': localCount,
        'supabaseCount': 0, // No Supabase integration yet
        'needsSync': false, // No sync needed for local-only
        'lastSync': lastSync?.toIso8601String(),
        'message': 'Local storage only - Supabase integration not configured',
      };
    } catch (e) {
      return {
        'isConnected': false,
        'localCount': 0,
        'supabaseCount': 0,
        'needsSync': false,
        'lastSync': null,
        'error': e.toString(),
      };
    }
  }

  // Sync with Supabase method (placeholder for future implementation)
  static Future<bool> syncWithSupabase() async {
    try {
      // TODO: Implement actual Supabase sync when credentials are configured
      print('🔄 Sync with Supabase requested...');
      
      // For now, just simulate a sync operation
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if Supabase is configured (placeholder check)
      // In a real implementation, you would check if credentials are valid
      print('⚠️ Supabase sync not implemented yet - using local storage only');
      
      return false; // Return false since sync is not actually implemented
    } catch (e) {
      print('❌ Sync with Supabase failed: $e');
      return false;
    }
  }

  // Initialize local storage
  static Future<void> initialize() async {
    print('📱 Initializing local storage...');
    try {
      final expenses = await getExpensesLocal();
      print('✅ Local storage initialized with ${expenses.length} expenses');
    } catch (e) {
      print('❌ Local storage initialization failed: $e');
    }
  }
}