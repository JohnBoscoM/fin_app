import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String nameKey; // ARB key for built-in, or raw name for custom
  final int colorValue;
  final int iconCodePoint;
  final String iconFontFamily;
  final bool isBuiltIn;

  const ExpenseCategory({
    required this.id,
    required this.nameKey,
    required this.colorValue,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
    this.isBuiltIn = false,
  });

  Color get color => Color(colorValue);

  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameKey': nameKey,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'isBuiltIn': isBuiltIn,
      };

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      nameKey: json['nameKey'] as String,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      iconFontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }
}
