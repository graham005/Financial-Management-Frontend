import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report/daily_collection_report.dart';
import '../models/report/revenue_summary_report.dart';
import '../models/report/outstanding_fees_report.dart';
import '../models/report/collection_rate_report.dart';
import '../models/report/payment_history_report.dart';
import '../models/report/item_transactions_report.dart';
import '../models/report/student_statement_report.dart';
import '../models/report/report_summary.dart';
import '../models/report/report_filter.dart';

class ReportService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> _setAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Get Daily Collections Report
  Future<DailyCollectionReport> getDailyCollections(ReportFilter filter) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/daily-collections',
        queryParameters: filter.toQueryParams(),
      );
      
      return DailyCollectionReport.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch daily collections: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch daily collections: $e');
    }
  }

  /// Get Revenue Summary Report
  Future<RevenueSummaryReport> getRevenueSummary(ReportFilter filter) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/revenue-summary',
        queryParameters: filter.toQueryParams(),
      );
      
      return RevenueSummaryReport.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch revenue summary: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch revenue summary: $e');
    }
  }

  /// Get Outstanding Fees Report
  Future<OutstandingFeesReport> getOutstandingFees(ReportFilter filter) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/outstanding-fees',
        queryParameters: filter.toQueryParams(),
      );
      
      return OutstandingFeesReport.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch outstanding fees: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch outstanding fees: $e');
    }
  }

  /// Get Collection Rate Report
  Future<CollectionRateReport> getCollectionRate(ReportFilter filter) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/collection-rate',
        queryParameters: filter.toQueryParams(),
      );
      
      return CollectionRateReport.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch collection rate: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch collection rate: $e');
    }
  }

  /// Get Payment History Report
  Future<PaymentHistoryReport> getPaymentHistory(ReportFilter filter) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/payment-history',
        queryParameters: filter.toQueryParams(),
      );
      
      return PaymentHistoryReport.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch payment history: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch payment history: $e');
    }
  }

  /// Get Item Transactions Report
  Future<ItemTransactionsReport> getItemTransactions(ReportFilter filter) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/item-transactions',
        queryParameters: filter.toQueryParams(),
      );
      
      return ItemTransactionsReport.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch item transactions: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch item transactions: $e');
    }
  }

  /// Get Student Statement Report
  Future<StudentStatementReport> getStudentStatement(String studentId, String format) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/student-statement/$studentId',
        queryParameters: {'Format': format},
      );
      
      return StudentStatementReport.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch student statement: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch student statement: $e');
    }
  }


  /// Get Report Summary (aggregated dashboard data)
  Future<ReportSummary> getReportSummary(ReportFilter filter) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/summary',
        queryParameters: filter.toQueryParams(),
      );
      
      return ReportSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch report summary: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to fetch report summary: $e');
    }
  }

  /// Download report as PDF/Excel (returns file bytes)
  Future<Response> downloadReport({
    required String reportType, // 'daily-collections', 'revenue-summary', etc.
    required ReportFilter filter,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get(
        '/admin/Report/$reportType',
        queryParameters: filter.toQueryParams(),
        options: Options(
          responseType: ResponseType.bytes, // For file download
        ),
      );
      
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to download report: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to download report: $e');
    }
  }

  /// Helper: Validate if report data is available for given filters
  Future<bool> isReportAvailable(String reportType, ReportFilter filter) async {
    try {
      await getDailyCollections(filter);
      return true;
    } catch (e) {
      return false;
    }
  }
}