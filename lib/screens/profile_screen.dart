import 'package:flutter/material.dart';
import '../main.dart';
import '../services/task_storage_service.dart';
import '../services/document_storage_service.dart';
import '../services/bill_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import 'package:flutter/services.dart';
import '../services/backup_service.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _taskCount = 0;
  int _docCount = 0;
  int _billCount = 0;
  int _vehicleCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    final tasks = await TaskStorageService().loadTasks();
    final docs = await DocumentStorageService().loadDocuments();
    final bills = await BillStorageService().loadBills();
    final vehicles = await VehicleStorageService().loadVehicles();

    if (mounted) {
      setState(() {
        _taskCount = tasks.length;
        _docCount = docs.length;
        _billCount = bills.length;
        _vehicleCount = vehicles.length;
        _isLoading = false;
      });
    }
  }

  void _handleBackupExport() async {
  final backupService = BackupService();
  final jsonPayload = await backupService.generateBackupJson();

  if (!mounted) return;

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Life OS Backup Export'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All tasks, documents, bills, and vehicles packaged as JSON:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  jsonPayload,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy JSON'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonPayload));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup JSON copied to clipboard')),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}
  void _showEmergencySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.emergency, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              const ListTile(
                dense: true,
                leading: Icon(Icons.bloodtype, color: Colors.redAccent),
                title: Text('Blood Group'),
                subtitle: Text('Not Set (Update in Profile settings)'),
              ),
              const ListTile(
                dense: true,
                leading: Icon(Icons.contact_phone, color: Colors.green),
                title: Text('Primary Emergency Contact'),
                subtitle: Text('Family / Close Guardian'),
              ),
              const ListTile(
                dense: true,
                leading: Icon(Icons.local_hospital, color: Colors.blue),
                title: Text('Medical Conditions / Allergies'),
                subtitle: Text('None recorded'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings - Life OS'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // User Banner Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, size: 36, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Life OS Member',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Personal Edition • Local Storage Active',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Mode Card
                Card(
                  color: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.health_and_safety, color: Colors.red, size: 30),
                    title: const Text(
                      'Emergency Mode',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    subtitle: const Text('One-tap medical information & SOS contacts'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                    onTap: _showEmergencySheet,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Preferences & Theme',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                //storage doagnosis
                const SizedBox(height: 20),
                const Text(
                  'Data Ownership',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download_for_offline, color: Colors.deepPurple),
                    title: const Text('Export Complete Life OS Backup'),
                    subtitle: const Text('Export all modules as JSON for personal custody'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _handleBackupExport,
                  ),
                ),
                Card(
                  child: SwitchListTile(
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? Colors.amber : Colors.blueGrey,
                    ),
                    title: const Text('Dark Theme'),
                    subtitle: Text(isDark ? 'Dark mode enabled' : 'Light mode enabled'),
                    value: isDark,
                    onChanged: (bool value) {
                      setState(() {
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Storage Diagnostics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.task_alt, color: Colors.purple),
                        title: const Text('Stored Tasks'),
                        trailing: Text(
                          '$_taskCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder, color: Colors.blue),
                        title: const Text('Vaulted Documents'),
                        trailing: Text(
                          '$_docCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                        title: const Text('Tracked Recurring Bills'),
                        trailing: Text(
                          '$_billCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.directions_car, color: Colors.teal),
                        title: const Text('Tracked Vehicles'),
                        trailing: Text(
                          '$_vehicleCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}