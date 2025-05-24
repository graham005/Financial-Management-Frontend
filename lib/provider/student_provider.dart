import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Student {
  final String admissionNumber;
  final String name;
  final String grade;
  final String parentName;
  final String parentPhoneNumber;

  Student({
    required this.admissionNumber,
    required this.name,
    required this.grade,
    required this.parentName,
    required this.parentPhoneNumber
  });

  Map<String, dynamic> toJson() {
    return {
      "admissionNumber": admissionNumber,
      "name": name,
      "grade": grade,
      "parentName": parentName,
      "parentPhoneNumber": parentPhoneNumber
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      admissionNumber: json["addmissionNumber"], 
      name: json["name"], 
      grade: json["grade"], 
      parentName: json["parentName"],
      parentPhoneNumber: json["parentPnoneNumber"]
    );
  }
}

class StudentProvider extends StateNotifier<List<Student>>{
  StudentProvider(): super([]);

  final Dio _dio = Dio(BaseOptions(baseUrl: "")); //TODO: Add base url

  Future<void> fetchStudents() async {
    final response = await _dio.get("/student");
    final List<dynamic> data = response.data;
    state = data.map((json) => Student.fromJson(json)).toList();
    
  }
}

final studentProvider = StateNotifierProvider<StudentProvider, List<Student>> ((ref) {
  return StudentProvider();
});