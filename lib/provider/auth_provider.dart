import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref){
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? userRole;
  final String? email;
  final String? username;

  AuthState({
    required this.isAuthenticated,
    this.userRole,
    this.email,
    this.username,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userRole,
    String? email,
    String? username,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
      email: email ?? this.email,
      username: username ?? this.username,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(): super(AuthState(isAuthenticated: false)) {
    _checkAuthStatus();
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post("/Auth/Login", data: {
        "email": email,
        "password": password,
      });
      
      if (response.statusCode != 200) {
        throw Exception("Login failed: ${response.statusMessage}");
      }

      final token = response.data["accessToken"];
      
      if (token != null) {
        // Store token first
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        
        // Set Authorization header for subsequent requests
        _dio.options.headers['Authorization'] = 'Bearer $token';
        
        // Fetch user information from /Auth/Me endpoint
        final userInfo = await _fetchUserInfo();
        
        // Extract role from JWT payload as fallback
        final userRole = userInfo['role'] ?? _extractRoleFromJWT(token);
        final username = userInfo['username'] ?? userInfo['userName'] ?? userInfo['name'];
        
        // Store user information
        await prefs.setString("user_role", userRole);
        await prefs.setString("email", email);
        if (username != null) {
          await prefs.setString("username", username);
        }

        state = AuthState(
          isAuthenticated: true,
          userRole: userRole,
          email: email,
          username: username,
        );
      }
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  Future<Map<String, dynamic>> _fetchUserInfo() async {
    try {
      final response = await _dio.get("/Auth/Me");
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception("Failed to fetch user info: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error fetching user info: $e");
      // Return empty map if request fails
      return {};
    }
  }

  String _extractRoleFromJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return "Admin"; // Default fallback
      }
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      
      // Common JWT claim names for roles
      return payloadMap['role'] ?? 
             payloadMap['Role'] ?? 
             payloadMap['roles'] ?? 
             payloadMap['Roles'] ?? 
             payloadMap['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
             "Admin"; // Default fallback
    } catch (e) {
      print("Error extracting role from JWT: $e");
      return "Admin"; // Default fallback
    }
  }

  Future<void> refreshUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final userInfo = await _fetchUserInfo();
        
        final userRole = userInfo['role'] ?? state.userRole ?? "Admin";
        final username = userInfo['username'] ?? userInfo['userName'] ?? userInfo['name'];
        final email = userInfo['email'] ?? state.email;
        
        // Update stored information
        await prefs.setString("user_role", userRole);
        if (email != null) await prefs.setString("email", email);
        if (username != null) await prefs.setString("username", username);
        
        state = state.copyWith(
          userRole: userRole,
          email: email,
          username: username,
        );
      }
    } catch (e) {
      print("Error refreshing user info: $e");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user_role");
    await prefs.remove("email");
    await prefs.remove("username");
    
    // Clear Authorization header
    _dio.options.headers.remove('Authorization');
    
    state = AuthState(isAuthenticated: false);
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userRole = prefs.getString("user_role");
    final email = prefs.getString("email");
    final username = prefs.getString("username");
    
    if (token != null) {
      // Set Authorization header
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      state = AuthState(
        isAuthenticated: true,
        userRole: userRole,
        email: email,
        username: username,
      );
      
      // Optionally refresh user info on app start
      // Uncomment the line below if you want to fetch fresh user data on app start
      // refreshUserInfo();
    }
  }

  Future<bool> isAuthenticated() async {
    await _checkAuthStatus();
    return state.isAuthenticated;
  }
}