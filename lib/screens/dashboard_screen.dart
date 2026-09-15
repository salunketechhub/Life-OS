import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/document_item.dart';
import '../services/task_storage_service.dart';
import '../services/document_storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskStorageService _taskService = TaskStorageService();
  final DocumentStorageService _docService = DocumentStorageService();

  List<Task> _tasks = [];
  List<DocumentItem> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final tasks = await _taskService.loadTasks();
    final docs = await _docService.loadDocuments();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  int get _pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;

  int get _expiringDocsCount {
    final now = DateTime.now();
    return _documents.where((d) {
      if (d.expiryDate == null) return false;
      final diff = d.expiryDate!.difference(now).inDays;
      return diff >= 0 && diff <= 30;
    }).length;
  }

  int get _calculatedLifeScore {
    if (_tasks.isEmpty && _documents.isEmpty) return 70;
    int score = 80;
    if (_pendingTasksCount > 5) score -= 10;
    if (_expiringDocsCount > 0) score -= 15;
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    if (_tasks.isNotEmpty) {
      score += ((completedCount / _tasks.length) * 20).toInt();
    }
    return score.clamp(20, 100);
  }

  String _generateAiInsight() {
    if (_expiringDocsCount > 0) {
      return 'Action required: You have $_expiringDocsCount document(s) expiring within 30 days.';
    }
    if (_pendingTasksCount > 3) {
      return 'You have $_pendingTasksCount pending tasks. Focus on high-priority items today.';
    }
    if (_tasks.isNotEmpty && _pendingTasksCount == 0) {
      return 'All caught up! Great job maintaining your tasks today.';
    }
    return 'Your Life OS is healthy. Add new goals and track your assets regularly.';
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
        title: const Text('Life OS Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting & Score Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Life Score: $_calculatedLifeScore/100',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircularProgressIndicator(
                      value: _calculatedLifeScore / 100,
                      strokeWidth: 6,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Insight Banner
            Card(
              elevation: 0,
              color: Colors.amber.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.amber),
                title: const Text('AI Insight', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_generateAiInsight()),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Live Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Metric Cards Grid
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.blue, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$_pendingTasksCount',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Tasks Pending', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: _expiringDocsCount > 0 ? Colors.red : Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_expiringDocsCount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _expiringDocsCount > 0 ? Colors.red : Colors.black,
                            ),
                          ),
                          const Text('Expiring Docs', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.folder_shared_outlined, color: Colors.purple),
                title: const Text('Total Documents Vaulted'),
                trailing: Text(
                  '${_documents.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}