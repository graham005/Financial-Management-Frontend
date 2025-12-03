import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _requestQueue = [];

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to all requests
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null && !options.path.contains('/Auth/')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    print('📤 Request: ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('❌ Error Response: ${err.response?.statusCode} - ${err.requestOptions.path}');

    // Only handle 401 errors
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // Don't retry refresh endpoint or login endpoint
      if (requestOptions.path.contains('/Auth/Refresh') ||
          requestOptions.path.contains('/Auth/Login')) {
        print('⚠️ Auth endpoint failed, not retrying');
        handler.next(err);
        return;
      }

      print('🔄 Attempting token refresh...');

      // If already refreshing, queue the request
      if (_isRefreshing) {
        print('⏳ Token refresh in progress, queueing request...');
        _requestQueue.add(requestOptions);
        return;
      }

      _isRefreshing = true;

      try {
        // Attempt to refresh the token
        final newToken = await _refreshToken();

        if (newToken != null) {
          print('✅ Token refreshed successfully');
          
          // Update the failed request with new token
          requestOptions.headers['Authorization'] = 'Bearer $newToken';

          // Retry the original request
          final response = await _dio.fetch(requestOptions);
          
          // Process queued requests with new token
          await _processQueue(newToken);
          
          _isRefreshing = false;
          handler.resolve(response);
          return;
        } else {
          print('❌ Token refresh failed');
          _isRefreshing = false;
          _requestQueue.clear();
          
          // Logout user
          await _handleLogout();
          handler.next(err);
          return;
        }
      } catch (e) {
        print('❌ Token refresh error: $e');
        _isRefreshing = false;
        _requestQueue.clear();
        
        // Logout user
        await _handleLogout();
        handler.next(err);
        return;
      }
    }

    // Pass through other errors
    handler.next(err);
  }

  /// Refresh the access token using the refresh token
  Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString("refresh_token");

      if (refreshToken == null) {
        print('⚠️ No refresh token found');
        return null;
      }

      print('📤 Sending refresh request...');
      
      final response = await _dio.post(
        '/Auth/Refresh',
        data: {
          'token': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Extract new tokens from response
        final newAccessToken = data['accessToken'] ?? data['token'] ?? data['access_token'];
        final newRefreshToken = data['refreshToken'] ?? data['refresh_token'];

        if (newAccessToken != null) {
          // Save new tokens
          await prefs.setString("auth_token", newAccessToken);
          
          if (newRefreshToken != null) {
            await prefs.setString("refresh_token", newRefreshToken);
          }

          print('✅ Tokens saved successfully');
          return newAccessToken;
        }
      }

      return null;
    } catch (e) {
      print('❌ Refresh token error: $e');
      return null;
    }
  }

  /// Process queued requests with new token
  Future<void> _processQueue(String newToken) async {
    print('🔄 Processing ${_requestQueue.length} queued requests...');
    
    for (final requestOptions in _requestQueue) {
      try {
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        await _dio.fetch(requestOptions);
      } catch (e) {
        print('❌ Failed to process queued request: $e');
      }
    }
    
    _requestQueue.clear();
  }

  /// Handle logout when refresh fails
  Future<void> _handleLogout() async {
    print('🚪 Logging out user due to token refresh failure...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("refresh_token");
    await prefs.remove("user_role");
    await prefs.remove("email");
    await prefs.remove("username");
    
    // The app will handle navigation to login screen
    // through the auth provider state change
  }
}