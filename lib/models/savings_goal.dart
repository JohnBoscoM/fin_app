class SavingsGoal {
  final String id;
  final String name;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String colorHex;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.colorHex,
    required this.createdAt,
  });

  SavingsGoal copyWith({
    String? id,
    String? name,
    String? emoji,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progressPercent {
    final percent = (currentAmount / targetAmount) * 100;
    return percent.clamp(0, 100);
  }

  int get daysRemaining {
    if (deadline == null) return -1;
    final now = DateTime.now();
    return deadline!.difference(now).inDays;
  }

  bool get isCompleted => progressPercent >= 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      colorHex: json['colorHex'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
