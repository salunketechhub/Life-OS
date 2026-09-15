enum DocumentCategory {
  personal,   // Aadhaar, PAN, Passport, Voter ID
  financial,  // Insurance, Tax Returns, Loans
  vehicle,    // RC, Driving License, PUC
  education,  // Degrees, Transcripts, Certificates
  property,   // Rent Agreements, Deed, Tax Receipts
}

class DocumentItem {
  final String id;
  final String title;
  final String documentNumber;
  final DocumentCategory category;
  final DateTime? expiryDate;
  final String? notes;

  DocumentItem({
    required this.id,
    required this.title,
    required this.documentNumber,
    required this.category,
    this.expiryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'documentNumber': documentNumber,
      'category': category.name,
      'expiryDate': expiryDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      documentNumber: json['documentNumber'] as String? ?? '',
      category: DocumentCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DocumentCategory.personal,
      ),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      notes: json['notes'] as String?,
    );
  }
}