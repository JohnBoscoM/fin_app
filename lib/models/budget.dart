class Budget {
  final String id;
  final String category;
  final double monthlyLimit;
  final DateTime month; // First day of the month

  Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
  });

  Budget copyWith({
    String? id,
    String? category,
    double? monthlyLimit,
    DateTime? month,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'month': month.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      month: DateTime.parse(json['month'] as String),
    );
  }
}
