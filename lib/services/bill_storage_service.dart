import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_item.dart';

class BillStorageService {
  static const String _billsKey = 'life_os_bills';

  Future<List<BillItem>> loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final String? billsJson = prefs.getString(_billsKey);

    if (billsJson == null || billsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(billsJson);
      return decodedList
          .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBills(List<BillItem> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> rawList =
        bills.map((b) => b.toJson()).toList();
    await prefs.setString(_billsKey, jsonEncode(rawList));
  }
}