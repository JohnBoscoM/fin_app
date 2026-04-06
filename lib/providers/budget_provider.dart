import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/storage_service.dart';

class BudgetProvider extends ChangeNotifier {
  final StorageService _storage;
  List<Budget> _budgets = [];
  bool _isLoading = false;

  BudgetProvider(this._storage);

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();

    _budgets = await _storage.getBudgets();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBudget(Budget budget) async {
    _budgets.add(budget);
    await _storage.saveBudgets(_budgets);
    notifyListeners();
  }

  Future<void> updateBudget(Budget budget) async {
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
      await _storage.saveBudgets(_budgets);
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    await _storage.saveBudgets(_budgets);
    notifyListeners();
  }

  List<Budget> getBudgetsForMonth(DateTime month) {
    return _budgets.where((b) =>
      b.month.year == month.year && b.month.month == month.month,
    ).toList();
  }

  Budget? getBudgetForCategory(String category, DateTime month) {
    try {
      return _budgets.firstWhere((b) =>
        b.category == category &&
        b.month.year == month.year &&
        b.month.month == month.month,
      );
    } catch (_) {
      return null;
    }
  }

  double getTotalBudgeted(DateTime month) {
    return getBudgetsForMonth(month)
        .fold(0.0, (sum, b) => sum + b.monthlyLimit);
  }
}
