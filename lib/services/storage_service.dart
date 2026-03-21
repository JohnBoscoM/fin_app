import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';

class StorageService {
  static const String _expensesKey = 'budget_expenses';
  static const String _incomesKey = 'budget_incomes';
  static const String _goalsKey = 'budget_goals';
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Expense operations
  Future<List<Expense>> getExpenses() async {
    final jsonString = _prefs.getString(_expensesKey);
    if (jsonString == null) return [];
    
    final list = jsonDecode(jsonString) as List;
    return list.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final jsonString = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await _prefs.setString(_expensesKey, jsonString);
  }

  // Income operations
  Future<List<Income>> getIncomes() async {
    final jsonString = _prefs.getString(_incomesKey);
    if (jsonString == null) return [];
    
    final list = jsonDecode(jsonString) as List;
    return list.map((e) => Income.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveIncomes(List<Income> incomes) async {
    final jsonString = jsonEncode(incomes.map((e) => e.toJson()).toList());
    await _prefs.setString(_incomesKey, jsonString);
  }

  // Goals operations
  Future<List<SavingsGoal>> getGoals() async {
    final jsonString = _prefs.getString(_goalsKey);
    if (jsonString == null) return [];
    
    final list = jsonDecode(jsonString) as List;
    return list.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveGoals(List<SavingsGoal> goals) async {
    final jsonString = jsonEncode(goals.map((e) => e.toJson()).toList());
    await _prefs.setString(_goalsKey, jsonString);
  }

  // Language preference
  String? getLanguage() {
    return _prefs.getString(_languageKey);
  }

  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  // Theme preference
  bool isDarkMode() {
    return _prefs.getBool(_themeKey) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  // Utility functions
  Future<double> getTotalExpenses() async {
    final List<Expense> expenses = await getExpenses();
    return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  Future<double> getTotalIncome() async {
    final List<Income> incomes = await getIncomes();
    return incomes.fold<double>(0.0, (double sum, Income income) => sum + income.amount);
  }

  Future<double> getMonthlySavings() async {
    final totalIncome = await getTotalIncome();
    final totalExpenses = await getTotalExpenses();
    return totalIncome - totalExpenses;
  }

  Future<void> clearAllData() async {
    await _prefs.remove(_expensesKey);
    await _prefs.remove(_incomesKey);
    await _prefs.remove(_goalsKey);
  }
}
