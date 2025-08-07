import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade.dart';

class GradeProvider extends StateNotifier<AsyncValue<List<Grade>>> {
  GradeProvider() : super(const AsyncValue.loading()) {
    fetchGrades();
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> fetchGrades() async {
    try {
      state = const AsyncValue.loading();
      
      // Get the auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.get("/admin/Grade");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final grades = data.map((json) => Grade.fromJson(json)).toList();
        state = AsyncValue.data(grades);
      } else {
        state = AsyncValue.error("Failed to fetch grades", StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addGrade({
    required String name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      await _dio.post("/admin/Grade", data: {
        "name": name,
      });
      
      // Refresh the grade list
      await fetchGrades();
      return true;
    } catch (e) {
      print("Error adding grade: $e");
      return false;
    }
  }

  Future<bool> updateGrade({
    required String id,
    required String name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      await _dio.patch("/admin/Grade/$id", data: {
        "name": name,
      });
      
      // Refresh the grade list
      await fetchGrades();
      return true;
    } catch (e) {
      print("Error updating grade: $e");
      return false;
    }
  }

  Future<bool> deleteGrade(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      await _dio.delete("/admin/Grade/$id");
      
      // Refresh the grade list
      await fetchGrades();
      return true;
    } catch (e) {
      print("Error deleting grade: $e");
      return false;
    }
  }
}

final gradeProvider = StateNotifierProvider<GradeProvider, AsyncValue<List<Grade>>>((ref) {
  return GradeProvider();
});