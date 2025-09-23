import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thermal_receipt.dart';

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
      
      final response = await _dio.get('/financialtransaction/$transactionId/thermal-receipt');
      
      if (response.statusCode == 200) {
        return ThermalReceipt.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch thermal receipt: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data?['message'] ?? e.message;
      throw Exception('Failed to fetch thermal receipt ($status): $message');
    } catch (e) {
      throw Exception('Failed to fetch thermal receipt: $e');
    }
  }

  /// Fetches multiple thermal receipts for batch operations
  Future<List<ThermalReceipt>> getThermalReceipts(List<String> transactionIds) async {
    try {
      final receipts = await Future.wait(
        transactionIds.map((id) => getThermalReceipt(id)),
      );
      return receipts;
    } catch (e) {
      throw Exception('Failed to fetch thermal receipts: $e');
    }
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