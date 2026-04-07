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
    final List<Income> result = [];
    for (final i in _incomes) {
      final sameMonth = i.createdAt.year == month.year
                     && i.createdAt.month == month.month;
      if (sameMonth) {
        result.add(i);
      } else if (i.isRecurring && _isBeforeMonth(i.createdAt, month)) {
        result.add(i.copyWith(
          id: '${i.id}_${month.year}_${month.month}',
          createdAt: DateTime(month.year, month.month,
              i.createdAt.day.clamp(1, _daysInMonth(month))),
        ));
      }
    }
    return result;
  }

  bool _isBeforeMonth(DateTime date, DateTime month) {
    return date.year < month.year ||
      (date.year == month.year && date.month < month.month);
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  double getTotalIncomeForMonth(DateTime month) {
    return getIncomesForMonth(month).fold(0.0, (sum, i) => sum + i.amount);
  }
}
