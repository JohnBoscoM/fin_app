enum AssetType {
  stock,
  fund,
  crypto,
  realEstate,
  cash,
  other;

  String get displayName {
    switch (this) {
      case AssetType.stock:
        return 'Stocks';
      case AssetType.fund:
        return 'Funds';
      case AssetType.crypto:
        return 'Crypto';
      case AssetType.realEstate:
        return 'Real Estate';
      case AssetType.cash:
        return 'Cash';
      case AssetType.other:
        return 'Other';
    }
  }
}

class Asset {
  final String id;
  final String name;
  final AssetType type;
  final double currentValue;
  final double purchaseValue;
  final DateTime purchaseDate;
  final String? notes;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.currentValue,
    required this.purchaseValue,
    required this.purchaseDate,
    this.notes,
  });

  double get gainLoss => currentValue - purchaseValue;

  double get gainLossPercent {
    if (purchaseValue == 0) return 0;
    return ((currentValue - purchaseValue) / purchaseValue) * 100;
  }

  Asset copyWith({
    String? id,
    String? name,
    AssetType? type,
    double? currentValue,
    double? purchaseValue,
    DateTime? purchaseDate,
    String? notes,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currentValue: currentValue ?? this.currentValue,
      purchaseValue: purchaseValue ?? this.purchaseValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'currentValue': currentValue,
      'purchaseValue': purchaseValue,
      'purchaseDate': purchaseDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AssetType.values.firstWhere((e) => e.name == json['type']),
      currentValue: (json['currentValue'] as num).toDouble(),
      purchaseValue: (json['purchaseValue'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      notes: json['notes'] as String?,
    );
  }
}
