import 'package:flutter/material.dart';
import '../models/vehicle_item.dart';
import '../services/vehicle_storage_service.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final VehicleStorageService _storageService = VehicleStorageService();
  List<VehicleItem> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final loaded = await _storageService.loadVehicles();
    setState(() {
      _vehicles = loaded;
      _isLoading = false;
    });
  }

  Future<void> _addVehicle(
    String name,
    String regNum,
    VehicleType type,
    DateTime? insurance,
    DateTime? puc,
    DateTime? service,
  ) async {
    final vehicle = VehicleItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      registrationNumber: regNum.trim(),
      type: type,
      insuranceExpiry: insurance,
      pucExpiry: puc,
      nextServiceDate: service,
    );

    setState(() {
      _vehicles.insert(0, vehicle);
    });
    await _storageService.saveVehicles(_vehicles);
  }

  Future<void> _deleteVehicle(String id) async {
    setState(() {
      _vehicles.removeWhere((v) => v.id == id);
    });
    await _storageService.saveVehicles(_vehicles);
  }

  bool _isUrgent(DateTime? date) {
    if (date == null) return false;
    final diff = date.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 15;
  }

  void _showAddVehicleSheet() {
    final nameController = TextEditingController();
    final regController = TextEditingController();
    VehicleType selectedType = VehicleType.twoWheeler;
    DateTime? insDate;
    DateTime? pucDate;
    DateTime? serviceDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Vehicle Record',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Vehicle Model (e.g. Hunter 350, Swift)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: regController,
                      decoration: const InputDecoration(
                        hintText: 'Registration Number (e.g. MH 12 AB 1234)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VehicleType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: VehicleType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.name == 'twoWheeler'
                              ? '2 Wheeler'
                              : t.name == 'fourWheeler'
                                  ? '4 Wheeler'
                                  : 'Other'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.shield_outlined),
                      title: Text(insDate == null
                          ? 'Set Insurance Expiry'
                          : 'Insurance: ${insDate!.day}/${insDate!.month}/${insDate!.year}'),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setModalState(() => insDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.speed),
                      title: Text(pucDate == null
                          ? 'Set PUC Expiry'
                          : 'PUC: ${pucDate!.day}/${pucDate!.month}/${pucDate!.year}'),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setModalState(() => pucDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            _addVehicle(
                              nameController.text,
                              regController.text,
                              selectedType,
                              insDate,
                              pucDate,
                              serviceDate,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Save Vehicle'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Hub - Life OS')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleSheet,
        child: const Icon(Icons.add),
      ),
      body: _vehicles.isEmpty
          ? const Center(child: Text('No vehicles tracked yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final v = _vehicles[index];
                final insUrgent = _isUrgent(v.insuranceExpiry);
                final pucUrgent = _isUrgent(v.pucExpiry);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              v.type == VehicleType.twoWheeler
                                  ? Icons.two_wheeler
                                  : Icons.directions_car,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (v.registrationNumber.isNotEmpty)
                                    Text(
                                      v.registrationNumber,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteVehicle(v.id),
                            ),
                          ],
                        ),
                        const Divider(),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (v.insuranceExpiry != null)
                              Chip(
                                avatar: const Icon(Icons.shield, size: 14),
                                label: Text(
                                  'Ins: ${v.insuranceExpiry!.day}/${v.insuranceExpiry!.month}/${v.insuranceExpiry!.year}',
                                  style: TextStyle(
                                    color: insUrgent ? Colors.red : null,
                                    fontWeight: insUrgent ? FontWeight.bold : null,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (v.pucExpiry != null)
                              Chip(
                                avatar: const Icon(Icons.eco, size: 14),
                                label: Text(
                                  'PUC: ${v.pucExpiry!.day}/${v.pucExpiry!.month}/${v.pucExpiry!.year}',
                                  style: TextStyle(
                                    color: pucUrgent ? Colors.red : null,
                                    fontWeight: pucUrgent ? FontWeight.bold : null,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}