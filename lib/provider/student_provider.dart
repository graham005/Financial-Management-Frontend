import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Student {
  final String id;
  final String admissionNumber;
  final String name;
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthdate;
  final String gradeName;
  final String parentName;
  final String parentFirstName;
  final String parentLastName;
  final String parentPhoneNumber;

  Student({
    required this.id,
    required this.admissionNumber,
    required this.name,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthdate,
    required this.gradeName,
    required this.parentName,
    required this.parentFirstName,
    required this.parentLastName,
    required this.parentPhoneNumber,
  });

  String get fullName => '$firstName $middleName $lastName'.trim();
  String get displayName => '$fullName ($admissionNumber)';

  Map<String, dynamic> toJson() {
    return {
      "admissionNumber": admissionNumber,
      "name": name,
      "firstName": firstName,
      "middleName": middleName,
      "lastName": lastName,
      "birthdate": birthdate,
      "gradeName": gradeName,
      "parentName": parentName,
      "parentFirstName": parentFirstName,
      "parentLastName": parentLastName,
      "parentPhoneNumber": parentPhoneNumber,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json["id"].toString(),
      admissionNumber: json["admissionNumber"] ?? '',
      name: json["name"] ?? '',
      firstName: json["firstName"] ?? '',
      middleName: json["middleName"] ?? '',
      lastName: json["lastName"] ?? '',
      birthdate: json["birthdate"] ?? '',
      gradeName: json["gradeName"] ?? '',
      parentName: json["parentName"] ?? '',
      parentFirstName: json["parentFirstName"] ?? '',
      parentLastName: json["parentLastName"] ?? '',
      parentPhoneNumber: json["parentPhoneNumber"] ?? '',
    );
  }
}

class StudentProvider extends StateNotifier<AsyncValue<List<Student>>> {
  StudentProvider() : super(const AsyncValue.loading()) {
    fetchStudents();
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> _setAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchStudents() async {
    try {
      state = const AsyncValue.loading();
      await _setAuthHeaders();
      
      final response = await _dio.get("/admin/Student");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final students = data.map((json) => Student.fromJson(json)).toList();
        state = AsyncValue.data(students);
      } else {
        state = AsyncValue.error("Failed to fetch students", StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addStudent(Student student) async {
    try {
      await _setAuthHeaders();
      await _dio.post("/admin/Student", data: student.toJson());
      await fetchStudents();
    } catch (e) {
      print("Error adding student: $e");
    }
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      await _setAuthHeaders();
      await _dio.patch("/admin/Student/$id", data: data);
      await fetchStudents();
    } catch (e) {
      print("Error updating student: $e");
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _setAuthHeaders();
      await _dio.delete("/admin/Student/$id");
      await fetchStudents();
    } catch (e) {
      print("Error deleting student: $e");
    }
  }

  List<Student> searchStudents(String query) {
    return state.when(
      data: (students) {
        if (query.isEmpty) return students;
        
        return students.where((student) {
          final searchQuery = query.toLowerCase();
          return student.fullName.toLowerCase().contains(searchQuery) ||
                 student.admissionNumber.toLowerCase().contains(searchQuery) ||
                 student.gradeName.toLowerCase().contains(searchQuery);
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }
}

final studentProvider = StateNotifierProvider<StudentProvider, AsyncValue<List<Student>>>((ref) {
  return StudentProvider();
});