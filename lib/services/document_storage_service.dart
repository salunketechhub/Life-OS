import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_item.dart';

class DocumentStorageService {
  static const String _docsKey = 'life_os_documents';

  Future<List<DocumentItem>> loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? docsJson = prefs.getString(_docsKey);

    if (docsJson == null || docsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(docsJson);
      return decodedList
          .map((item) => DocumentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDocuments(List<DocumentItem> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> rawList =
        docs.map((d) => d.toJson()).toList();
    await prefs.setString(_docsKey, jsonEncode(rawList));
  }
}