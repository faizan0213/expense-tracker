import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/chat_expense_service.dart';
import '../services/image_extract_service.dart';

class ChatExpenseScreen extends StatefulWidget {
  const ChatExpenseScreen({super.key});

  @override
  State<ChatExpenseScreen> createState() => _ChatExpenseScreenState();
}

class _ChatExpenseScreenState extends State<ChatExpenseScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hi! Main aapka expense assistant hun. Aap mujhse keh sakte hain:\n\n"
          "📝 Text Messages:\n"
          "• 'Maine 500 rupees khana pe kharch kiye'\n"
          "• 'Transport mein 200 rupees gaye'\n"
          "• 'Shopping ke liye 1500 spend kiye'\n"
          "• 'Medical bill 800 rupees ka tha'\n\n"
          "📸 Image Upload:\n"
          "• Bill/receipt ki photo upload kariye\n"
          "• Main automatically text extract kar dunga\n\n"
          "Main automatically amount, category aur description extract kar dunga!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Process the message to extract expense data
      final expenseData = await ChatExpenseService.processExpenseMessage(message);
      
      if (expenseData != null) {
        // Create expense
        final expense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: expenseData['amount'],
          category: expenseData['category'],
          name: expenseData['description'] ?? 'Expense via Chat',
          mode: 'Cash', // Default payment mode
          date: DateTime.now(),
        );

        // Save expense
        await ExpenseService.addExpense(expense);

        // Add success message
        setState(() {
          _messages.add(ChatMessage(
            text: "✅ Expense successfully added!\n\n"
                "Amount: ₹${expense.amount.toStringAsFixed(2)}\n"
                "Category: ${expense.category}\n"
                "Name: ${expense.name}\n"
                "Mode: ${expense.mode}\n"
                "Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(expense.date)}",
            isUser: false,
            timestamp: DateTime.now(),
            expense: expense,
          ));
        });
      } else {
        // Add error message
        setState(() {
          _messages.add(ChatMessage(
            text: "Sorry, main aapke message se expense details extract nahi kar paya. "
                "Kripya amount aur category clearly mention kariye.\n\n"
                "Example: 'Maine 500 rupees food pe spend kiye'",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error occurred: $e\nPlease try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _pickAndUploadImage() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Add image message to chat
      setState(() {
        _messages.add(ChatMessage(
          text: "📸 Image uploaded",
          isUser: true,
          timestamp: DateTime.now(),
          imagePath: pickedFile.path,
        ));
        _isLoading = true;
      });

      _scrollToBottom();

      // Process image using optimized endpoint
      final imageFile = File(pickedFile.path);
      print('🎯 Chat: Starting image extraction for file: ${imageFile.path}');
      print('🎯 Chat: File size: ${await imageFile.length()} bytes');
      final result = await ImageExtractService.extractAndProcessExpense(imageFile);
      print('🎯 Chat: Extraction result: $result');

      if (result != null && result['success'] == true) {
        final expenseData = result['expense'] as Map<String, dynamic>?;

        if (expenseData != null) {
          // Create expense from extracted data
          final expense = Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: (expenseData['amount'] as num).toDouble(),
            category: expenseData['category'] ?? 'Other',
            name: expenseData['description'] ?? 'Expense from Image',
            mode: expenseData['mode'] ?? 'Cash',
            date: DateTime.now(),
            imagePath: pickedFile.path,
            billNo: expenseData['bill_no'],
          );

          // Save expense to local storage
          await ExpenseService.addExpense(expense);

          // Add success message
          setState(() {
            _messages.add(ChatMessage(
              text: "✅ Image processed & saved locally!\n\n"
                  "💰 Expense Details:\n"
                  "Amount: ₹${expense.amount.toStringAsFixed(2)}\n"
                  "Category: ${expense.category}\n"
                  "Name: ${expense.name}\n"
                  "Mode: ${expense.mode}\n"
                  "${expense.billNo != null ? 'Bill No: ${expense.billNo}\n' : ''}"
                  "Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(expense.date)}",
              isUser: false,
              timestamp: DateTime.now(),
              expense: expense,
            ));
          });
        } else {
          // Only text extracted, no expense data found
          setState(() {
            _messages.add(ChatMessage(
              text: "📝 Image processed but no expense data found.\n\n"
                  "❌ Could not extract expense information from the image. "
                  "Please try with a clearer image or add expense details manually.",
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        }
      } else {
        // Error processing image
        setState(() {
          _messages.add(ChatMessage(
            text: "❌ Failed to process image: ${result?['error'] ?? 'Unknown error'}\n\n"
                "Please try with a clearer image or add expense details manually.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "❌ Error uploading image: $e\nPlease try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image upload button
                FloatingActionButton(
                  onPressed: _isLoading ? null : _pickAndUploadImage,
                  backgroundColor: Colors.blue[600],
                  mini: true,
                  heroTag: "image_upload",
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your expense message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: Colors.green[600],
                  mini: true,
                  heroTag: "send_message",
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.green[600],
              radius: 16,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Colors.blue[600] 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show image if available
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white70 
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (message.expense != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expense Added',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[600],
              radius: 16,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Expense? expense;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.expense,
    this.imagePath,
  });
}