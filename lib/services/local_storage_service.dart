import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_model.dart';

class LocalStorageService {
  static const String _homesKey = 'ev_hesap_homes';

  Future<List<HomeModel>> getHomes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_homesKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => HomeModel.fromJson(j)).toList();
    } catch (e) {
      print('LocalStorage getHomes error: $e');
      return [];
    }
  }

  Future<void> saveHomes(List<HomeModel> homes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = homes.map((h) => h.toJson()).toList();
      await prefs.setString(_homesKey, json.encode(jsonList));
    } catch (e) {
      print('LocalStorage saveHomes error: $e');
    }
  }

  Future<void> addHome(HomeModel home) async {
    final homes = await getHomes();
    // Aynı ID varsa güncelle, yoksa ekle
    final index = homes.indexWhere((h) => h.id == home.id);
    if (index >= 0) {
      homes[index] = home;
    } else {
      homes.insert(0, home);
    }
    await saveHomes(homes);
  }

  Future<void> deleteHome(String homeId) async {
    final homes = await getHomes();
    homes.removeWhere((h) => h.id == homeId);
    await saveHomes(homes);
  }

  Future<void> updateOrder(List<HomeModel> homes) async {
    final updatedHomes = homes.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();
    await saveHomes(updatedHomes);
  }
}
