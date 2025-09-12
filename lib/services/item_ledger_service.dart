import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/requirement_list.dart';
import '../models/requirement_item.dart';
import '../models/student_requirement.dart';
import '../models/item_transaction.dart';

class ItemLedgerService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  Future<void> _setAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // Requirement Lists
  Future<List<RequirementList>> getRequirementLists({
    String? term,
    int? academicYear,
    String? status,
  }) async {
    try {
      await _setAuthHeaders();
      
      final queryParams = <String, dynamic>{};
      if (term != null) queryParams['term'] = term;
      if (academicYear != null) queryParams['academicYear'] = academicYear;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/ItemLedger/requirement-lists',
        queryParameters: queryParams,
      );

      // Handle both single object and list responses
      if (response.data is List) {
        return (response.data as List)
            .map((json) => RequirementList.fromJson(json))
            .toList();
      } else {
        // If it's a single object, wrap it in a list
        return [RequirementList.fromJson(response.data)];
      }
    } catch (e) {
      throw Exception('Failed to load requirement lists: $e');
    }
  }

  Future<RequirementList> getRequirementList(String id) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get('/ItemLedger/requirement-lists/$id');
      
      // Check if response is a List or Map
      if (response.data is List) {
        // If it's a list, take the first item (assuming it's the requested item)
        if ((response.data as List).isNotEmpty) {
          return RequirementList.fromJson((response.data as List).first);
        } else {
          throw Exception('Requirement list not found');
        }
      } else if (response.data is Map<String, dynamic>) {
        // If it's a map, parse it directly
        return RequirementList.fromJson(response.data);
      } else {
        throw Exception('Unexpected response format: ${response.data.runtimeType}');
      }
    } catch (e) {
      throw Exception('Failed to load requirement list: $e');
    }
  }

  Future<RequirementList> createRequirementList({
    required String term,
    required int academicYear,
    required String createdBy,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.post('/ItemLedger/requirement-lists', data: {
        'term': term,
        'academicYear': academicYear,
        'createdBy': createdBy,
      });
      
      // Handle both single object and list responses
      if (response.data is List) {
        if ((response.data as List).isNotEmpty) {
          return RequirementList.fromJson((response.data as List).first);
        } else {
          throw Exception('No data returned from create operation');
        }
      } else {
        return RequirementList.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Failed to create requirement list: $e');
    }
  }

  Future<void> archiveRequirementList(String id) async {
    try {
      await _setAuthHeaders();
      
      await _dio.patch('/ItemLedger/requirement-lists/$id/archive');
    } catch (e) {
      throw Exception('Failed to archive requirement list: $e');
    }
  }

  // Requirement Items
  Future<RequirementItem> getRequirementItem(String id) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get('/ItemLedger/requirement-items/$id');
      
      if (response.data is List) {
        if ((response.data as List).isNotEmpty) {
          return RequirementItem.fromJson((response.data as List).first);
        } else {
          throw Exception('Requirement item not found');
        }
      } else {
        return RequirementItem.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Failed to load requirement item: $e');
    }
  }

  Future<RequirementItem> addRequirementItem({
    required String requirementListId,
    required String itemName,
    required int requiredQuantity,
    required String unit,
    required double unitPrice,
    String? description,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.post(
        '/ItemLedger/requirement-lists/$requirementListId/items',
        data: {
          'itemName': itemName,
          'requiredQuantity': requiredQuantity,
          'unit': unit,
          'unitPrice': unitPrice,
          'description': description,
        },
      );
      
      if (response.data is List) {
        if ((response.data as List).isNotEmpty) {
          return RequirementItem.fromJson((response.data as List).first);
        } else {
          throw Exception('No data returned from add operation');
        }
      } else {
        return RequirementItem.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Failed to add requirement item: $e');
    }
  }

  Future<RequirementItem> updateRequirementItem({
    required String id,
    required String itemName,
    required int requiredQuantity,
    required String unit,
    required double unitPrice,
    String? description,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.patch('/ItemLedger/requirement-items/$id', data: {
        'itemName': itemName,
        'requiredQuantity': requiredQuantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'description': description,
      });
      
      if (response.data is List) {
        if ((response.data as List).isNotEmpty) {
          return RequirementItem.fromJson((response.data as List).first);
        } else {
          throw Exception('No data returned from update operation');
        }
      } else {
        return RequirementItem.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Failed to update requirement item: $e');
    }
  }

  Future<void> deleteRequirementItem(String id) async {
    try {
      await _setAuthHeaders();
      
      await _dio.delete('/ItemLedger/requirement-items/$id');
    } catch (e) {
      throw Exception('Failed to delete requirement item: $e');
    }
  }

  // Student Requirements
  Future<List<StudentRequirement>> getStudentRequirements({
    String? studentId,
    String? term,
    String? academicYear,
    String? status,
  }) async {
    try {
      await _setAuthHeaders();
      
      final queryParams = <String, dynamic>{};
      if (studentId != null) queryParams['studentId'] = studentId;
      if (term != null) queryParams['term'] = term;
      if (academicYear != null) queryParams['academicYear'] = academicYear;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/ItemLedger/student-requirements',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => StudentRequirement.fromJson(json))
            .toList();
      } else {
        return [StudentRequirement.fromJson(response.data)];
      }
    } catch (e) {
      throw Exception('Failed to load student requirements: $e');
    }
  }

  Future<StudentRequirement> getStudentRequirement(String id) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.get('/ItemLedger/student-requirements/$id');
      
      if (response.data is List) {
        if ((response.data as List).isNotEmpty) {
          return StudentRequirement.fromJson((response.data as List).first);
        } else {
          throw Exception('Student requirement not found');
        }
      } else {
        return StudentRequirement.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Failed to load student requirement: $e');
    }
  }

  Future<StudentRequirement> assignRequirement({
    required String studentId,
    required String requirementListId,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.post('/ItemLedger/student-requirements', data: {
        'studentId': studentId,
        'requirementListId': requirementListId,
      });
      
      if (response.data is List) {
        if ((response.data as List).isNotEmpty) {
          return StudentRequirement.fromJson((response.data as List).first);
        } else {
          throw Exception('No data returned from assign operation');
        }
      } else {
        return StudentRequirement.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Failed to assign requirement: $e');
    }
  }

  Future<void> bulkAssignStudents({
    required String requirementListId,
    required List<String> studentIds,
  }) async {
    try {
      await _setAuthHeaders();
      
      await _dio.post('/ItemLedger/assign-students', data: {
        'requirementListId': requirementListId,
        'studentIds': studentIds,
      });
    } catch (e) {
      throw Exception('Failed to bulk assign students: $e');
    }
  }

  // Transactions
  Future<ItemTransaction> recordTransaction({
    required String studentRequirementId,
    required String transactionType,
    double? monetaryAmount,
    required List<TransactionItem> items,
    String? remarks,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.post('/ItemLedger/transactions', data: {
        'studentRequirementId': studentRequirementId,
        'transactionType': transactionType,
        'monetaryAmount': monetaryAmount,
        'items': items.map((item) => item.toJson()).toList(),
        'remarks': remarks,
      });
      
      if (response.data is List) {
        if ((response.data as List).isNotEmpty) {
          return ItemTransaction.fromJson((response.data as List).first);
        } else {
          throw Exception('No data returned from record transaction operation');
        }
      } else {
        return ItemTransaction.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Failed to record transaction: $e');
    }
  }
}