import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/storage_service.dart';

class IncomeProvider extends ChangeNotifier {
  final StorageService _storage;
  List<Income> _incomes = [];
  bool _isLoading = false;

  IncomeProvider(this._storage);

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;

  Future<void> loadIncomes() async {
    _isLoading = true;
    notifyListeners();
    
    _incomes = await _storage.getIncomes();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addIncome(Income income) async {
    _incomes.add(income);
    await _storage.saveIncomes(_incomes);
    notifyListeners();
  }

  Future<void> updateIncome(Income income) async {
    final index = _incomes.indexWhere((i) => i.id == income.id);
    if (index != -1) {
      _incomes[index] = income;
      await _storage.saveIncomes(_incomes);
      notifyListeners();
    }
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
    await _storage.saveIncomes(_incomes);
    notifyListeners();
  }

  double getTotalIncome() {
    return _incomes.fold(0.0, (sum, i) => sum + i.amount);
  }

  List<Income> getIncomesForMonth(DateTime month) {
    return _incomes.where((i) =>
      i.createdAt.year == month.year && i.createdAt.month == month.month,
    ).toList();
  }

  double getTotalIncomeForMonth(DateTime month) {
    return getIncomesForMonth(month).fold(0.0, (sum, i) => sum + i.amount);
  }
}
