import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report/daily_collection_report.dart';
import '../models/report/revenue_summary_report.dart';
import '../models/report/outstanding_fees_report.dart';
import '../models/report/collection_rate_report.dart';
import '../models/report/payment_history_report.dart';
import '../models/report/item_transactions_report.dart';
import '../models/report/student_statement_report.dart';
import '../models/report/report_summary.dart';
import '../models/report/report_filter.dart';
import '../services/report_service.dart';
import '../services/report_download_service.dart';

// Service Provider
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

final reportDownloadServiceProvider = Provider<ReportDownloadService>((ref) {
  return ReportDownloadService();
});

// Report Filter State Provider
final reportFilterProvider = StateProvider<ReportFilter>((ref) {
  return ReportFilter(); // Default: all filters null, format JSON
});

// Daily Collections Report Provider
final dailyCollectionsProvider = FutureProvider.autoDispose<DailyCollectionReport>((ref) async {
  final service = ref.watch(reportServiceProvider);
  final filter = ref.watch(reportFilterProvider);
  return service.getDailyCollections(filter);
});

// Revenue Summary Report Provider
final revenueSummaryProvider = FutureProvider.autoDispose<RevenueSummaryReport>((ref) async {
  final service = ref.watch(reportServiceProvider);
  final filter = ref.watch(reportFilterProvider);
  return service.getRevenueSummary(filter);
});

// Outstanding Fees Report Provider
final outstandingFeesProvider = FutureProvider.autoDispose<OutstandingFeesReport>((ref) async {
  final service = ref.watch(reportServiceProvider);
  final filter = ref.watch(reportFilterProvider);
  return service.getOutstandingFees(filter);
});

// Collection Rate Report Provider
final collectionRateProvider = FutureProvider.autoDispose<CollectionRateReport>((ref) async {
  final service = ref.watch(reportServiceProvider);
  final filter = ref.watch(reportFilterProvider);
  return service.getCollectionRate(filter);
});

// Payment History Report Provider
final paymentHistoryProvider = FutureProvider.autoDispose<PaymentHistoryReport>((ref) async {
  final service = ref.watch(reportServiceProvider);
  final filter = ref.watch(reportFilterProvider);
  return service.getPaymentHistory(filter);
});

// Item Transactions Report Provider
final itemTransactionsProvider = FutureProvider.autoDispose<ItemTransactionsReport>((ref) async {
  final service = ref.watch(reportServiceProvider);
  final filter = ref.watch(reportFilterProvider);
  return service.getItemTransactions(filter);
});

// Student Statement Report Provider (requires studentId)
final studentStatementProvider = FutureProvider.family.autoDispose<StudentStatementReport, String>(
  (ref, studentId) async {
    final service = ref.watch(reportServiceProvider);
    final filter = ref.watch(reportFilterProvider);
    return service.getStudentStatement(studentId, filter.format);
  },
);

// Report Summary Provider
final reportSummaryProvider = FutureProvider.autoDispose<ReportSummary>((ref) async {
  final service = ref.watch(reportServiceProvider);
  final filter = ref.watch(reportFilterProvider);
  return service.getReportSummary(filter);
});

// Download Notifier
class ReportDownloadNotifier extends StateNotifier<bool> {
  final ReportDownloadService _service;

  ReportDownloadNotifier(this._service) : super(false);

  Future<bool> downloadReport({
    required String reportType,
    required ReportFilter filter,
  }) async {
    state = true; // Set loading
    try {
      final success = await _service.downloadReport(
        reportType: reportType,
        filter: filter,
      );
      state = false;
      return success;
    } catch (e) {
      state = false;
      print('Download error in notifier: $e');
      return false;
    }
  }
}

// Provider for download state
final reportDownloadProvider = StateNotifierProvider<ReportDownloadNotifier, bool>((ref) {
  final service = ref.watch(reportDownloadServiceProvider);
  return ReportDownloadNotifier(service);
});

// Report Type Enum for UI selection
enum ReportType {
  dailyCollections('Daily Collections', 'daily-collections'),
  revenueSummary('Revenue Summary', 'revenue-summary'),
  outstandingFees('Outstanding Fees', 'outstanding-fees'),
  collectionRate('Collection Rate', 'collection-rate'),
  paymentHistory('Payment History', 'payment-history'),
  itemTransactions('Item Transactions', 'item-transactions'),
  studentStatement('Student Statement', 'student-statement'),
  summary('Summary', 'summary');

  final String displayName;
  final String endpoint;

  const ReportType(this.displayName, this.endpoint);
}

// Selected Report Type Provider
final selectedReportTypeProvider = StateProvider<ReportType>((ref) {
  return ReportType.summary; // Default to summary
});

// Batch Selection Provider (for student statements)
final batchStudentSelectionProvider = StateProvider<Set<String>>((ref) {
  return {};
});