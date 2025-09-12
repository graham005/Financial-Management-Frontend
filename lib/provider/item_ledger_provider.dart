import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/requirement_list.dart';
import '../models/requirement_item.dart';
import '../models/student_requirement.dart';
import '../models/item_transaction.dart';
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
      state = state.copyWith(lists: lists, isLoading: false);
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
    String? academicYear,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final requirements = await _service.getStudentRequirements(
        studentId: studentId,
        term: term,
        academicYear: academicYear,
        status: status,
      );
      state = state.copyWith(requirements: requirements, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> assignRequirement({
    required String studentId,
    required String requirementListId,
  }) async {
    try {
      await _service.assignRequirement(
        studentId: studentId,
        requirementListId: requirementListId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> recordTransaction({
    required String studentRequirementId,
    required String transactionType,
    double? monetaryAmount,
    required List<TransactionItem> items,
    String? remarks,
  }) async {
    try {
      await _service.recordTransaction(
        studentRequirementId: studentRequirementId,
        transactionType: transactionType,
        monetaryAmount: monetaryAmount,
        items: items,
        remarks: remarks,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
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

// Item Management Providers
final addRequirementItemProvider = FutureProvider.family<RequirementItem, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.addRequirementItem(
    requirementListId: params['requirementListId'],
    itemName: params['itemName'],
    requiredQuantity: params['requiredQuantity'],
    unit: params['unit'],
    unitPrice: params['unitPrice'],
    description: params['description'],
  );
});

final updateRequirementItemProvider = FutureProvider.family<RequirementItem, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(itemLedgerServiceProvider);
  return service.updateRequirementItem(
    id: params['id'],
    itemName: params['itemName'],
    requiredQuantity: params['requiredQuantity'],
    unit: params['unit'],
    unitPrice: params['unitPrice'],
    description: params['description'],
  );
});