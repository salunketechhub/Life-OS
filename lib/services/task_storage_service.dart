import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskStorageService {
  static const String _tasksKey = 'life_os_tasks';

  // Load tasks from SharedPreferences
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_tasksKey);

    if (tasksJson == null || tasksJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(tasksJson);
      return decodedList
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Save tasks to SharedPreferences
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> rawList =
        tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(rawList));
  }
}