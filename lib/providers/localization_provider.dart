import 'package:flutter/material.dart';

class LocalizationProvider extends ChangeNotifier {
  Locale _locale;
  
  LocalizationProvider(Locale initialLocale) : _locale = initialLocale;

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
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
