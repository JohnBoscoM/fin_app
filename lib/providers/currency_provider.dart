import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final bool symbolAfter;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    this.symbolAfter = false,
  });
}

class CurrencyProvider extends ChangeNotifier {
  final StorageService _storage;

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyInfo(code: 'SEK', symbol: 'kr', name: 'Swedish Krona', symbolAfter: true),
    CurrencyInfo(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone', symbolAfter: true),
    CurrencyInfo(code: 'DKK', symbol: 'kr', name: 'Danish Krone', symbolAfter: true),
    CurrencyInfo(code: 'ISK', symbol: 'kr', name: 'Icelandic Króna', symbolAfter: true),
    CurrencyInfo(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
    CurrencyInfo(code: 'PLN', symbol: 'zł', name: 'Polish Złoty'),
    CurrencyInfo(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna'),
    CurrencyInfo(code: 'HUF', symbol: 'Ft', name: 'Hungarian Forint'),
    CurrencyInfo(code: 'RON', symbol: 'lei', name: 'Romanian Leu'),
    CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
    CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyInfo(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
  ];

  late String _currencyCode;

  CurrencyProvider(this._storage) {
    _currencyCode = _storage.getCurrency() ?? 'USD';
  }

  String get currencyCode => _currencyCode;

  CurrencyInfo get current =>
      supportedCurrencies.firstWhere(
        (c) => c.code == _currencyCode,
        orElse: () => supportedCurrencies.first,
      );

  void setCurrency(String code) {
    if (_currencyCode != code) {
      _currencyCode = code;
      _storage.setCurrency(code);
      notifyListeners();
    }
  }

  String format(double amount, {int decimalDigits = 0, String? locale}) {
    if (current.symbolAfter) {
      final formatted = NumberFormat.currency(
        locale: locale,
        symbol: '',
        decimalDigits: decimalDigits,
      ).format(amount).trimRight();
      return '$formatted${current.symbol}';
    }
    return NumberFormat.currency(
      locale: locale,
      symbol: current.symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }
}
