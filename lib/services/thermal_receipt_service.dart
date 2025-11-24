import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thermal_receipt.dart';
import 'dart:convert';

class ThermalReceiptService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> _setAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Fetches thermal receipt data for a specific transaction
  Future<ThermalReceipt> getThermalReceipt(String transactionId) async {
    try {
      await _setAuthHeaders();
      print('🎯 ====== FETCHING RECEIPT ======');
      print('🎯 Transaction ID: $transactionId');
      print('🎯 API Base URL: ${dotenv.env['API_BASE_URL']}');
      
      final response = await _dio.get('/FinancialTransaction/$transactionId/thermal-receipt');
      
      print('🎯 ====== RESPONSE RECEIVED ======');
      print('🎯 Status Code: ${response.statusCode}');
      print('🎯 Response Type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        return _processReceiptData(response.data, transactionId);
      } else {
        throw Exception('Failed to fetch thermal receipt: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('🚫 ====== DIO EXCEPTION ======');
      print('🚫 Status Code: ${e.response?.statusCode}');
      print('🚫 Response Data: ${e.response?.data}');
      print('🚫 Error Message: ${e.message}');
      print('🚫 ============================');
      
      final status = e.response?.statusCode;
      final message = e.response?.data is Map ? e.response?.data['message'] : e.message;
      throw Exception('Failed to fetch thermal receipt ($status): $message');
    } catch (e, stack) {
      print('💥 ====== UNEXPECTED ERROR ======');
      print('💥 Error: $e');
      print('💥 Stack: $stack');
      print('💥 ===============================');
      throw Exception('Failed to fetch thermal receipt: $e');
    }
  }

  ThermalReceipt _processReceiptData(dynamic data, String transactionId) {
    print('🔧 ====== PROCESSING RECEIPT DATA ======');
    
    try {
      dynamic body = data;
      
      // Step 1: Handle string JSON
      if (body is String) {
        print('📝 Converting from JSON string...');
        body = jsonDecode(body);
        print('✅ Converted to: ${body.runtimeType}');
      }

      // Step 2: Handle array responses
      if (body is List) {
        print('📋 Response is a list with ${body.length} items');
        if (body.isEmpty) {
          throw Exception('Empty list response');
        }
        body = body[0];
        print('✅ Extracted first item: ${body.runtimeType}');
      }

      // Step 3: Convert to map
      if (body is! Map) {
        throw Exception('Cannot convert to Map: ${body.runtimeType}');
      }

      final Map<String, dynamic> responseMap = body is Map<String, dynamic> 
          ? body 
          : Map<String, dynamic>.from(body);

      print('🔑 Response structure keys: ${responseMap.keys.join(', ')}');

      // Step 4: Check if this is the new backend format (header/body/footer structure)
      if (responseMap.containsKey('header') && responseMap.containsKey('body')) {
        print('✨ Detected new backend format with header/body/footer structure');
        return _parseNewBackendFormat(responseMap, transactionId);
      }

      // Step 5: Handle old format or wrapped responses
      Map<String, dynamic> finalMap = responseMap;
      
      for (final wrapperKey in ['data', 'result', 'receipt', 'value', 'payload']) {
        if (responseMap.containsKey(wrapperKey) && responseMap[wrapperKey] != null) {
          print('🎁 Found wrapper key: $wrapperKey');
          final wrapped = responseMap[wrapperKey];
          if (wrapped is Map) {
            finalMap = Map<String, dynamic>.from(wrapped);
            print('✅ Unwrapped to: ${finalMap.keys.join(', ')}');
            break;
          }
        }
      }

      // Check if critical fields are missing
      if (!finalMap.containsKey('organization') || 
          !finalMap.containsKey('student') ||
          !finalMap.containsKey('items')) {
        print('⚠️ CRITICAL FIELDS MISSING - Creating from transaction data...');
        return _createReceiptFromTransaction(finalMap, transactionId);
      }

      return ThermalReceipt.fromJson(finalMap);
    } catch (e, stack) {
      print('❌ ====== PARSE ERROR ======');
      print('❌ Error: $e');
      print('❌ Stack: $stack');
      print('❌ ==========================');
      throw Exception('Failed to parse receipt: $e');
    }
  }

  /// Parse the new backend format (header/body/footer structure)
  ThermalReceipt _parseNewBackendFormat(Map<String, dynamic> data, String transactionId) {
    print('🎨 ====== PARSING NEW BACKEND FORMAT ======');
    
    try {
      final header = data['header'] as Map<String, dynamic>? ?? {};
      final body = data['body'] as Map<String, dynamic>? ?? {};
      final footer = data['footer'] as Map<String, dynamic>? ?? {};
      
      // Extract header information (no hardcoded fallbacks)
      final orgName = header['organizationName']?.toString() ?? '';
      final orgAddress = header['organizationAddress']?.toString() ?? '';
      final orgPhone = header['organizationPhone']?.toString() ?? '';
      final receiptTitle = header['receiptTitle']?.toString();
      final receiptNumber = header['receiptNumber']?.toString() ?? '';
      final issuedDate = _parseDateTime(header['issuedDate']) ?? DateTime.now();
      
      // Extract customer (student) information
      final customer = body['customer'] as Map<String, dynamic>? ?? {};
      final studentName = customer['name']?.toString() ?? 'Unknown Student';
      final admissionNumber = customer['admissionNumber']?.toString() ?? 'N/A';
      final grade = customer['grade']?.toString() ?? 'N/A';
      final parentName = customer['parentName']?.toString() ?? 'N/A';
      final contact = customer['contact']?.toString() ?? 'N/A';
      
      // Extract items
      final itemsList = body['items'] as List? ?? [];
      final items = <ReceiptItem>[];
      
      for (final item in itemsList) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);
          items.add(ReceiptItem(
            description: itemMap['name']?.toString() ?? itemMap['shortName']?.toString() ?? 'Item',
            quantity: _parseInt(itemMap['quantity']) ?? 1,
            unitPrice: _parseDouble(itemMap['unitPrice']) ?? 0.0,
            totalAmount: _parseDouble(itemMap['total']) ?? 0.0,
            itemType: itemMap['unit']?.toString(),
          ));
        }
      }
      
      // Extract totals
      final totals = body['totals'] as Map<String, dynamic>? ?? {};
      final subTotal = _parseDouble(totals['subTotal']) ?? 0.0;
      final tax = _parseDouble(totals['tax']) ?? 0.0;
      final discount = _parseDouble(totals['discount']) ?? 0.0;
      final grandTotal = _parseDouble(totals['grandTotal']) ?? 0.0;
      
      // Extract transaction information
      final transaction = body['transaction'] as Map<String, dynamic>? ?? {};
      final paymentMethod = transaction['paymentMethod']?.toString() ?? 'Cash';
      final transactionDate = _parseDateTime(transaction['transactionDate']) ?? DateTime.now();
      final processedBy = transaction['processedBy']?.toString() ?? 'System';
      final term = transaction['term']?.toString();
      final year = transaction['year']?.toString();

      // Footer / notes (do not inject defaults)
      final thankYouMessage = (footer['thankYouMessage']?.toString() ?? '').trim();
      final contactInfo = (footer['contactInfo']?.toString() ?? '').trim();
      final additionalNotes = (footer['additionalNotes'] as List? ?? []).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      final signatureLine = (footer['signature']?.toString() ?? '').isNotEmpty
          ? footer['signature'].toString()
          : 'Authorized Signature: _______________'; // always show a signature line
      final parts = <String>[];
      if (thankYouMessage.isNotEmpty) parts.add(thankYouMessage);
      if (contactInfo.isNotEmpty) parts.add(contactInfo);
      if (additionalNotes.isNotEmpty) parts.addAll(additionalNotes);
      // ALWAYS ensure thank you message at bottom
      const defaultThanks = 'Thank you for your payment!';
      if (!parts.any((p) => p.toLowerCase().contains('thank'))) {
        parts.add(defaultThanks);
      }
      final footerMessage = parts.isEmpty ? defaultThanks : parts.join('\n');

      return ThermalReceipt(
        receiptId: transactionId,
        receiptNumber: receiptNumber,
        receiptDate: issuedDate,
        staffMember: processedBy,
        organization: OrganizationDetails(
          name: orgName,
          address: orgAddress,
          phone: orgPhone.replaceAll('Tel: ', ''),
          email: '', // internal field removed from print usage
          logo: header['logoBase64']?.toString(),
        ),
        student: StudentDetails(
          studentName: studentName,
          admissionNumber: admissionNumber,
          grade: grade,
          parentName: parentName,
          parentPhone: contact,
        ),
        items: items,
        totals: ReceiptTotals(
          subtotal: subTotal,
          discountAmount: discount,
          taxAmount: tax,
          grandTotal: grandTotal,
        ),
        payment: PaymentDetails(
          paymentMethod: paymentMethod,
          transactionReference: transactionId,
          paymentDate: transactionDate,
          amountReceived: grandTotal,
          changeAmount: 0.0,
        ),
        footerMessage: footerMessage,
        term: term,
        year: year,
        signatureLine: signatureLine,
        title: receiptTitle, // NEW
      );
    } catch (e, stack) {
      print('❌ Error parsing new backend format: $e');
      print('Stack: $stack');
      throw Exception('Failed to parse new backend format: $e');
    }
  }

  /// Create receipt from transaction data when backend doesn't return proper receipt format
  ThermalReceipt _createReceiptFromTransaction(Map<String, dynamic> data, String transactionId) {
    // Use only what exists; no hardcoded organization/footer defaults
    final amount = _parseDouble(data['amount'] ?? data['totalAmount']) ?? 0.0;
    final paymentMethod = (data['paymentMethod'] ?? '').toString();
    final paymentDate = _parseDateTime(data['paymentDate'] ?? data['transactionDate']) ?? DateTime.now();

    final studentData = (data['student'] is Map) ? Map<String, dynamic>.from(data['student']) : const {};
    final studentName = (studentData['name'] ?? studentData['studentName'] ?? '').toString();
    final admissionNumber = (studentData['admissionNumber'] ?? studentData['admNo'] ?? '').toString();
    final grade = (studentData['grade'] ?? studentData['class'] ?? '').toString();

    final items = <ReceiptItem>[];
    if (data['feeAllocations'] is List) {
      for (final alloc in (data['feeAllocations'] as List)) {
        if (alloc is Map) {
          final m = Map<String, dynamic>.from(alloc);
          final amt = _parseDouble(m['amount']) ?? 0.0;
          items.add(ReceiptItem(
            description: (m['feeType'] ?? m['description'] ?? '').toString(),
            quantity: 1,
            unitPrice: amt,
            totalAmount: amt,
            itemType: 'fee',
          ));
        }
      }
    }
    if (items.isEmpty && amount > 0) {
      items.add(ReceiptItem(
        description: 'Payment',
        quantity: 1,
        unitPrice: amount,
        totalAmount: amount,
        itemType: 'fee',
      ));
    }

    // Footer: always include thank you message
    const defaultThanks = 'Thank you for your payment!';
    final footerMessage = defaultThanks;

    return ThermalReceipt(
      receiptId: transactionId,
      receiptNumber: (data['receiptNumber'] ?? '').toString(),
      receiptDate: paymentDate,
      staffMember: (data['staffMember'] ?? data['processedBy'] ?? '').toString(),
      organization: OrganizationDetails(
        name: (data['organizationName'] ?? '').toString(),
        address: (data['organizationAddress'] ?? '').toString(),
        phone: (data['organizationPhone'] ?? '').toString(),
        email: '', // do not print email
        logo: null,
      ),
      student: StudentDetails(
        studentName: studentName,
        admissionNumber: admissionNumber,
        grade: grade,
        parentName: (studentData['parentName'] ?? '').toString(),
        parentPhone: (studentData['parentPhone'] ?? '').toString(),
      ),
      items: items,
      totals: ReceiptTotals(
        subtotal: amount,
        discountAmount: _parseDouble(data['discountAmount']) ?? 0.0,
        taxAmount: _parseDouble(data['taxAmount']) ?? 0.0,
        grandTotal: amount,
      ),
      payment: PaymentDetails(
        paymentMethod: paymentMethod,
        transactionReference: (data['transactionReference'] ?? data['reference'] ?? transactionId).toString(),
        paymentDate: paymentDate,
        amountReceived: amount,
        changeAmount: 0.0,
      ),
      footerMessage: footerMessage,
      term: (data['term'] ?? '').toString().isEmpty ? null : data['term'].toString(),
      year: (data['year']?.toString().isEmpty ?? true) ? null : data['year'].toString(),
      signatureLine: 'Authorized Signature: _______________', // always show
      title: (data['receiptTitle'] ?? '').toString().isEmpty ? null : data['receiptTitle'].toString(),
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) return value;
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final cleaned = value.replaceAll(',', '');
      return int.tryParse(cleaned);
    }
    return null;
  }

  /// Fetches multiple thermal receipts for batch operations
  Future<List<ThermalReceipt>> getThermalReceipts(List<String> transactionIds) async {
    final results = <ThermalReceipt>[];
    final errors = <String>[];

    for (final id in transactionIds) {
      try {
        final receipt = await getThermalReceipt(id);
        results.add(receipt);
      } catch (e) {
        print('Error fetching receipt for transaction $id: $e');
        errors.add('$id: $e');
      }
    }

    if (results.isEmpty && errors.isNotEmpty) {
      throw Exception('Failed to fetch any receipts: ${errors.join(', ')}');
    }

    return results;
  }

  /// Validates if a transaction has receipt data available
  Future<bool> isReceiptAvailable(String transactionId) async {
    try {
      await getThermalReceipt(transactionId);
      return true;
    } catch (e) {
      return false;
    }
  }
}