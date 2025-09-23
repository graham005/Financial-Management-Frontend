// lib/services/thermal_printer_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/printer_config.dart';
import '../models/thermal_receipt.dart';

class ThermalPrinterService {
  static const String _configKey = 'printer_configs';
  static const String _defaultPrinterKey = 'default_printer';

  // Singleton
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  NetworkPrinter? _currentPrinter;
  PrinterConfig? _currentConfig;
  final StreamController<PrinterStatus> _statusController = StreamController<PrinterStatus>.broadcast();

  Stream<PrinterStatus> get statusStream => _statusController.stream;

  /// Get stored printer configurations
  Future<List<PrinterConfig>> getSavedPrinters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = prefs.getStringList(_configKey) ?? [];
      return configsJson.map((json) => PrinterConfig.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save printer configuration
  Future<void> savePrinterConfig(PrinterConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configs = await getSavedPrinters();
      
      // Remove existing config with same ID
      configs.removeWhere((c) => c.id == config.id);
      configs.add(config);
      
      final configsJson = configs.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_configKey, configsJson);

      if (config.isDefault) {
        await prefs.setString(_defaultPrinterKey, config.id);
      }
    } catch (e) {
      throw Exception('Failed to save printer configuration: $e');
    }
  }

  /// Get default printer
  Future<PrinterConfig?> getDefaultPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultId = prefs.getString(_defaultPrinterKey);
      
      if (defaultId == null) return null;
      
      final configs = await getSavedPrinters();
      return configs.where((c) => c.id == defaultId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Discover network printers on local network
  Future<List<PrinterConfig>> discoverNetworkPrinters() async {
    final discoveredPrinters = <PrinterConfig>[];
    
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      
      if (wifiIP == null) return discoveredPrinters;
      
      // Get network base (e.g., 192.168.1.x)
      final parts = wifiIP.split('.');
      if (parts.length != 4) return discoveredPrinters;
      
      final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
      
      // Common printer ports
      const printerPorts = [9100, 515, 631];
      
      // Scan network range (limited to reduce scan time)
      final futures = <Future>[];
      
      for (int i = 1; i <= 254; i++) {
        for (final port in printerPorts) {
          futures.add(_testPrinterConnection('$networkBase.$i', port).then((isReachable) {
            if (isReachable) {
              discoveredPrinters.add(PrinterConfig(
                id: 'network_${networkBase}_${i}_$port',
                name: 'Network Printer ($networkBase.$i:$port)',
                connectionType: PrinterConnectionType.network,
                address: '$networkBase.$i',
                port: port,
              ));
            }
          }));
        }
      }
      
      // Wait for all scans to complete with timeout
      await Future.wait(futures).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Network printer discovery error: $e');
    }
    
    return discoveredPrinters;
  }

  /// Test printer connection
  Future<bool> _testPrinterConnection(String address, int port) async {
    try {
      final socket = await Socket.connect(
        address,
        port,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Connect to printer
  Future<bool> connectToPrinter(PrinterConfig config) async {
    try {
      await disconnect();
      
      switch (config.connectionType) {
        case PrinterConnectionType.network:
          return await _connectNetworkPrinter(config);
        case PrinterConnectionType.usb:
          return await _connectUSBPrinter(config);
        case PrinterConnectionType.bluetooth:
          return await _connectBluetoothPrinter(config);
        case PrinterConnectionType.none:
          return false;
      }
    } catch (e) {
      _updateStatus(PrinterStatus(
        isConnected: false,
        error: 'Connection failed: $e',
      ));
      return false;
    }
  }

  Future<bool> _connectNetworkPrinter(PrinterConfig config) async {
    try {
      const PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      
      final printer = NetworkPrinter(paper, profile);
      final result = await printer.connect(config.address, port: config.port);
      
      if (result == PosPrintResult.success) {
        _currentPrinter = printer;
        _currentConfig = config;
        _updateStatus(const PrinterStatus(isConnected: true, isOnline: true));
        return true;
      } else {
        _updateStatus(PrinterStatus(
          isConnected: false,
          error: 'Network connection failed: $result',
        ));
        return false;
      }
    } catch (e) {
      _updateStatus(PrinterStatus(
        isConnected: false,
        error: 'Network printer error: $e',
      ));
      return false;
    }
  }

  Future<bool> _connectUSBPrinter(PrinterConfig config) async {
    // USB printer implementation would go here
    // This requires platform-specific code for Windows/Linux/macOS
    _updateStatus(const PrinterStatus(
      isConnected: false,
      error: 'USB printer support not implemented in this demo',
    ));
    return false;
  }

  Future<bool> _connectBluetoothPrinter(PrinterConfig config) async {
    // Bluetooth printer implementation would go here
    _updateStatus(const PrinterStatus(
      isConnected: false,
      error: 'Bluetooth printer support not implemented in this demo',
    ));
    return false;
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    try {
      _currentPrinter?.disconnect();
      _currentPrinter = null;
      _currentConfig = null;
      _updateStatus(const PrinterStatus(isConnected: false));
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  /// Print thermal receipt
  Future<bool> printReceipt(ThermalReceipt receipt) async {
    if (_currentPrinter == null || _currentConfig == null) {
      throw Exception('No printer connected');
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(_currentConfig!.paperSize, profile);
      
      final bytes = _generateReceiptBytes(receipt, generator);

      // Network printers often don't expose printTicket/writeBytes.
      // Fallback: send raw ESC/POS bytes over TCP using the configured address/port.
      if (_currentPrinter is NetworkPrinter) {
        final host = _currentConfig!.address;
        final port = _currentConfig!.port; // default RAW/TCP port for many printers
        try {
          final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
          socket.add(Uint8List.fromList(bytes));
          await socket.flush();
          await socket.close();
          return true;
        } catch (e) {
          print('Network print error: $e');
          return false;
        }
      } else {
        // For other printer implementations (USB/Bluetooth) that provide printTicket
        try {
          final result = await (_currentPrinter as dynamic).printTicket(bytes);
          return result == PosPrintResult.success;
        } catch (e) {
          print('Print error calling printTicket: $e');
          return false;
        }
      }
    } catch (e) {
      _updateStatus(PrinterStatus(
        isConnected: true,
        isOnline: false,
        error: 'Print error: $e',
      ));
      rethrow;
    }
  }

  /// Test print functionality
  Future<bool> printTestReceipt() async {
    if (_currentPrinter == null || _currentConfig == null) {
      throw Exception('No printer connected');
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(_currentConfig!.paperSize, profile);
      
      List<int> bytes = [];
      
      bytes += generator.text('TEST RECEIPT', styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ));
      
      bytes += generator.text('Financial Management System', styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ));
      
      bytes += generator.hr();
      bytes += generator.text('Test Date: ${DateTime.now()}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Printer: ${_currentConfig!.name}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Paper Size: ${_currentConfig!.paperSize == PaperSize.mm58 ? "58mm" : "80mm"}', 
          styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.hr();
      bytes += generator.text('If you can read this, your printer is working correctly!', 
          styles: const PosStyles(align: PosAlign.center));
      
      // finalize receipt (example: feed and cut)
      bytes += generator.feed(2);
      bytes += generator.cut();
      
      // Network printers in many esc_pos_printer versions don't expose printTicket/writeBytes.
      // Fallback: send raw ESC/POS bytes over TCP using the configured address/port.
      if (_currentPrinter is NetworkPrinter) {
        final host = _currentConfig!.address;
        final port = _currentConfig!.port; // common RAW/TCP port
        try {
          final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
          socket.add(Uint8List.fromList(bytes));
          await socket.flush();
          await socket.close();
          return true;
        } catch (e) {
          print('Network print error: $e');
          return false;
        }
      } else {
        // For printers (USB/Bluetooth) that offer printTicket
        try {
          final result = await (_currentPrinter as dynamic).printTicket(bytes);
          return result == PosPrintResult.success;
        } catch (e) {
          print('Print error calling printTicket: $e');
          return false;
        }
      }
    } catch (e) {
      throw Exception('Test print failed: $e');
    }
  }

  /// Generate ESC/POS bytes for receipt
  List<int> _generateReceiptBytes(ThermalReceipt receipt, Generator generator) {
    List<int> bytes = [];
    
    // Header
    bytes += generator.text(
      receipt.organization.name,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    
    bytes += generator.text(
      receipt.organization.address,
      styles: const PosStyles(align: PosAlign.center),
    );
    
    bytes += generator.text(
      'Tel: ${receipt.organization.phone}',
      styles: const PosStyles(align: PosAlign.center),
    );
    
    if (receipt.organization.email.isNotEmpty) {
      bytes += generator.text(
        receipt.organization.email,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    
    bytes += generator.feed(1);
    bytes += generator.text(
      'PAYMENT RECEIPT',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
        bold: true,
      ),
    );
    
    bytes += generator.hr();
    
    // Receipt info
    bytes += generator.row([
      PosColumn(text: 'Receipt No:', width: 6),
      PosColumn(text: receipt.receiptNumber, width: 6),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Date:', width: 6),
      PosColumn(text: _formatDateTime(receipt.receiptDate), width: 6),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Staff:', width: 6),
      PosColumn(text: receipt.staffMember, width: 6),
    ]);
    
    bytes += generator.hr();
    
    // Student information
    bytes += generator.text(
      'STUDENT INFORMATION',
      styles: const PosStyles(bold: true),
    );
    
    bytes += generator.row([
      PosColumn(text: 'Name:', width: 4),
      PosColumn(text: receipt.student.studentName, width: 8),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Adm No:', width: 4),
      PosColumn(text: receipt.student.admissionNumber, width: 8),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Grade:', width: 4),
      PosColumn(text: receipt.student.grade, width: 8),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Parent:', width: 4),
      PosColumn(text: receipt.student.parentName, width: 8),
    ]);
    
    bytes += generator.hr();
    
    // Items
    bytes += generator.text(
      'PAYMENT DETAILS',
      styles: const PosStyles(bold: true),
    );
    
    // Items header
    if (_currentConfig!.paperSize == PaperSize.mm80) {
      bytes += generator.row([
        PosColumn(text: 'Description', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
    } else {
      bytes += generator.text('Item | Qty | Amount', styles: const PosStyles(bold: true));
    }
    
    bytes += generator.hr(ch: '-');
    
    // Items list
    for (final item in receipt.items) {
      if (_currentConfig!.paperSize == PaperSize.mm80) {
        bytes += generator.row([
          PosColumn(text: _truncateText(item.description, 20), width: 6),
          PosColumn(text: item.quantity.toString(), width: 2),
          PosColumn(
            text: '₦${item.totalAmount.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      } else {
        bytes += generator.text(_truncateText(item.description, 15));
        bytes += generator.row([
          PosColumn(text: '${item.quantity}x', width: 4),
          PosColumn(
            text: '₦${item.totalAmount.toStringAsFixed(2)}',
            width: 8,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }
    
    bytes += generator.hr();
    
    // Totals
    if (receipt.totals.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 8),
        PosColumn(
          text: '₦${receipt.totals.subtotal.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 8),
        PosColumn(
          text: '-₦${receipt.totals.discountAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    
    if (receipt.totals.taxAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Tax:', width: 8),
        PosColumn(
          text: '₦${receipt.totals.taxAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    
    bytes += generator.hr();
    
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '₦${receipt.totals.grandTotal.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    
    bytes += generator.hr();
    
    // Payment information
    bytes += generator.text(
      'PAYMENT INFORMATION',
      styles: const PosStyles(bold: true),
    );
    
    bytes += generator.row([
      PosColumn(text: 'Method:', width: 6),
      PosColumn(text: receipt.payment.paymentMethod, width: 6),
    ]);
    
    if (receipt.payment.transactionReference != null) {
      bytes += generator.row([
        PosColumn(text: 'Reference:', width: 6),
        PosColumn(text: receipt.payment.transactionReference!, width: 6),
      ]);
    }
    
    bytes += generator.row([
      PosColumn(text: 'Amount Received:', width: 6),
      PosColumn(text: '₦${receipt.payment.amountReceived.toStringAsFixed(2)}', width: 6),
    ]);
    
    if (receipt.payment.changeAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Change:', width: 6),
        PosColumn(text: '₦${receipt.payment.changeAmount.toStringAsFixed(2)}', width: 6),
      ]);
    }
    
    bytes += generator.hr();
    
    // Footer
    if (receipt.footerMessage != null) {
      bytes += generator.text(
        receipt.footerMessage!,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);
    }
    
    bytes += generator.text(
      'Thank you for your payment!',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );
    
    bytes += generator.feed(2);
    bytes += generator.cut();
    
    return bytes;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  void _updateStatus(PrinterStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Get current printer status
  PrinterStatus getCurrentStatus() {
    if (_currentPrinter == null) {
      return const PrinterStatus(isConnected: false);
    }
    
    return const PrinterStatus(
      isConnected: true,
      isOnline: true,
      hasPaper: true,
    );
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}