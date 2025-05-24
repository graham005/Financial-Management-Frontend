import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeeStructure {
  final int id;
  final String grade;
  final double term1Fee;
  final double term2Fee;
  final double term3Fee;
  final double totalFee;

  FeeStructure ({
    required this.id,
    required this.grade,
    required this.term1Fee,
    required this.term2Fee,
    required this.term3Fee,
    required this.totalFee,
  });

  Map<String, dynamic> toJson(){
    return {
      "id": id,
      "grade": grade,
      "term1Fee": term1Fee,
      "term2Fee": term2Fee,
      "term3Fee": term3Fee,
      "totalFee": totalFee,
    };
  }

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: json["id"], 
      grade: json["grade"], 
      term1Fee: json["term1Fee"].toDouble(), 
      term2Fee: json["term2Fee"].toDouble(), 
      term3Fee: json["term3Fee"].toDouble(), 
      totalFee: json["totalFee"].toDouble(),
    );
  }
}

class FeeStructureProvider extends StateNotifier<List<FeeStructure>>{
  FeeStructureProvider(): super([]);

  final Dio _dio = Dio(BaseOptions(baseUrl: ""));

  Future<void> fetchFeeStructure()async {
    final response = await _dio.get("/feestructure");
    final List<dynamic> data = response.data;
    state = data.map((json) => FeeStructure.fromJson(json)).toList();
  }
}

final feeStructureProvider = StateNotifierProvider<FeeStructureProvider, List<FeeStructure>>((ref) {
  return FeeStructureProvider();
});