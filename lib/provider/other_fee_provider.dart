import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/other_fee.dart';
import '../services/auth_interceptor.dart';

class OtherFeeProvider extends StateNotifier<List<OtherFee>> {
  
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));
  
  OtherFeeProvider() : super([]) {
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchOtherFees({int? academicYear, String? status}) async {
    try {
      await _setAuthHeader();
      
      final queryParams = <String, dynamic>{};
      if (academicYear != null) queryParams['academicYear'] = academicYear;
      if (status != null) queryParams['status'] = status;
      
      final response = await _dio.get("/admin/OtherFee", queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        state = data.map((json) => OtherFee.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        state = [];
        print("No other fees found (404 - empty data)");
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        state = [];
        print("No other fees found (404 - empty data)");
      } else {
        print("Error fetching other fees: $e");
      }
    }
  }

  Future<OtherFee?> getOtherFeeById(String id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get("/admin/OtherFee/$id");
      if (response.statusCode == 200) {
        return OtherFee.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error getting other fee by id: $e");
      return null;
    }
  }

  Future<void> addOtherFee(Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      await _dio.post("/admin/OtherFee", data: data);
      await fetchOtherFees(status: 'Active'); // Refresh with Active filter
    } catch (e) {
      print("Error adding other fee: $e");
      rethrow;
    }
  }

  Future<void> updateOtherFee(String id, Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      await _dio.patch("/admin/OtherFee/$id", data: data);
      await fetchOtherFees(status: 'Active');
    } catch (e) {
      print("Error updating other fee: $e");
      rethrow;
    }
  }

  Future<void> deleteOtherFee(String id) async {
    try {
      await _setAuthHeader();
      await _dio.delete("/admin/OtherFee/$id");
      await fetchOtherFees(status: 'Active');
    } catch (e) {
      print("Error deleting other fee: $e");
      rethrow;
    }
  }

  // NEW: Archive fees (bulk or single)
  Future<void> archiveOtherFees(int academicYear, List<String> feeIds) async {
    try {
      await _setAuthHeader();
      await _dio.post("/admin/OtherFee/archive", data: {
        "academicYear": academicYear,
        "feeIds": feeIds,
      });
      await fetchOtherFees(status: 'Active');
    } catch (e) {
      print("Error archiving other fees: $e");
      rethrow;
    }
  }

  // NEW: Unarchive single fee
  Future<void> unarchiveOtherFee(String id) async {
    try {
      await _setAuthHeader();
      await _dio.post("/admin/OtherFee/$id/unarchive");
      await fetchOtherFees();
    } catch (e) {
      print("Error unarchiving other fee: $e");
      rethrow;
    }
  }
}

final otherFeeProvider = StateNotifierProvider<OtherFeeProvider, List<OtherFee>>((ref) {
  return OtherFeeProvider();
});