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
      receiptId: json['receiptId'] ?? '',
      receiptNumber: json['receiptNumber'] ?? '',
      receiptDate: DateTime.parse(json['receiptDate'] ?? DateTime.now().toIso8601String()),
      staffMember: json['staffMember'] ?? '',
      organization: OrganizationDetails.fromJson(json['organization'] ?? {}),
      student: StudentDetails.fromJson(json['student'] ?? {}),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ReceiptItem.fromJson(item))
          .toList() ?? [],
      totals: ReceiptTotals.fromJson(json['totals'] ?? {}),
      payment: PaymentDetails.fromJson(json['payment'] ?? {}),
      footerMessage: json['footerMessage'],
    );
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
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      logo: json['logo'],
    );
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
      studentName: json['studentName'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      grade: json['grade'] ?? '',
      parentName: json['parentName'] ?? '',
      parentPhone: json['parentPhone'] ?? '',
    );
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
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      itemType: json['itemType'],
    );
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
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
    );
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
      paymentMethod: json['paymentMethod'] ?? '',
      transactionReference: json['transactionReference'],
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      amountReceived: (json['amountReceived'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
    );
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