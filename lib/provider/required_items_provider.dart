import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/required_item.dart';

class RequiredItemsProvider extends StateNotifier<AsyncValue<List<RequiredItem>>> {
  RequiredItemsProvider() : super(const AsyncValue.loading()) {
    fetchRequiredItems();
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchRequiredItems() async {
    try {
      state = const AsyncValue.loading();
      await _setAuthHeader();
      
      final response = await _dio.get("/ItemManagement/required-items");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        final items = data.map((json) => RequiredItem.fromJson(json)).toList();
        state = AsyncValue.data(items);
      } else if (response.statusCode == 404) {
        // Handle 404 as empty data (some backends do this)
        state = const AsyncValue.data([]);
        print("No required items found (404 - empty data)");
      } else {
        state = AsyncValue.error("Failed to fetch required items", StackTrace.current);
      }
    } catch (e, stackTrace) {
      if (e is DioException && e.response?.statusCode == 404) {
        // Handle 404 as empty data
        state = const AsyncValue.data([]);
        print("No required items found (404 - empty data)");
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<RequiredItem?> getRequiredItemById(String id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get("/ItemManagement/required-items/$id");
      if (response.statusCode == 200) {
        return RequiredItem.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error getting required item by id: $e");
      return null;
    }
  }

  Future<bool> addRequiredItem({
    required String itemName,
    required double expectedQuantity,
    required String unit,
  }) async {
    try {
      await _setAuthHeader();

      await _dio.post("/ItemManagement/required-items", data: {
        "itemName": itemName,
        "expectedQuantity": expectedQuantity,
        "unit": unit,
      });
      
      // Refresh the required items list
      await fetchRequiredItems();
      return true;
    } catch (e) {
      print("Error adding required item: $e");
      return false;
    }
  }

  Future<bool> updateRequiredItem({
    required String id,
    required String itemName,
    required double expectedQuantity,
    required String unit,
  }) async {
    try {
      await _setAuthHeader();

      await _dio.patch("/ItemManagement/required-items/$id", data: {
        "itemName": itemName,
        "expectedQuantity": expectedQuantity,
        "unit": unit,
      });
      
      // Refresh the required items list
      await fetchRequiredItems();
      return true;
    } catch (e) {
      print("Error updating required item: $e");
      return false;
    }
  }

  Future<bool> deleteRequiredItem(String id) async {
    try {
      await _setAuthHeader();

      await _dio.delete("/ItemManagement/required-items/$id");
      
      // Refresh the required items list
      await fetchRequiredItems();
      return true;
    } catch (e) {
      print("Error deleting required item: $e");
      return false;
    }
  }
}

final requiredItemsProvider = StateNotifierProvider<RequiredItemsProvider, AsyncValue<List<RequiredItem>>>((ref) {
  return RequiredItemsProvider();
});
