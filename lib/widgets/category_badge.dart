import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;

  static const Map<String, Color> categoryColors = {
    'Housing': Color(0xFFFF6B6B),
    'Food': Color(0xFFFFA500),
    'Transport': Color(0xFF4ECDC4),
    'Subscriptions': Color(0xFF95E1D3),
    'Health': Color(0xFFA8E6CF),
    'Entertainment': Color(0xFFFFD93D),
    'Other': Color(0xFFC9ADA7),
  };

  const CategoryBadge({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  Color getCategoryColor() {
    return categoryColors[category] ?? const Color(0xFFC9ADA7);
  }

  @override
  Widget build(BuildContext context) {
    final color = getCategoryColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: color),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      ),
    );
  }
}
