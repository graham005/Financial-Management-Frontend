import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref){
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier(): super(false);

  final Dio _dio = Dio(BaseOptions(baseUrl: "https://localhost:44340/api"));

  Future<void> login(String username, String password) async {
    try {
      final response =await _dio.post("/Auth/Login", data: {
        "username": username,
        "password": password,
      });
      print(response.data["accessToken"]);    
      if (response.statusCode != 200) {
        throw Exception("Login failed: ${response.statusMessage}");
      }

      final token =response.data["accesToken"];
      if (token != null){
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);

        state =true;
      }
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  Future <void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    state = false;
  }

  Future<bool> isAuthenticated() async {
    final prefs =await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    state = token != null;
    return state;
  }
}