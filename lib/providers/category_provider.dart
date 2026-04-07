import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../services/storage_service.dart';

class CategoryProvider extends ChangeNotifier {
  final StorageService _storage;
  List<ExpenseCategory> _categories = [];

  CategoryProvider(this._storage);

  List<ExpenseCategory> get categories => _categories;

  // Default built-in categories with their icon code points
  static List<ExpenseCategory> get defaultCategories => [
        ExpenseCategory(
          id: 'housing',
          nameKey: 'housing',
          colorValue: 0xFFFF6B6B,
          iconCodePoint: Icons.home_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'food',
          nameKey: 'food',
          colorValue: 0xFFFFA500,
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'transport',
          nameKey: 'transport',
          colorValue: 0xFF4ECDC4,
          iconCodePoint: Icons.directions_car_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'subscriptions',
          nameKey: 'subscriptions',
          colorValue: 0xFF95E1D3,
          iconCodePoint: Icons.subscriptions_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'health',
          nameKey: 'health',
          colorValue: 0xFFA8E6CF,
          iconCodePoint: Icons.favorite_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'entertainment',
          nameKey: 'entertainment',
          colorValue: 0xFFFFD93D,
          iconCodePoint: Icons.movie_rounded.codePoint,
          isBuiltIn: true,
        ),
        // Common brand / subscription categories
        ExpenseCategory(
          id: 'spotify',
          nameKey: 'spotify',
          colorValue: 0xFF1DB954,
          iconCodePoint: Icons.music_note_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'netflix',
          nameKey: 'netflix',
          colorValue: 0xFFE50914,
          iconCodePoint: Icons.play_circle_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'gym',
          nameKey: 'gym',
          colorValue: 0xFFFF9800,
          iconCodePoint: Icons.fitness_center_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'shopping',
          nameKey: 'shopping',
          colorValue: 0xFFE91E63,
          iconCodePoint: Icons.shopping_bag_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'travel',
          nameKey: 'travel',
          colorValue: 0xFF03A9F4,
          iconCodePoint: Icons.flight_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'education',
          nameKey: 'education',
          colorValue: 0xFF9C27B0,
          iconCodePoint: Icons.school_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'gaming',
          nameKey: 'gaming',
          colorValue: 0xFF7C4DFF,
          iconCodePoint: Icons.sports_esports_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'insurance',
          nameKey: 'insurance',
          colorValue: 0xFF607D8B,
          iconCodePoint: Icons.security_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'electricity',
          nameKey: 'electricity',
          colorValue: 0xFFFFC107,
          iconCodePoint: Icons.bolt_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'phone',
          nameKey: 'phone',
          colorValue: 0xFF00BCD4,
          iconCodePoint: Icons.phone_android_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'internet',
          nameKey: 'internet',
          colorValue: 0xFF3F51B5,
          iconCodePoint: Icons.wifi_rounded.codePoint,
          isBuiltIn: true,
        ),
        ExpenseCategory(
          id: 'savings',
          nameKey: 'savings',
          colorValue: 0xFF2CB67D,
          iconCodePoint: Icons.savings_rounded.codePoint,
          iconFontFamily: 'MaterialIcons',
          isBuiltIn: true,
        ),
        // "Other" always last among built-ins
        ExpenseCategory(
          id: 'other',
          nameKey: 'other',
          colorValue: 0xFFC9ADA7,
          iconCodePoint: Icons.receipt_rounded.codePoint,
          isBuiltIn: true,
        ),
      ];

  Future<void> loadCategories() async {
    _categories = await _storage.getCategories();
    if (_categories.isEmpty) {
      _categories = List.of(defaultCategories);
      await _storage.saveCategories(_categories);
    } else {
      // Migration: ensure 'savings' category exists
      final hasSavings = _categories.any((c) => c.id == 'savings');
      if (!hasSavings) {
        final otherIdx = _categories.indexWhere((c) => c.id == 'other');
        final savingsCat = defaultCategories.firstWhere((c) => c.id == 'savings');
        if (otherIdx >= 0) {
          _categories.insert(otherIdx, savingsCat);
        } else {
          _categories.add(savingsCat);
        }
        await _storage.saveCategories(_categories);
      }
    }
    notifyListeners();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    // Insert custom categories before "Other"
    final otherIdx = _categories.indexWhere((c) => c.id == 'other');
    if (otherIdx >= 0) {
      _categories.insert(otherIdx, category);
    } else {
      _categories.add(category);
    }
    await _storage.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      _categories[idx] = category;
      await _storage.saveCategories(_categories);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _storage.saveCategories(_categories);
    notifyListeners();
  }

  ExpenseCategory? getCategoryById(String id) {
    final idx = _categories.indexWhere((c) => c.id == id);
    return idx >= 0 ? _categories[idx] : null;
  }

  /// Resolve display name: built-in categories use l10n, custom use nameKey directly
  String getDisplayName(ExpenseCategory cat, AppLocalizations l) {
    if (!cat.isBuiltIn) return cat.nameKey;
    return _localizedName(cat.id, l);
  }

  /// Resolve display name from category id string
  String getDisplayNameById(String id, AppLocalizations l) {
    final cat = getCategoryById(id);
    if (cat != null) return getDisplayName(cat, l);
    // Fallback: try l10n key, else raw id
    return _localizedName(id, l);
  }

  static String _localizedName(String id, AppLocalizations l) {
    switch (id) {
      case 'housing':
        return l.housing;
      case 'food':
        return l.food;
      case 'transport':
        return l.transport;
      case 'subscriptions':
        return l.subscriptions;
      case 'health':
        return l.health;
      case 'entertainment':
        return l.entertainment;
      case 'other':
        return l.other;
      case 'spotify':
        return l.spotify;
      case 'netflix':
        return l.netflix;
      case 'gym':
        return l.gym;
      case 'shopping':
        return l.shopping;
      case 'travel':
        return l.travel;
      case 'education':
        return l.education;
      case 'gaming':
        return l.gaming;
      case 'insurance':
        return l.insurance;
      case 'electricity':
        return l.electricity;
      case 'phone':
        return l.phone;
      case 'internet':
        return l.internet;
      case 'savings':
        return l.savings;
      default:
        return id;
    }
  }
}
