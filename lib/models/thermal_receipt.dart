class ThermalReceipt {
  final String receiptId;
  final String receiptNumber;
  final DateTime receiptDate;
  final String staffMember;
  final OrganizationDetails organization;
  final StudentDetails student;
  final List<ReceiptItem> items;
  final ReceiptTotals totals;
  final PaymentDetails payment;
  final String? footerMessage;

  ThermalReceipt({
    required this.receiptId,
    required this.receiptNumber,
    required this.receiptDate,
    required this.staffMember,
    required this.organization,
    required this.student,
    required this.items,
    required this.totals,
    required this.payment,
    this.footerMessage,
  });

  factory ThermalReceipt.fromJson(Map<String, dynamic> json) {
    return ThermalReceipt(
      receiptId: _toString(json['receiptId']),
      receiptNumber: _toString(json['receiptNumber']),
      receiptDate: _parseDateTime(json['receiptDate']),
      staffMember: _toString(json['staffMember']),
      organization: OrganizationDetails.fromJson(_toMap(json['organization'])),
      student: StudentDetails.fromJson(_toMap(json['student'])),
      items: _parseItems(json['items']),
      totals: ReceiptTotals.fromJson(_toMap(json['totals'])),
      payment: PaymentDetails.fromJson(_toMap(json['payment'])),
      footerMessage: json['footerMessage']?.toString(),
    );
  }

  // Helper methods for safe type conversion
  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    // If backend wrapped as list with single map item, unwrap first
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return <String, dynamic>{};
  }

  static List<ReceiptItem> _parseItems(dynamic value) {
    if (value == null) return [];

    List<dynamic>? list;

    // Direct list
    if (value is List) {
      list = value;
    }

    // Wrapped in a map or special $values field
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final candidates = [
        map['items'],
        map['data'],
        map['results'],
        map['value'],
        map['records'],
        map[r'$values'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) {
          list = candidate;
          break;
        }
        if (candidate is Map && candidate[r'$values'] is List) {
          list = candidate[r'$values'] as List;
          break;
        }
      }
    }

    if (list == null) return [];

    return list
        .where((item) => item != null)
        .map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return ReceiptItem.fromJson(item);
            } else if (item is Map) {
              return ReceiptItem.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          } catch (e) {
            // print('Error parsing receipt item: $e');
            return null;
          }
        })
        .whereType<ReceiptItem>()
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'receiptNumber': receiptNumber,
      'receiptDate': receiptDate.toIso8601String(),
      'staffMember': staffMember,
      'organization': organization.toJson(),
      'student': student.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'totals': totals.toJson(),
      'payment': payment.toJson(),
      'footerMessage': footerMessage,
    };
  }
}

class OrganizationDetails {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? logo;

  OrganizationDetails({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.logo,
  });

  factory OrganizationDetails.fromJson(Map<String, dynamic> json) {
    return OrganizationDetails(
      name: _toString(json['name']),
      address: _toString(json['address']),
      phone: _toString(json['phone']),
      email: _toString(json['email']),
      logo: json['logo']?.toString(),
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logo': logo,
    };
  }
}

class StudentDetails {
  final String studentName;
  final String admissionNumber;
  final String grade;
  final String parentName;
  final String parentPhone;

  StudentDetails({
    required this.studentName,
    required this.admissionNumber,
    required this.grade,
    required this.parentName,
    required this.parentPhone,
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) {
    return StudentDetails(
      studentName: _toString(json['studentName']),
      admissionNumber: _toString(json['admissionNumber']),
      grade: _toString(json['grade']),
      parentName: _toString(json['parentName']),
      parentPhone: _toString(json['parentPhone']),
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'studentName': studentName,
      'admissionNumber': admissionNumber,
      'grade': grade,
      'parentName': parentName,
      'parentPhone': parentPhone,
    };
  }
}

class ReceiptItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String? itemType;

  ReceiptItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.itemType,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      description: _toString(json['description']),
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unitPrice']),
      totalAmount: _toDouble(json['totalAmount']),
      itemType: json['itemType']?.toString(),
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _toInt(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'itemType': itemType,
    };
  }
}

class ReceiptTotals {
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;

  ReceiptTotals({
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.grandTotal,
  });

  factory ReceiptTotals.fromJson(Map<String, dynamic> json) {
    return ReceiptTotals(
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discountAmount']),
      taxAmount: _toDouble(json['taxAmount']),
      grandTotal: _toDouble(json['grandTotal']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
    };
  }
}

class PaymentDetails {
  final String paymentMethod;
  final String? transactionReference;
  final DateTime paymentDate;
  final double amountReceived;
  final double changeAmount;

  PaymentDetails({
    required this.paymentMethod,
    this.transactionReference,
    required this.paymentDate,
    required this.amountReceived,
    required this.changeAmount,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      paymentMethod: _toString(json['paymentMethod']),
      transactionReference: json['transactionReference']?.toString(),
      paymentDate: _parseDateTime(json['paymentDate']),
      amountReceived: _toDouble(json['amountReceived']),
      changeAmount: _toDouble(json['changeAmount']),
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
      'transactionReference': transactionReference,
      'paymentDate': paymentDate.toIso8601String(),
      'amountReceived': amountReceived,
      'changeAmount': changeAmount,
    };
  }
}