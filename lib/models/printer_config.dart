// lib/models/printer_config.dart
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

enum PrinterConnectionType { usb, bluetooth, network, none }

class PrinterConfig {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final String address; // IP address for network, MAC for Bluetooth, device path for USB
  final int port; // For network printers
  final PaperSize paperSize;
  final bool isDefault;

  const PrinterConfig({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    this.port = 9100,
    this.paperSize = PaperSize.mm80,
    this.isDefault = false,
  });

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      connectionType: PrinterConnectionType.values.firstWhere(
        (e) => e.toString() == json['connectionType'],
        orElse: () => PrinterConnectionType.none,
      ),
      address: json['address'] ?? '',
      port: json['port'] ?? 9100,
      paperSize: json['paperSize'] == 'mm58' ? PaperSize.mm58 : PaperSize.mm80,
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'connectionType': connectionType.toString(),
      'address': address,
      'port': port,
      'paperSize': paperSize == PaperSize.mm58 ? 'mm58' : 'mm80',
      'isDefault': isDefault,
    };
  }

  PrinterConfig copyWith({
    String? id,
    String? name,
    PrinterConnectionType? connectionType,
    String? address,
    int? port,
    PaperSize? paperSize,
    bool? isDefault,
  }) {
    return PrinterConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      address: address ?? this.address,
      port: port ?? this.port,
      paperSize: paperSize ?? this.paperSize,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class PrinterStatus {
  final bool isConnected;
  final bool isOnline;
  final bool hasPaper;
  final String? error;

  const PrinterStatus({
    required this.isConnected,
    this.isOnline = false,
    this.hasPaper = true,
    this.error,
  });

  bool get canPrint => isConnected && isOnline && hasPaper && error == null;
}