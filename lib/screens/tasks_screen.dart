// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_storage_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskStorageService _storageService = TaskStorageService();
  final TextEditingController _taskController = TextEditingController();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final loaded = await _storageService.loadTasks();
    setState(() {
      _tasks = loaded;
      _isLoading = false;
    });
  }

  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) return;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
    );

    setState(() {
      _tasks.insert(0, newTask); // Add newest to the top
    });
    _taskController.clear();
    await _storageService.saveTasks(_tasks);
  }

  Future<void> _toggleTaskCompletion(int index) async {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
    });
    await _storageService.saveTasks(_tasks);
  }

  Future<void> _deleteTask(String id) async {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    await _storageService.saveTasks(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks - Life OS'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Add a new task...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addTask,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 36),
                  onPressed: () => _addTask(_taskController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks recorded yet.'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (_) => _toggleTaskCompletion(index),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTask(task.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}