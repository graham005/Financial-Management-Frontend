import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User{
  final String id;
  final String username;
  final String email;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toJson(){
    return {
      "id": id,
      "username": username,
      "email": email,
      "role": role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"].toString(), 
      username: json["username"] ?? '', 
      email: json["email"] ?? '', 
      role: json["role"] ?? 'Admin'
    );
  }
}

class UserProvider extends StateNotifier<AsyncValue<List<User>>> {
  UserProvider(): super(const AsyncValue.loading()) {
    fetchUsers();
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> fetchUsers() async {
    try {
      state = const AsyncValue.loading();
      
      // Get the auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.get("/admin/Users");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final users = data.map((json) => User.fromJson(json)).toList();
        state = AsyncValue.data(users);
      } else {
        state = AsyncValue.error("Failed to fetch users", StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      await _dio.post("/admin/Users", data: {
        "username": username,
        "email": email,
        "password": password,
        "role": role,
      });
      
      // Refresh the user list
      await fetchUsers();
      return true;
    } catch (e) {
      print("Error adding user: $e");
      return false;
    }
  }

  Future<bool> updateUser({
    required String id,
    required String username,
    required String email,
    required String role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      await _dio.put("/admin/Users/$id", data: {
        "username": username,
        "email": email,
        "role": role,
      });
      
      // Refresh the user list
      await fetchUsers();
      return true;
    } catch (e) {
      print("Error updating user: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      await _dio.delete("/admin/Users/$id");
      
      // Refresh the user list
      await fetchUsers();
      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }
}

final userProvider = StateNotifierProvider<UserProvider, AsyncValue<List<User>>>((ref) {
  return UserProvider();
});
