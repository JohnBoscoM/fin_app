import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';

class CategoryBadge extends StatelessWidget {
  final String categoryId;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryBadge({
    super.key,
    required this.categoryId,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Handle "All" filter with empty categoryId
    if (categoryId.isEmpty) {
      final color = const Color(0xFF9E9E9E);
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
            l.noCategory,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }

    final cat = catProvider.getCategoryById(categoryId);
    final isMonochrome = context.watch<ThemeProvider>().isMonochrome;
    final color = isMonochrome
        ? (categoryId == 'savings' ? const Color(0xFFA5D6A7) : const Color(0xFF9E9E9E))
        : (cat?.color ?? const Color(0xFFC9ADA7));
    final label = cat != null
        ? catProvider.getDisplayName(cat, l)
        : categoryId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cat != null) ...[
              Icon(cat.icon, size: 14, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
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
          ],
        ),
      ),
    );
  }
}
