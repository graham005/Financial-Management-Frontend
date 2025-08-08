import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class StudentProvider extends StateNotifier<List<Student>> {
  StudentProvider() : super([]);

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> fetchStudents() async {
    final response = await _dio.get("/admin/Student");
    final List<dynamic> data = response.data;
    state = data.map((json) => Student.fromJson(json)).toList();
  }

  Future<void> addStudent(Student student) async {
    await _dio.post("/admin/Student", data: student.toJson());
    await fetchStudents();
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _dio.patch("/admin/Student/$id", data: data);
    await fetchStudents();
  }

  Future<void> deleteStudent(String id) async {
    await _dio.delete("/admin/Student/$id");
    await fetchStudents();
  }
}

final studentProvider = StateNotifierProvider<StudentProvider, List<Student>>((ref) {
  return StudentProvider();
});