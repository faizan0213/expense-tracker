import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import 'supabase_service.dart';

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

  // Main methods - Supabase first, local backup
  static Future<List<Expense>> getExpenses() async {
    try {
      // Try Supabase first
      final expenses = await SupabaseService.getExpenses();
      
      // Backup to local storage
      await saveExpensesLocal(expenses);
      await updateLastSync();
      
      return expenses;
    } catch (e) {
      print('Supabase Error: $e, using local storage');
      // Fallback to local storage
      return await getExpensesLocal();
    }
  }

  static Future<void> addExpense(Expense expense) async {
    try {
      // Try Supabase first
      await SupabaseService.addExpense(expense);
      
      // Also update local storage
      final expenses = await getExpensesLocal();
      expenses.add(expense);
      await saveExpensesLocal(expenses);
      await updateLastSync();
    } catch (e) {
      print('Supabase Error: $e, saving locally');
      // Fallback to local storage
      final expenses = await getExpensesLocal();
      expenses.add(expense);
      await saveExpensesLocal(expenses);
    }
  }

  static Future<void> updateExpense(Expense updatedExpense) async {
    try {
      // Try Supabase first
      await SupabaseService.updateExpense(updatedExpense);
      
      // Also update local storage
      final expenses = await getExpensesLocal();
      final index = expenses.indexWhere((expense) => expense.id == updatedExpense.id);
      if (index != -1) {
        expenses[index] = updatedExpense;
        await saveExpensesLocal(expenses);
        await updateLastSync();
      }
    } catch (e) {
      print('Supabase Error: $e, updating locally');
      // Fallback to local storage
      final expenses = await getExpensesLocal();
      final index = expenses.indexWhere((expense) => expense.id == updatedExpense.id);
      if (index != -1) {
        expenses[index] = updatedExpense;
        await saveExpensesLocal(expenses);
      }
    }
  }

  static Future<void> deleteExpense(String id) async {
    try {
      // Try Supabase first
      await SupabaseService.deleteExpense(id);
      
      // Also update local storage
      final expenses = await getExpensesLocal();
      expenses.removeWhere((expense) => expense.id == id);
      await saveExpensesLocal(expenses);
      await updateLastSync();
    } catch (e) {
      print('Supabase Error: $e, deleting locally');
      // Fallback to local storage
      final expenses = await getExpensesLocal();
      expenses.removeWhere((expense) => expense.id == id);
      await saveExpensesLocal(expenses);
    }
  }

  static Future<double> getTotalExpenses() async {
    try {
      return await SupabaseService.getTotalExpenses();
    } catch (e) {
      print('Supabase Error: $e, calculating locally');
      final expenses = await getExpensesLocal();
      return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
    }
  }

  static Future<Map<String, double>> getExpensesByCategory() async {
    try {
      return await SupabaseService.getExpensesByCategory();
    } catch (e) {
      print('Supabase Error: $e, calculating locally');
      final expenses = await getExpensesLocal();
      final Map<String, double> categoryTotals = {};
      
      for (final expense in expenses) {
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
      
      return categoryTotals;
    }
  }

  // Advanced Supabase methods
  static Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      return await SupabaseService.getExpensesByDateRange(startDate, endDate);
    } catch (e) {
      print('Supabase Error: $e, filtering locally');
      final expenses = await getExpensesLocal();
      return expenses.where((expense) {
        return expense.date.isAfter(startDate) && expense.date.isBefore(endDate);
      }).toList();
    }
  }

  static Future<List<Expense>> getExpensesByCategoryName(String category) async {
    try {
      return await SupabaseService.getExpensesByCategoryName(category);
    } catch (e) {
      print('Supabase Error: $e, filtering locally');
      final expenses = await getExpensesLocal();
      return expenses.where((expense) => expense.category == category).toList();
    }
  }

  static Future<List<Expense>> searchExpenses(String query) async {
    try {
      return await SupabaseService.searchExpenses(query);
    } catch (e) {
      print('Supabase Error: $e, searching locally');
      final expenses = await getExpensesLocal();
      return expenses.where((expense) => 
        expense.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  // Sync method - local data ko Supabase pe sync karne ke liye
  static Future<bool> syncWithSupabase() async {
    try {
      final localExpenses = await getExpensesLocal();
      final supabaseExpenses = await SupabaseService.getExpenses();
      
      // Find expenses that are only in local storage
      final localOnlyExpenses = localExpenses.where((localExpense) {
        return !supabaseExpenses.any((supabaseExpense) => 
          supabaseExpense.id == localExpense.id);
      }).toList();
      
      // Upload local-only expenses to Supabase
      if (localOnlyExpenses.isNotEmpty) {
        await SupabaseService.bulkInsertExpenses(localOnlyExpenses);
      }
      
      // Update local storage with latest from Supabase
      final latestExpenses = await SupabaseService.getExpenses();
      await saveExpensesLocal(latestExpenses);
      await updateLastSync();
      
      print('Sync completed successfully. Synced ${localOnlyExpenses.length} expenses.');
      return true;
    } catch (e) {
      print('Sync failed: $e');
      return false;
    }
  }

  // Check connection and sync status
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final lastSync = await getLastSync();
      final localCount = (await getExpensesLocal()).length;
      
      // Try to get Supabase count
      int supabaseCount = 0;
      bool isConnected = false;
      
      try {
        final supabaseExpenses = await SupabaseService.getExpenses();
        supabaseCount = supabaseExpenses.length;
        isConnected = true;
      } catch (e) {
        isConnected = false;
      }
      
      return {
        'isConnected': isConnected,
        'localCount': localCount,
        'supabaseCount': supabaseCount,
        'lastSync': lastSync?.toIso8601String(),
        'needsSync': localCount != supabaseCount,
      };
    } catch (e) {
      return {
        'isConnected': false,
        'localCount': 0,
        'supabaseCount': 0,
        'lastSync': null,
        'needsSync': false,
        'error': e.toString(),
      };
    }
  }

  // Initialize and ensure table exists
  static Future<void> initialize() async {
    try {
      await SupabaseService.ensureTableExists();
      print('Supabase connection verified');
    } catch (e) {
      print('Supabase initialization failed: $e');
    }
  }
}