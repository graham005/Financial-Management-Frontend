import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_received.dart';
import '../models/required_item.dart';
import '../provider/student_provider.dart';

class ItemsReceivedNotifier extends StateNotifier<AsyncValue<List<ItemReceived>>> {
  ItemsReceivedNotifier() : super(const AsyncValue.loading()) {
    _dio = Dio();
    _dio.options.baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  late final Dio _dio;

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchItemsReceived() async {
    try {
      state = const AsyncValue.loading();
      await _setAuthHeader();

      final response = await _dio.get('/ItemManagement/items-received');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        final itemsReceived = data.map((json) => ItemReceived.fromJson(json)).toList();
        
        // Sort by date received (most recent first)
        itemsReceived.sort((a, b) => b.dateReceived.compareTo(a.dateReceived));
        
        state = AsyncValue.data(itemsReceived);
      } else {
        state = AsyncValue.error(
          'Failed to fetch items received: ${response.statusCode}',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      print('Error fetching items received: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addItemReceived({
    required String requiredItemId,
    required String studentId,
    required double quantity,
    required DateTime dateReceived,
  }) async {
    try {
      await _setAuthHeader();

      final itemData = {
        'requiredItemId': requiredItemId,
        'studentId': studentId,
        'quantity': quantity,
        'dateReceived': dateReceived.toIso8601String(),
      };

      print('Adding item received: $itemData');

      final response = await _dio.post(
        '/ItemManagement/items-received',
        data: itemData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the list after successful addition
        await fetchItemsReceived();
        return true;
      } else {
        print('Failed to add item received: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding item received: $e');
      return false;
    }
  }

  Future<bool> updateItemReceived({
    required String id,
    required String requiredItemId,
    required String studentId,
    required double quantity,
    required DateTime dateReceived,
  }) async {
    try {
      await _setAuthHeader();

      // Use the correct PATCH schema (without id in the body)
      final itemData = {
        'requiredItemId': requiredItemId,
        'studentId': studentId,
        'quantity': quantity,
        'dateReceived': dateReceived.toIso8601String(),
      };

      print('Updating item received $id: $itemData');

      final response = await _dio.patch( // Changed from PUT to PATCH
        '/ItemManagement/items-received/$id',
        data: itemData,
      );

      if (response.statusCode == 200) {
        // Refresh the list after successful update
        await fetchItemsReceived();
        return true;
      } else {
        print('Failed to update item received: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating item received: $e');
      return false;
    }
  }

  Future<bool> deleteItemReceived(String id) async {
    try {
      await _setAuthHeader();

      print('Deleting item received: $id');

      final response = await _dio.delete('/ItemManagement/items-received/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh the list after successful deletion
        await fetchItemsReceived();
        return true;
      } else {
        print('Failed to delete item received: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting item received: $e');
      return false;
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

// Required Items Provider for dropdown selections
class RequiredItemsForSelectionNotifier extends StateNotifier<AsyncValue<List<RequiredItem>>> {
  RequiredItemsForSelectionNotifier() : super(const AsyncValue.loading()) {
    _dio = Dio();
    _dio.options.baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  late final Dio _dio;

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchRequiredItems() async {
    try {
      state = const AsyncValue.loading();
      await _setAuthHeader();

      final response = await _dio.get('/ItemManagement/required-items');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        final requiredItems = data.map((json) => RequiredItem.fromJson(json)).toList();
        
        // Sort by item name
        requiredItems.sort((a, b) => a.itemName.compareTo(b.itemName));
        
        state = AsyncValue.data(requiredItems);
      } else {
        state = AsyncValue.error(
          'Failed to fetch required items: ${response.statusCode}',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      print('Error fetching required items: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Students Provider for dropdown selections
class StudentsForSelectionNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  StudentsForSelectionNotifier() : super(const AsyncValue.loading()) {
    _dio = Dio();
    _dio.options.baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  late final Dio _dio;

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchStudents() async {
    try {
      state = const AsyncValue.loading();
      await _setAuthHeader();

      final response = await _dio.get('/admin/Student');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        final students = data.map((json) => Student.fromJson(json)).toList();
        
        // Sort by name
        students.sort((a, b) => a.name.compareTo(b.name));
        
        state = AsyncValue.data(students);
      } else {
        state = AsyncValue.error(
          'Failed to fetch students: ${response.statusCode}',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      print('Error fetching students: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Provider instances
final itemsReceivedProvider = StateNotifierProvider<ItemsReceivedNotifier, AsyncValue<List<ItemReceived>>>((ref) {
  return ItemsReceivedNotifier();
});

final requiredItemsForSelectionProvider = StateNotifierProvider<RequiredItemsForSelectionNotifier, AsyncValue<List<RequiredItem>>>((ref) {
  return RequiredItemsForSelectionNotifier();
});

final studentsForSelectionProvider = StateNotifierProvider<StudentsForSelectionNotifier, AsyncValue<List<Student>>>((ref) {
  return StudentsForSelectionNotifier();
});