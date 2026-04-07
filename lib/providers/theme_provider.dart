import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  bool _isDarkMode;
  Color _accentColor;
  bool _isMonochrome;

  static const List<Color> accentOptions = [
    Color(0xFF7F5AF0), // Purple (default)
    Color(0xFF2CB67D), // Green
    Color(0xFFE53935), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
  ];

  static const Color monochromeAccent = Color(0xFF6B6B6B);

  ThemeProvider(this._storage)
      : _isDarkMode = _storage.isDarkMode(),
        _accentColor = Color(_storage.getAccentColor() ?? 0xFF7F5AF0),
        _isMonochrome = _storage.getMonochrome() ?? false;

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _isMonochrome ? monochromeAccent : _accentColor;
  Color get rawAccentColor => _accentColor;
  bool get isMonochrome => _isMonochrome;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _storage.setDarkMode(_isDarkMode);
      notifyListeners();
    }
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _storage.setAccentColor(color.toARGB32());
    notifyListeners();
  }

  void setMonochrome(bool value) {
    _isMonochrome = value;
    _storage.setMonochrome(value);
    notifyListeners();
  }
}
