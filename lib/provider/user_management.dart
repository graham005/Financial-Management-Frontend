import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      id: json["id"], 
      username: json["username"], 
      email: json["email"], 
      role: json["role"]
    );
  }
}

class UserProvider extends StateNotifier<List<User>> {
  UserProvider(): super([]);

  final Dio _dio = Dio(BaseOptions(baseUrl: ""));

  Future<void> fetchUsers() async {
    final response = await _dio.get("/user");
    final List<dynamic> data = response.data;
    state = data.map((json) => User.fromJson(json)).toList();
  }

}


final userProvider = StateNotifierProvider<UserProvider, List<User>> ((ref) {
  return UserProvider();
});
