import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> _setAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.post(
        '/Auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      print('✅ Password changed successfully: ${response.data}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error changing password: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      
      if (e.response?.data != null && e.response!.data is Map) {
        final errorMessage = e.response!.data['message'] ?? e.response!.data['Message'];
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
      }
      
      throw Exception('Failed to change password: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  Future<Map<String, String>?> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/Auth/Refresh',
        data: {
          'token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        return {
          'accessToken': data['accessToken'] ?? data['token'] ?? data['access_token'],
          'refreshToken': data['refreshToken'] ?? data['refresh_token'] ?? refreshToken,
        };
      }

      return null;
    } catch (e) {
      print('❌ Token refresh failed: $e');
      return null;
    }
  }
}