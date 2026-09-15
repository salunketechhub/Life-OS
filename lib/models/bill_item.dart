enum BillCategory { utility, subscription, credit, insurance, other }

enum BillingCycle { monthly, yearly }

class BillItem {
  final String id;
  final String title;
  final double amount;
  final BillCategory category;
  final BillingCycle cycle;
  final int dueDayOfMonth; // 1 - 31
  final bool isAutoPay;

  BillItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.cycle = BillingCycle.monthly,
    required this.dueDayOfMonth,
    this.isAutoPay = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'cycle': cycle.name,
      'dueDayOfMonth': dueDayOfMonth,
      'isAutoPay': isAutoPay,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: BillCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => BillCategory.subscription,
      ),
      cycle: BillingCycle.values.firstWhere(
        (c) => c.name == json['cycle'],
        orElse: () => BillingCycle.monthly,
      ),
      dueDayOfMonth: json['dueDayOfMonth'] as int? ?? 1,
      isAutoPay: json['isAutoPay'] as bool? ?? false,
    );
  }
}