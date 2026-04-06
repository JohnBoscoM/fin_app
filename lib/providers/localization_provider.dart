import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class LocalizationProvider extends ChangeNotifier {
  Locale _locale;
  final StorageService _storage;

  LocalizationProvider(Locale initialLocale, this._storage)
      : _locale = initialLocale;

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      _storage.setLanguage(newLocale.languageCode);
      notifyListeners();
    }
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('sv', 'SE'));
    } else {
      setLocale(const Locale('en', 'US'));
    }
  }
}
