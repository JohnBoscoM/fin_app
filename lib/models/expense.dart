class Expense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final bool isRecurring;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.isRecurring,
    required this.createdAt,
  });

  Expense copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    bool? isRecurring,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'isRecurring': isRecurring,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      isRecurring: json['isRecurring'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
