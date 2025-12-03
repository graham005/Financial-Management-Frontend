import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_interceptor.dart';


class DeleteService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  DeleteService(): super(){
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Future<void> deleteUser(BuildContext context, String userId) async{
    try{
      await _dio.delete("user/$userId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("User delted successfully"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("An error occurred while deleting the user: $e")),
      );
    }
  }

  Future<void> deleteStudent(BuildContext context, String studentId) async {
    try {
      await _dio.delete("/student/$studentId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("Student deleted successfully"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("An error occurred while deleting the student: $e")),
      );
    }
  }

  Future<void> deleteFeeStructure(BuildContext context, int feeStructureId) async {
    try {
      await _dio.delete("/feestructure/$feeStructureId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("Fee structure deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("An error occurred while deleting the fee structure: $e")),
      );
    }
  }

  Future<void> deleteOtherFee(BuildContext context, int feeId) async {
    try {
      await _dio.delete("/other-fees/$feeId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("Other fee deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText("An error occured while deleting the fee: $e")),
      );
    }
  }
}