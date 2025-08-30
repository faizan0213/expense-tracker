import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'expenses';

  // Get all expenses
  static Future<List<Expense>> getExpenses() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching expenses: $e');
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  // Add new expense
  static Future<Expense> addExpense(Expense expense) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(expense.toJson())
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      print('Error adding expense: $e');
      throw Exception('Failed to add expense: $e');
    }
  }

  // Update expense
  static Future<Expense> updateExpense(Expense expense) async {
    try {
      final response = await _client
          .from(_tableName)
          .update(expense.toJson())
          .eq('id', expense.id)
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      print('Error updating expense: $e');
      throw Exception('Failed to update expense: $e');
    }
  }

  // Delete expense
  static Future<void> deleteExpense(String id) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Get total expenses
  static Future<double> getTotalExpenses() async {
    try {
      final expenses = await getExpenses();
      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    } catch (e) {
      print('Error calculating total expenses: $e');
      return 0.0;
    }
  }

  // Get expenses by category
  static Future<Map<String, double>> getExpensesByCategory() async {
    try {
      final expenses = await getExpenses();
      final Map<String, double> categoryTotals = {};
      
      for (final expense in expenses) {
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
      
      return categoryTotals;
    } catch (e) {
      print('Error getting expenses by category: $e');
      return {};
    }
  }

  // Get expenses by date range
  static Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching expenses by date range: $e');
      throw Exception('Failed to fetch expenses by date range: $e');
    }
  }

  // Get expenses by specific category
  static Future<List<Expense>> getExpensesByCategoryName(String category) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('category', category)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching expenses by category: $e');
      throw Exception('Failed to fetch expenses by category: $e');
    }
  }

  // Search expenses by name
  static Future<List<Expense>> searchExpenses(String query) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .ilike('name', '%$query%')
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching expenses: $e');
      throw Exception('Failed to search expenses: $e');
    }
  }

  // Bulk insert expenses (for sync)
  static Future<List<Expense>> bulkInsertExpenses(List<Expense> expenses) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(expenses.map((e) => e.toJson()).toList())
          .select();

      return (response as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } catch (e) {
      print('Error bulk inserting expenses: $e');
      throw Exception('Failed to bulk insert expenses: $e');
    }
  }

  // Check if table exists and create if not
  static Future<void> ensureTableExists() async {
    try {
      // Try to fetch one record to check if table exists
      await _client.from(_tableName).select().limit(1);
    } catch (e) {
      print('Table might not exist. Please create the expenses table in Supabase dashboard.');
      print('SQL to create table:');
      print('''
        CREATE TABLE expenses (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          name TEXT NOT NULL,
          bill_no TEXT,
          amount DECIMAL(10,2) NOT NULL,
          mode TEXT NOT NULL,
          date TIMESTAMP WITH TIME ZONE NOT NULL,
          image_path TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Enable RLS
        ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
        
        -- Create policy for public access
        CREATE POLICY "Enable all operations for all users" ON expenses
        FOR ALL USING (true);
      ''');
      throw Exception('Expenses table does not exist. Please create it in Supabase dashboard.');
    }
  }
}