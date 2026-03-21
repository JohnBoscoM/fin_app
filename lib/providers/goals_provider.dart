import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/storage_service.dart';

class GoalsProvider extends ChangeNotifier {
  final StorageService _storage;
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;

  GoalsProvider(this._storage);

  List<SavingsGoal> get goals => _goals;
  bool get isLoading => _isLoading;

  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();
    
    _goals = await _storage.getGoals();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    _goals.add(goal);
    await _storage.saveGoals(_goals);
    notifyListeners();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      await _storage.saveGoals(_goals);
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    await _storage.saveGoals(_goals);
    notifyListeners();
  }

  Future<void> addFundsToGoal(String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount + amount,
      );
      _goals[index] = updatedGoal;
      await _storage.saveGoals(_goals);
      notifyListeners();
    }
  }

  double getTotalSavingsTarget() {
    return _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
  }

  double getTotalSavingsCurrent() {
    return _goals.fold(0.0, (sum, g) => sum + g.currentAmount);
  }
}
