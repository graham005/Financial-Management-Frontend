import 'package:dio/dio.dart';
import 'package:flutter/material.dart';


class DeleteService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "")); // TODO: Add base URL from .env

  Future<void> deleteUser(BuildContext context, String userId) async{
    try{
      await _dio.delete("user/$userId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User delted successfully"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while deleting the user: $e")),
      );
    }
  }

  Future<void> deleteStudent(BuildContext context, String studentId) async {
    try {
      await _dio.delete("/student/$studentId"); // TODO:Check if corresponds with API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Student deleted successfully"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while deleting the student: $e")),
      );
    }
  }

  Future<void> deleteFeeStructure(BuildContext context, int feeStructureId) async {
    try {
      await _dio.delete("/feestructure/$feeStructureId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fee structure deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while deleting the fee structure: $e")),
      );
    }
  }
}