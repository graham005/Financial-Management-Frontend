// lib/Pages/Admin/printer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../provider/thermal_printer_provider.dart';
import '../../models/printer_config.dart';
import '../../utils/app_colors.dart';
import 'dart:math' as math;

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(printerConfigProvider.notifier).loadSavedPrinters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(printerConfigProvider);
    final statusAsync = ref.watch(printerStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Printer Settings',
          style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddPrinterDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Printer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(statusAsync, isDark),
            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActions(configState, isDark),
            const SizedBox(height: 16),

            // Printer List
            _buildPrinterList(configState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(AsyncValue<PrinterStatus> statusAsync, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Printer Status',
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          statusAsync.when(
            data: (status) => _buildStatusRow(status),
            loading: () => const Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Checking status...'),
              ],
            ),
            error: (error, _) => Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Status error: $error')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(PrinterStatus status) {
    final color = status.isConnected
        ? (status.canPrint ? Colors.green : Colors.orange)
        : Colors.red;

    final statusText = status.isConnected
        ? (status.canPrint ? 'Ready' : 'Connected (Issue)')
        : 'Disconnected';

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: GoogleFonts.underdog(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        if (status.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.error!,
              style: GoogleFonts.underdog(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(PrinterConfigState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : () => _discoverPrinters(),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    'Discover Printers',
                    style: GoogleFonts.underdog(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.selectedPrinter != null ? () => _testPrint() : null,
                  icon: const Icon(Icons.print),
                  label: Text(
                    'Test Print',
                    style: GoogleFonts.underdog(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterList(PrinterConfigState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Configured Printers (${state.configs.length})',
              style: GoogleFonts.underdog(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (state.configs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.print_disabled,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No printers configured',
                      style: GoogleFonts.underdog(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a printer or discover network printers',
                      style: GoogleFonts.underdog(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.configs.map((config) => _buildPrinterTile(config, state.selectedPrinter)),
        ],
      ),
    );
  }

  Widget _buildPrinterTile(PrinterConfig config, PrinterConfig? selectedPrinter) {
    final isSelected = selectedPrinter?.id == config.id;
    final isConnected = isSelected;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha:0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getConnectionTypeColor(config.connectionType),
          child: Icon(
            _getConnectionTypeIcon(config.connectionType),
            color: Colors.white,
          ),
        ),
        title: Text(
          config.name,
          style: GoogleFonts.underdog(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${config.connectionType.toString().split('.').last.toUpperCase()} - ${config.address}',
              style: GoogleFonts.underdog(fontSize: 12),
            ),
            Text(
              'Paper: ${config.paperSize == PaperSize.mm58 ? "58mm" : "80mm"}',
              style: GoogleFonts.underdog(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (config.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEFAULT',
                  style: GoogleFonts.underdog(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (isConnected)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              onPressed: () => _showPrinterOptionsMenu(config),
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        onTap: () => _connectToPrinter(config),
      ),
    );
  }

  Color _getConnectionTypeColor(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return Colors.blue;
      case PrinterConnectionType.usb:
        return Colors.green;
      case PrinterConnectionType.bluetooth:
        return Colors.purple;
      case PrinterConnectionType.none:
        return Colors.grey;
    }
  }

  IconData _getConnectionTypeIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return Icons.wifi;
      case PrinterConnectionType.usb:
        return Icons.usb;
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.none:
        return Icons.help;
    }
  }

  void _discoverPrinters() async {
    await ref.read(printerConfigProvider.notifier).discoverNetworkPrinters();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network printer discovery completed')),
      );
    }
  }

  void _connectToPrinter(PrinterConfig config) async {
    final success = await ref.read(printerConfigProvider.notifier).connectToPrinter(config);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connected to ${config.name}' : 'Failed to connect to ${config.name}'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _testPrint() async {
    try {
      // If this is a FutureProvider<bool>
      final success = await ref.read(testPrintProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print successful!' : 'Test print failed'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test print error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPrinterDialog(
        onSave: (config) async {
          await ref.read(printerConfigProvider.notifier).savePrinter(config);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Printer "${config.name}" saved'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPrinterOptionsMenu(PrinterConfig config) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _showEditPrinterDialog(config);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text(config.isDefault ? 'Remove as Default' : 'Set as Default'),
            onTap: () {
              Navigator.pop(context);
              _toggleDefault(config);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deletePrinter(config);
            },
          ),
        ],
      ),
    );
  }

  void _showEditPrinterDialog(PrinterConfig config) {
    showDialog(
      context: context,
      builder: (context) => _AddPrinterDialog(
        config: config,
        onSave: (updatedConfig) async {
          await ref.read(printerConfigProvider.notifier).savePrinter(updatedConfig);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Printer "${updatedConfig.name}" updated'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _toggleDefault(PrinterConfig config) async {
    final updatedConfig = config.copyWith(isDefault: !config.isDefault);
    await ref.read(printerConfigProvider.notifier).savePrinter(updatedConfig);
  }

  void _deletePrinter(PrinterConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Printer', style: GoogleFonts.underdog()),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printer deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AddPrinterDialog extends StatefulWidget {
  final PrinterConfig? config;
  final Function(PrinterConfig) onSave;

  const _AddPrinterDialog({
    this.config,
    required this.onSave,
  });

  @override
  State<_AddPrinterDialog> createState() => _AddPrinterDialogState();
}

class _AddPrinterDialogState extends State<_AddPrinterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '9100');

  PrinterConnectionType _selectedType = PrinterConnectionType.network;
  PaperSize _selectedPaperSize = PaperSize.mm80;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.config != null) {
      _nameController.text = widget.config!.name;
      _addressController.text = widget.config!.address;
      _portController.text = widget.config!.port.toString();
      _selectedType = widget.config!.connectionType;
      _selectedPaperSize = widget.config!.paperSize;
      _isDefault = widget.config!.isDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.config != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Printer' : 'Add Printer',
        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<PrinterConnectionType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Connection Type *',
                  border: OutlineInputBorder(),
                ),
                items: PrinterConnectionType.values
                    .where((type) => type != PrinterConnectionType.none)
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: _selectedType == PrinterConnectionType.network
                      ? 'IP Address *'
                      : 'Address *',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),
              
              if (_selectedType == PrinterConnectionType.network)
                TextFormField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Port is required';
                    if (int.tryParse(value!) == null) return 'Enter a valid port number';
                    return null;
                  },
                ),
              if (_selectedType == PrinterConnectionType.network) const SizedBox(height: 16),
              
              DropdownButtonFormField<PaperSize>(
                value: _selectedPaperSize,
                decoration: const InputDecoration(
                  labelText: 'Paper Size *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PaperSize.mm58, child: Text('58mm')),
                  DropdownMenuItem(value: PaperSize.mm80, child: Text('80mm')),
                ],
                onChanged: (value) => setState(() => _selectedPaperSize = value!),
              ),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Set as default printer'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value ?? false),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePrinter,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            isEdit ? 'Update' : 'Add',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _savePrinter() {
    if (!_formKey.currentState!.validate()) return;

    final config = PrinterConfig(
      id: widget.config?.id ?? 'printer_${math.Random().nextInt(10000)}',
      name: _nameController.text.trim(),
      connectionType: _selectedType,
      address: _addressController.text.trim(),
      port: int.tryParse(_portController.text) ?? 9100,
      paperSize: _selectedPaperSize,
      isDefault: _isDefault,
    );

    widget.onSave(config);
  }
}