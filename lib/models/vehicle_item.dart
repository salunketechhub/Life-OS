enum VehicleType { twoWheeler, fourWheeler, other }

class VehicleItem {
  final String id;
  final String name; // e.g. "Royal Enfield Hunter" or "Honda City"
  final String registrationNumber; // e.g. "MH 12 AB 1234"
  final VehicleType type;
  final DateTime? insuranceExpiry;
  final DateTime? pucExpiry;
  final DateTime? nextServiceDate;

  VehicleItem({
    required this.id,
    required this.name,
    required this.registrationNumber,
    this.type = VehicleType.twoWheeler,
    this.insuranceExpiry,
    this.pucExpiry,
    this.nextServiceDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'registrationNumber': registrationNumber,
      'type': type.name,
      'insuranceExpiry': insuranceExpiry?.toIso8601String(),
      'pucExpiry': pucExpiry?.toIso8601String(),
      'nextServiceDate': nextServiceDate?.toIso8601String(),
    };
  }

  factory VehicleItem.fromJson(Map<String, dynamic> json) {
    return VehicleItem(
      id: json['id'] as String,
      name: json['name'] as String,
      registrationNumber: json['registrationNumber'] as String? ?? '',
      type: VehicleType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => VehicleType.twoWheeler,
      ),
      insuranceExpiry: json['insuranceExpiry'] != null
          ? DateTime.parse(json['insuranceExpiry'])
          : null,
      pucExpiry: json['pucExpiry'] != null
          ? DateTime.parse(json['pucExpiry'])
          : null,
      nextServiceDate: json['nextServiceDate'] != null
          ? DateTime.parse(json['nextServiceDate'])
          : null,
    );
  }
}