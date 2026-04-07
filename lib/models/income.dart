class Income {
  final String id;
  final String source;
  final double amount;
  final bool isRecurring;
  final DateTime createdAt;

  Income({
    required this.id,
    required this.source,
    required this.amount,
    this.isRecurring = false,
    required this.createdAt,
  });

  Income copyWith({
    String? id,
    String? source,
    double? amount,
    bool? isRecurring,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'amount': amount,
      'isRecurring': isRecurring,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      source: json['source'] as String,
      amount: (json['amount'] as num).toDouble(),
      isRecurring: json['isRecurring'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
