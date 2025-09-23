import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thermal_receipt.dart';
import '../services/thermal_receipt_service.dart';

// Service Provider
final thermalReceiptServiceProvider = Provider<ThermalReceiptService>((ref) {
  return ThermalReceiptService();
});

// State for thermal receipt operations
class ThermalReceiptState {
  final ThermalReceipt? receipt;
  final bool isLoading;
  final String? error;

  ThermalReceiptState({
    this.receipt,
    this.isLoading = false,
    this.error,
  });

  ThermalReceiptState copyWith({
    ThermalReceipt? receipt,
    bool? isLoading,
    String? error,
  }) {
    return ThermalReceiptState(
      receipt: receipt,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Thermal Receipt Notifier
class ThermalReceiptNotifier extends StateNotifier<ThermalReceiptState> {
  final ThermalReceiptService _service;

  ThermalReceiptNotifier(this._service) : super(ThermalReceiptState());

  /// Fetch thermal receipt data for a transaction
  Future<void> fetchThermalReceipt(String transactionId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final receipt = await _service.getThermalReceipt(transactionId);
      state = state.copyWith(receipt: receipt, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Clear current receipt data
  void clearReceipt() {
    state = ThermalReceiptState();
  }

  /// Check if receipt is available for transaction
  Future<bool> checkReceiptAvailability(String transactionId) async {
    try {
      return await _service.isReceiptAvailable(transactionId);
    } catch (e) {
      return false;
    }
  }
}

// Main Provider
final thermalReceiptProvider = StateNotifierProvider<ThermalReceiptNotifier, ThermalReceiptState>((ref) {
  final service = ref.watch(thermalReceiptServiceProvider);
  return ThermalReceiptNotifier(service);
});

// Family provider for specific transaction receipts
final thermalReceiptByTransactionProvider = FutureProvider.family<ThermalReceipt, String>((ref, transactionId) async {
  final service = ref.watch(thermalReceiptServiceProvider);
  return service.getThermalReceipt(transactionId);
});

// Provider for batch receipt operations
class BatchReceiptNotifier extends StateNotifier<AsyncValue<List<ThermalReceipt>>> {
  final ThermalReceiptService _service;

  BatchReceiptNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> fetchMultipleReceipts(List<String> transactionIds) async {
    state = const AsyncValue.loading();
    
    try {
      final receipts = await _service.getThermalReceipts(transactionIds);
      state = AsyncValue.data(receipts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final batchReceiptProvider = StateNotifierProvider<BatchReceiptNotifier, AsyncValue<List<ThermalReceipt>>>((ref) {
  final service = ref.watch(thermalReceiptServiceProvider);
  return BatchReceiptNotifier(service);
});