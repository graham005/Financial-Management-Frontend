import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/auth_interceptor.dart';

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
}

class AuthProvider extends StateNotifier<AuthState> {
  late final Dio _dio;

  AuthProvider() : super(AuthState(isAuthenticated: false)) {
    _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));
    
    // Add auth interceptor
    _dio.interceptors.add(AuthInterceptor(_dio));
    
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userRole = prefs.getString("user_role");
    final email = prefs.getString("email");
    final username = prefs.getString("username");

    if (token != null && userRole != null) {
      state = AuthState(
        isAuthenticated: true,
        userRole: userRole,
        email: email,
        username: username,
      );
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post("/Auth/Login", data: {
        "email": email,
        "password": password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Extract tokens
        final token = data["token"] ?? data["accessToken"] ?? data["access_token"];
        final refreshToken = data["refreshToken"] ?? data["refresh_token"];
        
        if (token == null) {
          throw Exception("No token received from server");
        }

        // Get user role from token
        final userRole = _extractRoleFromJWT(token);

        // Fetch additional user info
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final userInfo = await _fetchUserInfo();
        final username = userInfo['username'] ?? userInfo['userName'] ?? userInfo['name'];

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        
        if (refreshToken != null) {
          await prefs.setString("refresh_token", refreshToken);
        }
        
        await prefs.setString("user_role", userRole);
        await prefs.setString("email", email);
        
        if (username != null) {
          await prefs.setString("username", username);
        }

        if (refreshToken != null) {
          print('✅ Refresh Token: ${refreshToken.substring(0, 20)}...');
        }

        state = AuthState(
          isAuthenticated: true,
          userRole: userRole,
          email: email,
          username: username,
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
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
      return {};
    }
  }

  String _extractRoleFromJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception("Invalid JWT format");
      }

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      // Check common role claim names
      final role = payloadMap['role'] ?? 
                   payloadMap['Role'] ?? 
                   payloadMap['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

      if (role == null) {
        print("Warning: No role found in JWT, defaulting to 'User'");
        return "User";
      }

      return role.toString();
    } catch (e) {
      print("Error extracting role from JWT: $e");
      return "User";
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("refresh_token");
    await prefs.remove("user_role");
    await prefs.remove("email");
    await prefs.remove("username");

    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider();
});