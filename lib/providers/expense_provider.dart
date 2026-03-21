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
    
    _isLoading = false;
    notifyListeners();
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
}
