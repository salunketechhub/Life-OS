import 'dart:convert';
import 'task_storage_service.dart';
import 'document_storage_service.dart';
import 'bill_storage_service.dart';
import 'vehicle_storage_service.dart';

class BackupService {
  final TaskStorageService _taskService = TaskStorageService();
  final DocumentStorageService _docService = DocumentStorageService();
  final BillStorageService _billService = BillStorageService();
  final VehicleStorageService _vehicleService = VehicleStorageService();

  Future<String> generateBackupJson() async {
    final tasks = await _taskService.loadTasks();
    final docs = await _docService.loadDocuments();
    final bills = await _billService.loadBills();
    final vehicles = await _vehicleService.loadVehicles();

    final Map<String, dynamic> backupData = {
      'app': 'Life OS',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'documents': docs.map((d) => d.toJson()).toList(),
        'bills': bills.map((b) => b.toJson()).toList(),
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
      },
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }
}