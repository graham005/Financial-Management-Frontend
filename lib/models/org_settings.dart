import 'dart:convert';

class OrganizationSettings {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? logoUrl;
  final String defaultPrinterId;
  final String defaultPaperSize; // 'mm58' | 'mm80'
  final String receiptTemplate; // template text (simple handlebars-like)

  const OrganizationSettings({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.logoUrl,
    this.defaultPrinterId = '',
    this.defaultPaperSize = 'mm80',
    this.receiptTemplate = '',
  });

  OrganizationSettings copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? defaultPrinterId,
    String? defaultPaperSize,
    String? receiptTemplate,
  }) {
    return OrganizationSettings(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      defaultPrinterId: defaultPrinterId ?? this.defaultPrinterId,
      defaultPaperSize: defaultPaperSize ?? this.defaultPaperSize,
      receiptTemplate: receiptTemplate ?? this.receiptTemplate,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'logoUrl': logoUrl,
        'defaultPrinterId': defaultPrinterId,
        'defaultPaperSize': defaultPaperSize,
        'receiptTemplate': receiptTemplate,
      };

  factory OrganizationSettings.fromJson(Map<String, dynamic> json) {
    return OrganizationSettings(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      logoUrl: json['logoUrl']?.toString(),
      defaultPrinterId: (json['defaultPrinterId'] ?? '').toString(),
      defaultPaperSize: (json['defaultPaperSize'] ?? 'mm80').toString(),
      receiptTemplate: (json['receiptTemplate'] ?? '').toString(),
    );
  }

  static OrganizationSettings fromJsonString(String raw) =>
      OrganizationSettings.fromJson(jsonDecode(raw));

  String toJsonString() => jsonEncode(toJson());
}