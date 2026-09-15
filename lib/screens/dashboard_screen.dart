import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/document_item.dart';
import '../models/bill_item.dart';
import '../models/vehicle_item.dart';
import '../services/task_storage_service.dart';
import '../services/document_storage_service.dart';
import '../services/bill_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import 'vehicles_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskStorageService _taskService = TaskStorageService();
  final DocumentStorageService _docService = DocumentStorageService();
  final BillStorageService _billService = BillStorageService();
  final VehicleStorageService _vehicleService = VehicleStorageService();

  List<Task> _tasks = [];
  List<DocumentItem> _documents = [];
  List<BillItem> _bills = [];
  List<VehicleItem> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final tasks = await _taskService.loadTasks();
    final docs = await _docService.loadDocuments();
    final bills = await _billService.loadBills();
    final vehicles = await _vehicleService.loadVehicles();

    if (mounted) {
      setState(() {
        _tasks = tasks;
        _documents = docs;
        _bills = bills;
        _vehicles = vehicles;
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

  int get _urgentVehicleAlertsCount {
    final now = DateTime.now();
    int count = 0;
    for (final v in _vehicles) {
      if (v.insuranceExpiry != null) {
        final diff = v.insuranceExpiry!.difference(now).inDays;
        if (diff >= 0 && diff <= 15) count++;
      }
      if (v.pucExpiry != null) {
        final diff = v.pucExpiry!.difference(now).inDays;
        if (diff >= 0 && diff <= 15) count++;
      }
    }
    return count;
  }

  double get _monthlyCommitment {
    return _bills.fold(0.0, (sum, bill) {
      if (bill.cycle == BillingCycle.monthly) {
        return sum + bill.amount;
      } else {
        return sum + (bill.amount / 12);
      }
    });
  }

  int get _calculatedLifeScore {
    if (_tasks.isEmpty && _documents.isEmpty && _bills.isEmpty && _vehicles.isEmpty) {
      return 75;
    }
    int score = 80;
    if (_pendingTasksCount > 5) score -= 10;
    if (_expiringDocsCount > 0) score -= 15;
    if (_urgentVehicleAlertsCount > 0) score -= 10;

    final completedCount = _tasks.where((t) => t.isCompleted).length;
    if (_tasks.isNotEmpty) {
      score += ((completedCount / _tasks.length) * 20).toInt();
    }
    return score.clamp(20, 100);
  }

  String _generateAiInsight() {
    if (_urgentVehicleAlertsCount > 0) {
      return 'Vehicle alert: You have $_urgentVehicleAlertsCount insurance/PUC renewal(s) due within 15 days.';
    }
    if (_expiringDocsCount > 0) {
      return 'Action required: $_expiringDocsCount document(s) expiring within 30 days.';
    }
    if (_monthlyCommitment > 15000) {
      return 'Monthly recurring commitments are ₹${_monthlyCommitment.toStringAsFixed(0)}. Review unused subscriptions.';
    }
    if (_pendingTasksCount > 3) {
      return 'You have $_pendingTasksCount pending tasks. Focus on high-priority items.';
    }
    return 'Your Life OS records are organized and on track.';
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
            // Life Score Card
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
                leading: Icon(Icons.auto_awesome, color: Colors.amber.shade900),
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

            // 3-Metric Overview Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.blue, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '$_pendingTasksCount',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const Text('Tasks Due', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_expiringDocsCount',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _expiringDocsCount > 0 ? Colors.red : Colors.black,
                            ),
                          ),
                          const Text('Expiring Docs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.credit_card, color: Colors.indigo, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_monthlyCommitment.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text('Monthly Outflow', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle Hub Direct Access Tile
            Card(
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _urgentVehicleAlertsCount > 0
                      ? Colors.red.shade100
                      : Colors.teal.shade100,
                  child: Icon(
                    Icons.directions_car_filled_outlined,
                    color: _urgentVehicleAlertsCount > 0 ? Colors.red : Colors.teal,
                  ),
                ),
                title: const Text('Vehicle Hub', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_urgentVehicleAlertsCount > 0
                    ? '$_urgentVehicleAlertsCount urgent renewal alert(s)'
                    : '${_vehicles.length} vehicle(s) tracked'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VehiclesScreen()),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}