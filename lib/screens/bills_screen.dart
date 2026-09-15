import 'package:flutter/material.dart';
import '../models/bill_item.dart';
import '../services/bill_storage_service.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final BillStorageService _storageService = BillStorageService();
  List<BillItem> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final loaded = await _storageService.loadBills();
    setState(() {
      _bills = loaded;
      _isLoading = false;
    });
  }

  double get _totalMonthlySpend {
    return _bills.fold(0.0, (sum, bill) {
      if (bill.cycle == BillingCycle.monthly) {
        return sum + bill.amount;
      } else {
        return sum + (bill.amount / 12);
      }
    });
  }

  Future<void> _addBill(
    String title,
    double amount,
    BillCategory category,
    BillingCycle cycle,
    int dueDay,
    bool autoPay,
  ) async {
    final newBill = BillItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      amount: amount,
      category: category,
      cycle: cycle,
      dueDayOfMonth: dueDay,
      isAutoPay: autoPay,
    );

    setState(() {
      _bills.insert(0, newBill);
    });
    await _storageService.saveBills(_bills);
  }

  Future<void> _deleteBill(String id) async {
    setState(() {
      _bills.removeWhere((b) => b.id == id);
    });
    await _storageService.saveBills(_bills);
  }

  void _showAddBillSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final dayController = TextEditingController(text: '5');
    BillCategory selectedCategory = BillCategory.subscription;
    BillingCycle selectedCycle = BillingCycle.monthly;
    bool autoPay = false;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Track Bill or Subscription',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Name (e.g., Netflix, Internet, Rent)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: 'Amount (e.g., 649)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dayController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Due Day (1-31)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<BillCategory>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: BillCategory.values.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<BillingCycle>(
                          initialValue: selectedCycle,
                          decoration: const InputDecoration(
                            labelText: 'Cycle',
                            border: OutlineInputBorder(),
                          ),
                          items: BillingCycle.values.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCycle = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-pay Enabled'),
                    value: autoPay,
                    onChanged: (val) => setModalState(() => autoPay = val),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        final day = int.tryParse(dayController.text.trim()) ?? 1;
                        if (titleController.text.trim().isNotEmpty && amt > 0) {
                          _addBill(
                            titleController.text,
                            amt,
                            selectedCategory,
                            selectedCycle,
                            day.clamp(1, 31),
                            autoPay,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save Commitment'),
                    ),
                  ),
                ],
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & Subs - Life OS'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBillSheet,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Total Monthly Outflow Header
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, size: 36, color: Colors.indigo),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Commitment',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_totalMonthlySpend.toStringAsFixed(0)} / mo',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _bills.isEmpty
                ? const Center(child: Text('No recurring bills or subscriptions added.'))
                : ListView.builder(
                    itemCount: _bills.length,
                    itemBuilder: (context, index) {
                      final bill = _bills[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: const Icon(Icons.payment, color: Colors.indigo),
                          ),
                          title: Text(
                            bill.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Due on day ${bill.dueDayOfMonth} • ${bill.cycle.name.toUpperCase()}${bill.isAutoPay ? ' • Auto-Pay' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${bill.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteBill(bill.id),
                              ),
                            ],
                          ),
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