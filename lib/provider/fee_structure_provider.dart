import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fee_structure.dart'; // Import from models

class FeeStructureProvider extends StateNotifier<List<FeeStructure>> {
  FeeStructureProvider(): super([]);

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> fetchFeeStructures() async {
    final response = await _dio.get("/admin/FeeStructure");
    final List<dynamic> data = response.data;
    state = data.map((json) => FeeStructure.fromJson(json)).toList();
  }

  Future<FeeStructure?> getFeeStructureById(String id) async {
    final response = await _dio.get("/admin/FeeStructure/$id");
    if (response.statusCode == 200) {
      return FeeStructure.fromJson(response.data);
    }
    return null;
  }

  Future<void> addFeeStructure(Map<String, dynamic> data) async {
    await _dio.post("/admin/FeeStructure", data: data);
    await fetchFeeStructures();
  }

  Future<void> updateFeeStructure(String id, Map<String, dynamic> data) async {
    await _dio.patch("/admin/FeeStructure/$id", data: data);
    await fetchFeeStructures();
  }

  Future<void> deleteFeeStructure(String id) async {
    await _dio.delete("/admin/FeeStructure/$id");
    await fetchFeeStructures();
  }
}

final feeStructureProvider = StateNotifierProvider<FeeStructureProvider, List<FeeStructure>>((ref) {
  return FeeStructureProvider();
});