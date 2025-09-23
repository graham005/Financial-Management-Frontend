import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thermal_receipt.dart';

class PrintAuditEntry {
  final String id; // transactionId
  final String receiptNumber;
  final String studentName;
  final double totalAmount;
  final DateTime timestamp;
  final bool success;
  final String? error;

  PrintAuditEntry({
    required this.id,
    required this.receiptNumber,
    required this.studentName,
    required this.totalAmount,
    required this.timestamp,
    required this.success,
    this.error,
  });

  factory PrintAuditEntry.fromJson(Map<String, dynamic> json) => PrintAuditEntry(
    id: json['id'] ?? '',
    receiptNumber: json['receiptNumber'] ?? '',
    studentName: json['studentName'] ?? '',
    totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    success: json['success'] ?? false,
    error: json['error'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'receiptNumber': receiptNumber,
    'studentName': studentName,
    'totalAmount': totalAmount,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'error': error,
  };
}

class PrintAuditNotifier extends StateNotifier<List<PrintAuditEntry>> {
  PrintAuditNotifier() : super([]) {
    _load();
  }

  static const _storageKey = 'print_audit_entries';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    state = raw.map((s) => PrintAuditEntry.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, payload);
  }

  Future<void> logSuccess(ThermalReceipt r, {required String transactionId}) async {
    final entry = PrintAuditEntry(
      id: transactionId,
      receiptNumber: r.receiptNumber,
      studentName: r.student.studentName,
      totalAmount: r.totals.grandTotal,
      timestamp: DateTime.now(),
      success: true,
    );
    state = [entry, ...state];
    await _persist();
  }

  Future<void> logFailure(ThermalReceipt r, {required String transactionId, required String error}) async {
    final entry = PrintAuditEntry(
      id: transactionId,
      receiptNumber: r.receiptNumber,
      studentName: r.student.studentName,
      totalAmount: r.totals.grandTotal,
      timestamp: DateTime.now(),
      success: false,
      error: error,
    );
    state = [entry, ...state];
    await _persist();
  }

  Future<void> clear() async {
    state = [];
    await _persist();
  }
}

final printAuditProvider = StateNotifierProvider<PrintAuditNotifier, List<PrintAuditEntry>>(
  (ref) => PrintAuditNotifier(),
);