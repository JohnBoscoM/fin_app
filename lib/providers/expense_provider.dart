import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/storage_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final StorageService _storage;
  List<Expense> _expenses = [];
  bool _isLoading = false;

  ExpenseProvider(this._storage);

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    
    _expenses = await _storage.getExpenses();

    // Migrate old capitalized category names to lowercase IDs
    bool migrated = false;
    for (int i = 0; i < _expenses.length; i++) {
      final oldCat = _expenses[i].category;
      final newCat = _migrateCategoryName(oldCat);
      if (newCat != oldCat) {
        _expenses[i] = _expenses[i].copyWith(category: newCat);
        migrated = true;
      }
    }
    if (migrated) {
      await _storage.saveExpenses(_expenses);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  static String _migrateCategoryName(String category) {
    const mapping = {
      'Housing': 'housing',
      'Food': 'food',
      'Transport': 'transport',
      'Subscriptions': 'subscriptions',
      'Health': 'health',
      'Entertainment': 'entertainment',
      'Other': 'other',
    };
    return mapping[category] ?? category;
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      await _storage.saveExpenses(_expenses);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  List<Expense> getExpensesByCategory(String category) {
    if (category.isEmpty) return _expenses;
    return _expenses.where((e) => e.category == category).toList();
  }

  double getTotalExpenses() {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Expense> getTopExpenses({int limit = 5}) {
    final sorted = [..._expenses]..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.take(limit).toList();
  }

  List<Expense> getExpensesForMonth(DateTime month) {
    return _expenses.where((e) =>
      e.createdAt.year == month.year && e.createdAt.month == month.month,
    ).toList();
  }

  List<Expense> getExpensesByCategoryForMonth(String category, DateTime month) {
    return getExpensesForMonth(month)
        .where((e) => category.isEmpty || e.category == category)
        .toList();
  }

  double getTotalExpensesForMonth(DateTime month) {
    return getExpensesForMonth(month).fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getCategoryTotalsForMonth(DateTime month) {
    final expenses = getExpensesForMonth(month);
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<Expense> getTopExpensesForMonth(DateTime month, {int limit = 5}) {
    final sorted = [...getExpensesForMonth(month)]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.take(limit).toList();
  }
}
