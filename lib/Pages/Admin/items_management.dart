import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../provider/required_items_provider.dart';
import '../../models/required_item.dart';

class ItemsManagementScreen extends ConsumerStatefulWidget {
  const ItemsManagementScreen({super.key});

  @override
  ConsumerState<ItemsManagementScreen> createState() => _ItemsManagementScreenState();
}

class _ItemsManagementScreenState extends ConsumerState<ItemsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(requiredItemsProvider.notifier).fetchRequiredItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RequiredItem> _filterItems(List<RequiredItem> items) {
    if (_searchQuery.isEmpty) return items;
    
    return items.where((item) {
      return item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.unit.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requiredItemsAsync = ref.watch(requiredItemsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          "Items Management",
          style: GoogleFonts.underdog(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(requiredItemsProvider.notifier).fetchRequiredItems(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(requiredItemsProvider.notifier).fetchRequiredItems(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Section
                    _buildHeaderSection(isDark),
                    const SizedBox(height: 24),

                    // Search and Add Button Row
                    _buildSearchAndAddSection(context, isDark),
                    const SizedBox(height: 24),

                    // Items List
                    requiredItemsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => _buildErrorWidget(error, isDark),
                      data: (items) => _buildItemsList(context, _filterItems(items), isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Required Items Management",
                  style: GoogleFonts.underdog(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Manage items that students need to bring to school",
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.inventory_2,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddSection(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search items...",
                  hintStyle: GoogleFonts.underdog(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.underdog(
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Add Button
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                "Add Item",
                style: GoogleFonts.underdog(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            "Failed to load required items",
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.underdog(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(requiredItemsProvider.notifier).fetchRequiredItems(),
            icon: const Icon(Icons.refresh),
            label: Text("Retry", style: GoogleFonts.underdog()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<RequiredItem> items, bool isDark) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? "No Required Items" : "No items found",
              style: GoogleFonts.underdog(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? "Add items that students need to bring to school"
                  : "Try adjusting your search criteria",
              style: GoogleFonts.underdog(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  "Required Items (${items.length})",
                  style: GoogleFonts.underdog(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Filtered",
                      style: GoogleFonts.underdog(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  AppColors.primary.withValues(alpha:0.1),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      "Item Name",
                      style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Expected Quantity",
                      style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Unit",
                      style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Actions",
                      style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                rows: items.map((item) => _buildItemRow(context, item, isDark)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildItemRow(BuildContext context, RequiredItem item, bool isDark) {
    return DataRow(cells: [
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.itemName,
            style: GoogleFonts.underdog(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          NumberFormat('#,##0.##').format(item.expectedQuantity),
          style: GoogleFonts.underdog(),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.unit,
            style: GoogleFonts.underdog(
              fontSize: 12,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditItemDialog(context, item),
              tooltip: "Edit Item",
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, item),
              tooltip: "Delete Item",
            ),
          ],
        ),
      ),
    ]);
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ItemFormDialog(
        title: "Add Required Item",
        onSave: (item) => ref.read(requiredItemsProvider.notifier).addRequiredItem(
          itemName: item.itemName,
          expectedQuantity: item.expectedQuantity,
          unit: item.unit,
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, RequiredItem item) {
    showDialog(
      context: context,
      builder: (context) => ItemFormDialog(
        title: "Edit Required Item",
        item: item,
        onSave: (updatedItem) => ref.read(requiredItemsProvider.notifier).updateRequiredItem(
          id: updatedItem.id!,
          itemName: updatedItem.itemName,
          expectedQuantity: updatedItem.expectedQuantity,
          unit: updatedItem.unit,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RequiredItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Required Item",
          style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to delete '${item.itemName}'?",
          style: GoogleFonts.underdog(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel", style: GoogleFonts.underdog()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (item.id.isNotEmpty) {
                ref.read(requiredItemsProvider.notifier).deleteRequiredItem(item.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text("Delete", style: GoogleFonts.underdog(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ItemFormDialog extends StatefulWidget {
  final String title;
  final RequiredItem? item;
  final Function(RequiredItem) onSave;

  const ItemFormDialog({
    super.key,
    required this.title,
    this.item,
    required this.onSave,
  });

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemNameController;
  late final TextEditingController _expectedQuantityController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(text: widget.item?.itemName ?? '');
    _expectedQuantityController = TextEditingController(
      text: widget.item?.expectedQuantity.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _expectedQuantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: Text(
        widget.title,
        style: GoogleFonts.underdog(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  labelStyle: GoogleFonts.underdog(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.inventory, color: AppColors.primary),
                ),
                style: GoogleFonts.underdog(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expectedQuantityController,
                decoration: InputDecoration(
                  labelText: "Expected Quantity",
                  labelStyle: GoogleFonts.underdog(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.numbers, color: AppColors.accent),
                ),
                style: GoogleFonts.underdog(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter expected quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: "Unit",
                  labelStyle: GoogleFonts.underdog(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.straighten, color: AppColors.secondary),
                  hintText: "e.g., pieces, kg, liters",
                  hintStyle: GoogleFonts.underdog(fontSize: 12),
                ),
                style: GoogleFonts.underdog(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a unit';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancel", style: GoogleFonts.underdog()),
        ),
        ElevatedButton(
          onPressed: _saveItem,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: Text("Save", style: GoogleFonts.underdog(color: Colors.white)),
        ),
      ],
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final item = RequiredItem(
        id: widget.item?.id ?? '',
        itemName: _itemNameController.text.trim(),
        expectedQuantity: double.parse(_expectedQuantityController.text.trim()),
        unit: _unitController.text.trim(),
      );

      widget.onSave(item);
      Navigator.of(context).pop();
    }
  }
}