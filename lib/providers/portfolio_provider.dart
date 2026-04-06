import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/storage_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final StorageService _storage;
  List<Asset> _assets = [];
  bool _isLoading = false;

  PortfolioProvider(this._storage);

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;

  Future<void> loadAssets() async {
    _isLoading = true;
    notifyListeners();

    _assets = await _storage.getAssets();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAsset(Asset asset) async {
    _assets.add(asset);
    await _storage.saveAssets(_assets);
    notifyListeners();
  }

  Future<void> updateAsset(Asset asset) async {
    final index = _assets.indexWhere((a) => a.id == asset.id);
    if (index != -1) {
      _assets[index] = asset;
      await _storage.saveAssets(_assets);
      notifyListeners();
    }
  }

  Future<void> deleteAsset(String id) async {
    _assets.removeWhere((a) => a.id == id);
    await _storage.saveAssets(_assets);
    notifyListeners();
  }

  double getTotalPortfolioValue() {
    return _assets.fold(0.0, (sum, a) => sum + a.currentValue);
  }

  double getTotalPurchaseValue() {
    return _assets.fold(0.0, (sum, a) => sum + a.purchaseValue);
  }

  double getTotalGainLoss() {
    return getTotalPortfolioValue() - getTotalPurchaseValue();
  }

  double getTotalGainLossPercent() {
    final purchase = getTotalPurchaseValue();
    if (purchase == 0) return 0;
    return (getTotalGainLoss() / purchase) * 100;
  }

  Map<AssetType, List<Asset>> getAssetsByType() {
    final map = <AssetType, List<Asset>>{};
    for (final asset in _assets) {
      map.putIfAbsent(asset.type, () => []).add(asset);
    }
    return map;
  }

  Map<String, double> getAllocationPercentages() {
    final total = getTotalPortfolioValue();
    if (total == 0) return {};
    final map = <String, double>{};
    for (final asset in _assets) {
      final key = asset.type.displayName;
      map[key] = (map[key] ?? 0) + asset.currentValue;
    }
    return map.map((key, value) => MapEntry(key, (value / total) * 100));
  }
}
