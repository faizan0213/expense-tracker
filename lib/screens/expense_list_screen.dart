import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Medical',
    'Education',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _searchController.addListener(_filterExpenses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await ExpenseService.getExpenses();
      setState(() {
        _expenses = expenses..sort((a, b) => b.date.compareTo(a.date));
        _filteredExpenses = _expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading expenses: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        final matchesSearch = expense.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedFilter == 'All' || 
            expense.category == _selectedFilter;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _deleteExpense(String id) async {
    try {
      await ExpenseService.deleteExpense(id);
      await _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense(expense.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expense Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (expense.imagePath != null && expense.imagePath!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: expense.imagePath!.startsWith('http')
                      ? Image.network(
                          expense.imagePath!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : File(expense.imagePath!).existsSync()
                          ? Image.file(
                              File(expense.imagePath!),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                ),
                const SizedBox(height: 16),
              ],
              
              _buildDetailRow('Name', expense.name),
              _buildDetailRow('Amount', '₹${expense.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Category', expense.category),
              _buildDetailRow('Payment Mode', expense.mode),
              _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(expense.date)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'entertainment':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      case 'medical':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt_long;
      case 'medical':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Expense List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            _filterExpenses();
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue[600],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Expense List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first expense to get started!',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = _filteredExpenses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getCategoryColor(expense.category),
                                    child: Icon(
                                      _getCategoryIcon(expense.category),
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (expense.imagePath != null && expense.imagePath!.isNotEmpty)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.image,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                expense.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${expense.category} • ${expense.mode}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(expense.date),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${expense.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility),
                                            SizedBox(width: 8),
                                            Text('View Details'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'view') {
                                        _showExpenseDetails(expense);
                                      } else if (value == 'delete') {
                                        _showDeleteDialog(expense);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => _showExpenseDetails(expense),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}