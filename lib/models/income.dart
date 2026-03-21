class Income {
  final String id;
  final String source;
  final double amount;
  final DateTime createdAt;

  Income({
    required this.id,
    required this.source,
    required this.amount,
    required this.createdAt,
  });

  Income copyWith({
    String? id,
    String? source,
    double? amount,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      source: json['source'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
