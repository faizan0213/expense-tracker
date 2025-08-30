import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/image_text_service.dart';
import '../utils/image_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food';
  String _selectedMode = 'Cash';
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Medical',
    'Education',
    'Other',
  ];

  final List<String> _paymentModes = [
    'Cash',
    'Credit Card',
    'UPI',
    'Net Banking',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose file source
      final File? selectedFile = await ImageHelper.showFileSourceDialog(context);

      if (selectedFile != null) {
        setState(() {
          _selectedImage = selectedFile;
          _isLoading = true;
        });

        // Check file type and process accordingly
        final fileType = ImageHelper.getFileType(selectedFile);
        final fileName = ImageHelper.getFileName(selectedFile);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing $fileType file: $fileName'),
            backgroundColor: Colors.blue,
          ),
        );

        // File selected successfully
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileType file selected: $fileName\nReady to upload when saving expense.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilePreview(File file) {
    final fileType = ImageHelper.getFileType(file);
    final fileName = ImageHelper.getFileName(file);
    final fileSizeMB = ImageHelper.getFileSizeInMB(file);

    if (ImageHelper.isValidImageFile(file)) {
      // Show image preview
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Show file info card for non-image files
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(fileType),
              size: 40,
              color: _getFileColor(fileType),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$fileType • ${fileSizeMB.toStringAsFixed(2)} MB',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'CSV':
        return Icons.table_chart;
      case 'JPEG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Colors.red;
      case 'CSV':
        return Colors.orange;
      case 'JPEG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;

        // Upload file to FastAPI server if selected
        if (_selectedImage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading file to server...'),
              backgroundColor: Colors.blue,
            ),
          );

          imageUrl = await ImageTextService.uploadImage(_selectedImage!.path);

          if (imageUrl == null) {
            throw Exception('Failed to upload file to server');
          }
        }

        final expense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          category: _selectedCategory,
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          mode: _selectedMode,
          date: _selectedDate,
          imagePath: imageUrl, // Use FastAPI server URL instead of local path
        );

        await ExpenseService.addExpense(expense);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                imageUrl != null
                    ? 'Expense added with file successfully!'
                    : 'Expense added successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Upload Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_selectedImage != null) ...[
                              _buildFilePreview(_selectedImage!),
                              const SizedBox(height: 12),
                            ],
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                _selectedImage == null
                                    ? 'Upload File/Receipt'
                                    : 'Change File',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Form Fields
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Name Field
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Expense Name',
                                prefixIcon: const Icon(Icons.receipt),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter expense name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Amount Field
                            TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Amount (₹)',
                                prefixIcon: const Icon(Icons.currency_rupee),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter amount';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter valid amount';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Category Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: const Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // Payment Mode Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedMode,
                              decoration: InputDecoration(
                                labelText: 'Payment Mode',
                                prefixIcon: const Icon(Icons.payment),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: _paymentModes.map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMode = value!;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // Date Picker
                            InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Save Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
