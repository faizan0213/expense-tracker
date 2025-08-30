class Expense {
  final String id;
  final String category;
  final String name;
  final String? billNo;
  final double amount;
  final String mode;
  final DateTime date;
  final String? imagePath;

  Expense({
    required this.id,
    required this.category,
    required this.name,
    this.billNo,
    required this.amount,
    required this.mode,
    required this.date,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'bill_no': billNo,
      'amount': amount,
      'mode': mode,
      'date': date.toIso8601String(),
      'image_path': imagePath,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      category: json['category'],
      name: json['name'],
      billNo: json['bill_no'],
      amount: json['amount'].toDouble(),
      mode: json['mode'],
      date: DateTime.parse(json['date']),
      imagePath: json['image_path'],
    );
  }

  Expense copyWith({
    String? id,
    String? category,
    String? name,
    String? billNo,
    double? amount,
    String? mode,
    DateTime? date,
    String? imagePath,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      billNo: billNo ?? this.billNo,
      amount: amount ?? this.amount,
      mode: mode ?? this.mode,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}