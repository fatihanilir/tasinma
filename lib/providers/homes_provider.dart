import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/home_model.dart';
import '../models/cost_item.dart';
import '../services/local_storage_service.dart';
import '../services/database_service.dart';

class HomesProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  final DatabaseService _databaseService = DatabaseService();

  List<HomeModel> _homes = [];
  HomeModel? _currentHome;
  bool _isLoading = false;
  String? _errorMessage;
  bool _useCloud = false;
  StreamSubscription? _homesSub;

  List<HomeModel> get homes => _homes;
  HomeModel? get currentHome => _currentHome;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get useCloud => _useCloud;

  HomeModel _tempHome = HomeModel();
  HomeModel get tempHome => _tempHome;

  void setCloudMode(bool useCloud) {
    if (_useCloud == useCloud) return;
    _useCloud = useCloud;
    stopListening();
    startListening();
  }

  void startListening() {
    if (_useCloud) {
      _homesSub?.cancel();
      _homesSub = _databaseService.getHomesStream().listen((homes) {
        _homes = homes;
        notifyListeners();
      }, onError: (_) {
        _errorMessage = 'Veriler yüklenemedi';
        notifyListeners();
      });
    } else {
      _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      _homes = await _localStorageService.getHomes();
      _homes.sort((a, b) => a.order.compareTo(b.order));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Veriler yüklenemedi';
      notifyListeners();
    }
  }

  void stopListening() {
    _homesSub?.cancel();
    _homesSub = null;
  }

  void updateTempHome({
    String? title,
    String? link,
    double? price,
    double? cash,
    double? reno,
    double? commRate,
    double? taxRate,
    double? interestRate,
    int? term1,
    int? term2,
  }) {
    _tempHome = _tempHome.copyWith(
      title: title,
      link: link,
      price: price,
      cash: cash,
      reno: reno,
      commRate: commRate,
      taxRate: taxRate,
      interestRate: interestRate,
      term1: term1,
      term2: term2,
    );
    notifyListeners();
  }

  void addCost(CostItem cost) {
    final existingIndex = _tempHome.additionalCosts.indexWhere((c) => c.id == cost.id);
    final updatedCosts = List<CostItem>.from(_tempHome.additionalCosts);
    if (existingIndex >= 0) {
      updatedCosts[existingIndex] = cost;
    } else {
      updatedCosts.add(cost);
    }
    _tempHome = _tempHome.copyWith(additionalCosts: updatedCosts);
    notifyListeners();
  }

  void removeCost(String costId) {
    final updatedCosts = _tempHome.additionalCosts.where((c) => c.id != costId).toList();
    _tempHome = _tempHome.copyWith(additionalCosts: updatedCosts);
    notifyListeners();
  }

  void updateCostAmount(String costId, double amount) {
    final updatedCosts = _tempHome.additionalCosts.map((c) {
      if (c.id == costId) return c.copyWith(amount: amount);
      return c;
    }).toList();
    _tempHome = _tempHome.copyWith(additionalCosts: updatedCosts);
    notifyListeners();
  }

  void selectHomeForEdit(HomeModel? home) {
    _currentHome = home;
    if (home != null) {
      _tempHome = home;
    } else {
      _tempHome = HomeModel(cash: _tempHome.cash);
    }
    notifyListeners();
  }

  void resetForm() {
    _currentHome = null;
    _tempHome = HomeModel(cash: _tempHome.cash);
    notifyListeners();
  }

  Future<bool> saveCurrentHome() async {
    if (_tempHome.price <= 0) {
      _errorMessage = 'Önce ev fiyatını gir';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      var homeToSave = _tempHome;
      if (homeToSave.title.isEmpty) {
        homeToSave = homeToSave.copyWith(
          title: '${homeToSave.price.round()} TL',
        );
      }

      // İlan linkini normalize et (https ekle)
      if (homeToSave.link.trim().isNotEmpty) {
        homeToSave = homeToSave.copyWith(link: homeToSave.normalizedLink);
      }

      final newOrder = _currentHome != null ? _currentHome!.order : 0;

      if (_currentHome == null) {
        for (int i = 0; i < _homes.length; i++) {
          _homes[i] = _homes[i].copyWith(order: _homes[i].order + 1);
        }
      }

      homeToSave = homeToSave.copyWith(order: newOrder, savedAt: DateTime.now());

      if (_useCloud) {
        if (_currentHome == null) {
          for (final home in _homes) {
            await _databaseService.saveHome(home.copyWith(order: home.order + 1));
          }
        }
        await _databaseService.saveHome(homeToSave);
      } else {
        final existingIndex = _homes.indexWhere((h) => h.id == homeToSave.id);
        if (existingIndex >= 0) {
          _homes[existingIndex] = homeToSave;
        } else {
          _homes.insert(0, homeToSave);
        }
        _homes.sort((a, b) => a.order.compareTo(b.order));
        await _localStorageService.saveHomes(_homes);
      }

      _currentHome = null;
      _tempHome = HomeModel(cash: _tempHome.cash);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Kaydedilemedi, tekrar dene';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHome(String homeId) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_useCloud) {
        await _databaseService.deleteHome(homeId);
      } else {
        _homes.removeWhere((h) => h.id == homeId);
        await _localStorageService.saveHomes(_homes);
      }

      if (_currentHome?.id == homeId) {
        _currentHome = null;
        _tempHome = HomeModel(cash: _tempHome.cash);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Silinemedi';
      notifyListeners();
      return false;
    }
  }

  Future<void> moveHome(String homeId, int direction) async {
    final index = _homes.indexWhere((h) => h.id == homeId);
    if (index < 0) return;

    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _homes.length) return;

    final home = _homes.removeAt(index);
    _homes.insert(newIndex, home);

    for (int i = 0; i < _homes.length; i++) {
      _homes[i] = _homes[i].copyWith(order: i);
    }

    notifyListeners();

    try {
      if (_useCloud) {
        await _databaseService.updateOrder(_homes);
      } else {
        await _localStorageService.saveHomes(_homes);
      }
    } catch (e) {
      _errorMessage = 'Sıralama güncellenemedi';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
