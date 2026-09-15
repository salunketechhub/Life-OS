import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_item.dart';

class VehicleStorageService {
  static const String _vehiclesKey = 'life_os_vehicles';

  Future<List<VehicleItem>> loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_vehiclesKey);

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((item) => VehicleItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveVehicles(List<VehicleItem> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> rawList =
        vehicles.map((v) => v.toJson()).toList();
    await prefs.setString(_vehiclesKey, jsonEncode(rawList));
  }
}