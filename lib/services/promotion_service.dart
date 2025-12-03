import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_promotion.dart';

class PromotionService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> _setAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Get promotion preview
  Future<PromotionPreview> getPromotionPreview() async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get('/admin/StudentPromotion/preview');
      
      print('📋 Promotion Preview Response: ${response.data}');
      
      return PromotionPreview.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Error fetching promotion preview: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception('Failed to load promotion preview: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Failed to load promotion preview: $e');
    }
  }

  /// Promote selected students
  Future<bool> promoteStudents(List<String> studentIds) async {
    try {
      await _setAuthHeaders();
      
      print('📤 Promoting students: $studentIds');
      
      final response = await _dio.post(
        '/admin/StudentPromotion/promote',
        data: {
          'studentIds': studentIds,
        },
      );
      
      print('✅ Promotion successful: ${response.data}');
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error promoting students: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception('Failed to promote students: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Failed to promote students: $e');
    }
  }
}