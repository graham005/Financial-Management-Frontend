// lib/provider/thermal_printer_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/printer_config.dart';
import '../services/thermal_printer_service.dart';
import '../models/thermal_receipt.dart';

// Service Provider
final thermalPrinterServiceProvider = Provider<ThermalPrinterService>((ref) {
  return ThermalPrinterService();
});

// Printer configurations state
class PrinterConfigState {
  final List<PrinterConfig> configs;
  final PrinterConfig? selectedPrinter;
  final bool isLoading;
  final String? error;

  const PrinterConfigState({
    this.configs = const [],
    this.selectedPrinter,
    this.isLoading = false,
    this.error,
  });

  PrinterConfigState copyWith({
    List<PrinterConfig>? configs,
    PrinterConfig? selectedPrinter,
    bool? isLoading,
    String? error,
  }) {
    return PrinterConfigState(
      configs: configs ?? this.configs,
      selectedPrinter: selectedPrinter ?? this.selectedPrinter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Printer configuration notifier
class PrinterConfigNotifier extends StateNotifier<PrinterConfigState> {
  final ThermalPrinterService _service;

  PrinterConfigNotifier(this._service) : super(const PrinterConfigState()) {
    loadSavedPrinters();
  }

  Future<void> loadSavedPrinters() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final configs = await _service.getSavedPrinters();
      final defaultPrinter = await _service.getDefaultPrinter();
      
      state = state.copyWith(
        configs: configs,
        selectedPrinter: defaultPrinter,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> discoverNetworkPrinters() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final discoveredPrinters = await _service.discoverNetworkPrinters();
      
      // Add discovered printers to existing configs (avoid duplicates)
      final existingIds = state.configs.map((c) => c.id).toSet();
      final newPrinters = discoveredPrinters.where((p) => !existingIds.contains(p.id)).toList();
      
      state = state.copyWith(
        configs: [...state.configs, ...newPrinters],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> savePrinter(PrinterConfig config) async {
    try {
      await _service.savePrinterConfig(config);
      await loadSavedPrinters(); // Reload to reflect changes
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> connectToPrinter(PrinterConfig config) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await _service.connectToPrinter(config);
      
      state = state.copyWith(
        selectedPrinter: success ? config : null,
        isLoading: false,
      );
      
      return success;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      state = state.copyWith(selectedPrinter: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Main provider
final printerConfigProvider = StateNotifierProvider<PrinterConfigNotifier, PrinterConfigState>((ref) {
  final service = ref.watch(thermalPrinterServiceProvider);
  return PrinterConfigNotifier(service);
});

// Printer status stream provider
final printerStatusProvider = StreamProvider<PrinterStatus>((ref) {
  final service = ref.watch(thermalPrinterServiceProvider);
  return service.statusStream;
});

// Print operation providers
final printReceiptProvider = FutureProvider.family<bool, ThermalReceipt>((ref, receipt) async {
  try {
    final service = ref.watch(thermalPrinterServiceProvider);
    return await service.printReceipt(receipt);
  } catch (e) {
    print('Print receipt provider error: $e');
    throw Exception('Print failed: $e');
  }
});

final testPrintProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(thermalPrinterServiceProvider);
  return service.printTestReceipt();
});