import 'package:finance_management_frontend/models/requirement_transaction_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/requirement_list.dart';
import '../models/requirement_item.dart';
import '../models/student_requirement.dart';
import '../models/item_transaction.dart';
import '../models/requirement_transaction_history_entry.dart';
import '../services/item_ledger_service.dart';

// Service Provider
final itemLedgerServiceProvider = Provider<ItemLedgerService>((ref) {
  return ItemLedgerService();
});

// State Classes
class RequirementListState {
  final List<RequirementList> lists;
  final bool isLoading;
  final String? error;

  RequirementListState({
    this.lists = const [],
    this.isLoading = false,
    this.error,
  });

  RequirementListState copyWith({
    List<RequirementList>? lists,
    bool? isLoading,
    String? error,
  }) {
    return RequirementListState(
      lists: lists ?? this.lists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StudentRequirementState {
  final List<StudentRequirement> requirements;
  final bool isLoading;
  final String? error;

  StudentRequirementState({
    this.requirements = const [],
    this.isLoading = false,
    this.error,
  });

  StudentRequirementState copyWith({
    List<StudentRequirement>? requirements,
    bool? isLoading,
    String? error,
  }) {
    return StudentRequirementState(
      requirements: requirements ?? this.requirements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Requirement Lists Provider
class RequirementListNotifier extends StateNotifier<RequirementListState> {
  final ItemLedgerService _service;

  RequirementListNotifier(this._service) : super(RequirementListState());

  Future<void> loadRequirementLists({
    String? term,
    int? academicYear,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final lists = await _service.getRequirementLists(
        term: term,
        academicYear: academicYear,
        status: status,
      );

      // Fetch details per list to populate items (so itemCount != 0)
      final detailedLists = await Future.wait(lists.map((l) async {
        try {
          return await _service.getRequirementList(l.id);
        } catch (_) {
          return l; // fallback to lightweight list if detail fails
        }
      }));

      state = state.copyWith(lists: detailedLists, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createRequirementList({
    required String term,
    required int academicYear,
    required String createdBy,
  }) async {
    try {
      final newList = await _service.createRequirementList(
        term: term,
        academicYear: academicYear,
        createdBy: createdBy,
      );
      state = state.copyWith(lists: [...state.lists, newList]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> archiveRequirementList(String id) async {
    try {
      await _service.archiveRequirementList(id);
      final updatedLists = state.lists.where((list) => list.id != id).toList();
      state = state.copyWith(lists: updatedLists);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addRequirementItem({
    required String requirementListId,
    required String itemName,
    required int requiredQuantity,
    required String unit,
    required double unitPrice,
    String? description,
  }) async {
    try {
      await _service.addRequirementItem(
        requirementListId: requirementListId,
        itemName: itemName,
        requiredQuantity: requiredQuantity,
        unit: unit,
        unitPrice: unitPrice,
        description: description,
      );
      // Refresh the requirement list to show the new item
      await loadRequirementLists();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateRequirementItem({
    required String id,
    required String itemName,
    required int requiredQuantity,
    required String unit,
    required double unitPrice,
    String? description,
  }) async {
    try {
      await _service.updateRequirementItem(
        id: id,
        itemName: itemName,
        requiredQuantity: requiredQuantity,
        unit: unit,
        unitPrice: unitPrice,
        description: description,
      );
      // Refresh the requirement list to show updated item
      await loadRequirementLists();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteRequirementItem(String id) async {
    try {
      await _service.deleteRequirementItem(id);
      // Refresh the requirement list to remove deleted item
      await loadRequirementLists();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final requirementListProvider = StateNotifierProvider<RequirementListNotifier, RequirementListState>((ref) {
  final service = ref.watch(itemLedgerServiceProvider);
  return RequirementListNotifier(service);
});

// Selected Requirement List Provider
final selectedRequirementListProvider = StateProvider<RequirementList?>((ref) => null);

// Requirement List Details Provider
final requirementListDetailsProvider = FutureProvider.family<RequirementList, String>((ref, id) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.getRequirementList(id);
});

// Student Requirements Provider
class StudentRequirementNotifier extends StateNotifier<StudentRequirementState> {
  final ItemLedgerService _service;

  StudentRequirementNotifier(this._service) : super(StudentRequirementState());

  Future<void> loadStudentRequirements({
    String? studentId,
    String? term,
    int? academicYear,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final basic = await _service.getStudentRequirements(
        studentId: studentId,
        term: term,
        academicYear: academicYear,
        status: status,
      );

      // Enrich with details so items are populated and totals compute correctly
      final detailed = await Future.wait(basic.map((r) async {
        try {
          return await _service.getStudentRequirement(r.id);
        } catch (_) {
          return r; // fallback if details fail
        }
      }));

      state = state.copyWith(requirements: detailed, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Fixed: Added missing selectedItemIds parameter
  Future<bool> assignRequirement({
    required String studentId,
    required String requirementListId,
    required List<String> selectedItemIds,
  }) async {
    try {
      await _service.assignRequirement(
        studentId: studentId,
        requirementListId: requirementListId,
        selectedItemIds: selectedItemIds,
      );
      // Refresh the student requirements list
      await loadStudentRequirements();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Added: Bulk assignment method
  Future<bool> bulkAssignStudents({
    required List<String> studentIds,
    required String requirementListId,
    required List<String> selectedItemIds,
  }) async {
    try {
      await _service.bulkAssignStudents(
        studentIds: studentIds,
        requirementListId: requirementListId,
        selectedItemIds: selectedItemIds,
      );
      // Refresh the student requirements list
      await loadStudentRequirements();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<String?> recordTransaction({
    required String studentRequirementId,
    required String transactionType,
    double? monetaryAmount,
    required List<TransactionItem> items,
    String? notes,
    Map<String, String>? perItemNotes,
    Map<String, double>? perItemMoney,
  }) async {
    try {
      final transaction = await _service.recordTransaction(
        studentRequirementId: studentRequirementId,
        transactionType: transactionType,
        monetaryAmount: monetaryAmount,
        items: items,
        notes: notes,
        perItemNotes: perItemNotes,
        perItemMoney: perItemMoney,
      );
      
      await loadStudentRequirements();
      
      // Return the transaction ID so it can be used for receipt printing
      return transaction.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final studentRequirementProvider = StateNotifierProvider<StudentRequirementNotifier, StudentRequirementState>((ref) {
  final service = ref.watch(itemLedgerServiceProvider);
  return StudentRequirementNotifier(service);
});

// Student Requirement Details Provider
final studentRequirementDetailsProvider = FutureProvider.family<StudentRequirement, String>((ref, id) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.getStudentRequirement(id);
});

// Requirement Item Provider
final requirementItemProvider = FutureProvider.family<RequirementItem, String>((ref, id) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.getRequirementItem(id);
});

// Transaction Provider for recording individual transactions
final recordTransactionProvider = FutureProvider.family<ItemTransaction, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.recordTransaction(
    studentRequirementId: params['studentRequirementId'],
    transactionType: params['transactionType'],
    monetaryAmount: params['monetaryAmount'],
    items: params['items'] as List<TransactionItem>,
    notes: params['notes'],
    perItemNotes: params['perItemNotes'] as Map<String, String>?,
    perItemMoney: params['perItemMoney'] as Map<String, double>?,
  );
});

// NEW: Requirement transaction history provider
final requirementTransactionHistoryProvider = FutureProvider.family<List<RequirementTransactionHistoryEntry>, String>((ref, studentRequirementId) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.getRequirementTransactions(studentRequirementId);
});

final requirementTransactionDetailProvider = FutureProvider.family<RequirementTransactionDetail, String>((ref, transactionId) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.getTransactionDetail(transactionId);
});