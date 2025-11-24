import 'package:dio/dio.dart';
import 'package:finance_management_frontend/models/requirement_transaction_detail.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/requirement_list.dart';
import '../models/requirement_item.dart';
import '../models/student_requirement.dart';
import '../models/item_transaction.dart';
import '../models/requirement_transaction_history_entry.dart';

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

      if (response.data is List) {
        return (response.data as List)
            .map((json) => RequirementList.fromJson(json))
            .toList();
      } else {
        return [RequirementList.fromJson(response.data)];
      }
    } catch (e) {
      throw Exception('Failed to load requirement lists: $e');
    }
  }

  Future<RequirementList> getRequirementList(String id) async {
    try {
      await _setAuthHeaders();
      final resp = await _dio.get(
        // FIX: correct route
        '/ItemLedger/requirement-lists/$id',
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch},
      );
      return RequirementList.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('Failed to load requirement list (${status ?? 'unknown'}): ${data ?? e.message}');
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
    int? academicYear,
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
      final resp = await _dio.get(
        '/ItemLedger/student-requirements/$id',
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch}, // cache buster
      );
      return StudentRequirement.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to load student requirement: ${e.response?.data ?? e.message}');
    }
  }

  // Single student assignment
  Future<StudentRequirement> assignRequirement({
    required String studentId,
    required String requirementListId,
    required List<String> selectedItemIds,
  }) async {
    try {
      await _setAuthHeaders();
      
      final response = await _dio.post('/ItemLedger/student-requirements', data: {
        'studentId': studentId,
        'requirementListId': requirementListId,
        'selectedItemIds': selectedItemIds,
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

  // Bulk student assignment
  Future<void> bulkAssignStudents({
    required List<String> studentIds,
    required String requirementListId,
    required List<String> selectedItemIds,
  }) async {
    try {
      await _setAuthHeaders();
      
      await _dio.post('/ItemLedger/bulk-assign-students', data: {
        'studentIds': studentIds,
        'requirementListId': requirementListId,
        'selectedItemIds': selectedItemIds,
      });
    } catch (e) {
      throw Exception('Failed to bulk assign students: $e');
    }
  }

  // Transactions
  Future<ItemTransaction> recordTransaction({
    required String studentRequirementId,
    required String transactionType, // 'Item' | 'Money'
    double? monetaryAmount,
    required List<TransactionItem> items,
    String? notes,
    Map<String, String>? perItemNotes,
    Map<String, double>? perItemMoney,
  }) async {
    try {
      await _setAuthHeaders();

      final payload = <String, dynamic>{
        'studentRequirementId': studentRequirementId,
        'transactionDate': DateTime.now().toIso8601String(),
        'items': <Map<String, dynamic>>[],
      };

      if (transactionType == 'Item') {
        if (items.isEmpty) throw Exception('At least one item is required for Item transactions');
        final missing = items.where((i) => (perItemNotes?[i.itemId] ?? '').trim().isEmpty).toList();
        if (missing.isNotEmpty) throw Exception('Notes are required for each item');

        payload['items'] = items.map((i) => {
          'transactionType': 'Item',
          'requirementItemId': i.itemId,   // uses RequirementStatus.itemId mapped above
          'itemQuantity': i.quantity,
          'moneyAmount': 0,
          'notes': perItemNotes![i.itemId]!.trim(),
        }).toList();
      } else if (transactionType == 'Money') {
        final amt = (monetaryAmount ?? 0);
        if (amt <= 0) throw Exception('Amount must be provided for Money transactions');
        if (notes == null || notes.trim().isEmpty) throw Exception('Notes are required for Money transactions');
        if (perItemMoney == null || perItemMoney.isEmpty) throw Exception('Money allocation per item is required');

        payload['items'] = perItemMoney.entries.map((e) => {
          'transactionType': 'Money',
          'requirementItemId': e.key,      // RequirementStatus.itemId per mapping
          'itemQuantity': 0,
          'moneyAmount': double.parse(e.value.toStringAsFixed(2)),
          'notes': notes.trim(),
        }).toList();
      } else {
        throw Exception('Unsupported transaction type: $transactionType');
      }

      // print('[POST] /ItemLedger/transactions payload: $payload');

      final response = await _dio.post('/ItemLedger/transactions', data: payload);
      return response.data is Map<String, dynamic>
          ? ItemTransaction.fromJson(response.data as Map<String, dynamic>)
          : ItemTransaction.fromJson(((response.data as List).first) as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final server = e.response?.data;
      throw Exception('Failed to record transaction (${status ?? 'unknown'}): ${server ?? e.message}');
    } catch (e) {
      throw Exception('Failed to record transaction: $e');
    }
  }

  Future<List<RequirementTransactionHistoryEntry>> getRequirementTransactions(String studentRequirementId) async {
    try {
      await _setAuthHeaders();
      final resp = await _dio.get('/ItemLedger/student-requirements/$studentRequirementId/transactions');
      print('Response data: ${resp.data}');
      if (resp.data is List) {
        final list = (resp.data as List)
            .where((e) => e != null)
            .map((e) => RequirementTransactionHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate)); // newest first
        return list;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load requirement transactions: $e');
    }
  }

  Future<RequirementTransactionDetail> getTransactionDetail(String id) async {
    try {
      await _setAuthHeaders();
      final resp = await _dio.get('/ItemLedger/transactions/$id');
      if (resp.data is List) {
        final list = resp.data as List;
        if (list.isEmpty) {
          throw Exception('Transaction not found');
        }
        return RequirementTransactionDetail.fromJson(Map<String, dynamic>.from(list.first));
      } else {
        return RequirementTransactionDetail.fromJson(Map<String, dynamic>.from(resp.data));
      }
    } on DioException catch (e) {
      throw Exception('Failed to load transaction: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to load transaction: $e');
    }
  }
}