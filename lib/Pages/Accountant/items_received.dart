import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/required_item.dart';
import '../../provider/student_provider.dart';
import '../../utils/app_colors.dart';
import '../../provider/items_received_provider.dart';
import '../../models/item_received.dart';

class ItemsReceivedScreen extends ConsumerStatefulWidget {
  const ItemsReceivedScreen({super.key});

  @override
  ConsumerState<ItemsReceivedScreen> createState() => _ItemsReceivedScreenState();
}

class _ItemsReceivedScreenState extends ConsumerState<ItemsReceivedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Today, This Week, This Month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsReceivedProvider.notifier).fetchItemsReceived();
      ref.read(requiredItemsForSelectionProvider.notifier).fetchRequiredItems();
      ref.read(studentsForSelectionProvider.notifier).fetchStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ItemReceived> _filterItems(List<ItemReceived> items) {
    List<ItemReceived> filtered = items;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return (item.itemName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.studentName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.admissionNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        filtered = filtered.where((item) {
          return item.dateReceived.year == now.year &&
                 item.dateReceived.month == now.month &&
                 item.dateReceived.day == now.day;
        }).toList();
        break;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered.where((item) {
          return item.dateReceived.isAfter(weekStart.subtract(const Duration(days: 1)));
        }).toList();
        break;
      case 'This Month':
        filtered = filtered.where((item) {
          return item.dateReceived.year == now.year &&
                 item.dateReceived.month == now.month;
        }).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemsReceivedAsync = ref.watch(itemsReceivedProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          "Items Received",
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
            onPressed: () => ref.read(itemsReceivedProvider.notifier).fetchItemsReceived(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(itemsReceivedProvider.notifier).fetchItemsReceived(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Section
                    _buildHeaderSection(isDark),
                    const SizedBox(height: 24),

                    // Search, Filter and Add Button Row
                    _buildSearchFilterAndAddSection(context, isDark),
                    const SizedBox(height: 24),

                    // Items Received List
                    itemsReceivedAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => _buildErrorWidget(error, isDark),
                      data: (items) => _buildItemsReceivedList(context, _filterItems(items), isDark),
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
                  "Items Received Management",
                  style: GoogleFonts.underdog(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Track and manage items received from students",
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.inventory,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterAndAddSection(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          Row(
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
                      hintText: "Search by item, student name, or admission number...",
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
                  onPressed: () => _showAddItemReceivedDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Record Item",
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
          const SizedBox(height: 16),
          // Filter Chips
          Row(
            children: [
              Text(
                "Filter by date:",
                style: GoogleFonts.underdog(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: ['All', 'Today', 'This Week', 'This Month'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return FilterChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.underdog(
                          color: isSelected ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
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
            "Failed to load items received",
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
            onPressed: () => ref.read(itemsReceivedProvider.notifier).fetchItemsReceived(),
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

  Widget _buildItemsReceivedList(BuildContext context, List<ItemReceived> items, bool isDark) {
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
              Icons.inventory_outlined,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _selectedFilter == 'All' ? "No Items Received" : "No items found",
              style: GoogleFonts.underdog(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty && _selectedFilter == 'All'
                  ? "Record items received from students"
                  : "Try adjusting your search criteria or filters",
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
      constraints: const BoxConstraints(maxWidth: 1200),
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
                  "Items Received (${items.length})",
                  style: GoogleFonts.underdog(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
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
                  AppColors.primary.withValues(alpha: 0.1),
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
                      "Student",
                      style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Quantity",
                      style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Date Received",
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

  DataRow _buildItemRow(BuildContext context, ItemReceived item, bool isDark) {
    return DataRow(cells: [
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.itemName ?? 'Unknown Item',
                style: GoogleFonts.underdog(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (item.unit != null)
                Text(
                  'Unit: ${item.unit}',
                  style: GoogleFonts.underdog(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
      DataCell(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.studentName ?? 'Unknown Student',
              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
            ),
            if (item.admissionNumber != null)
              Text(
                item.admissionNumber!,
                style: GoogleFonts.underdog(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            NumberFormat('#,##0.##').format(item.quantity),
            style: GoogleFonts.underdog(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          DateFormat('MMM dd, yyyy\nh:mm a').format(item.dateReceived),
          style: GoogleFonts.underdog(),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditItemReceivedDialog(context, item),
              tooltip: "Edit Record",
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, item),
              tooltip: "Delete Record",
            ),
          ],
        ),
      ),
    ]);
  }

  void _showAddItemReceivedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ItemReceivedFormDialog(
        title: "Record Item Received",
        onSave: (item) => ref.read(itemsReceivedProvider.notifier).addItemReceived(
          requiredItemId: item.requiredItemId,
          studentId: item.studentId,
          quantity: item.quantity,
          dateReceived: item.dateReceived,
        ),
      ),
    );
  }

  void _showEditItemReceivedDialog(BuildContext context, ItemReceived item) {
    showDialog(
      context: context,
      builder: (context) => ItemReceivedFormDialog(
        title: "Edit Item Received",
        item: item,
        onSave: (updatedItem) => ref.read(itemsReceivedProvider.notifier).updateItemReceived(
          id: updatedItem.id!,
          requiredItemId: updatedItem.requiredItemId,
          studentId: updatedItem.studentId,
          quantity: updatedItem.quantity,
          dateReceived: updatedItem.dateReceived,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ItemReceived item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Record",
          style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to delete this record for '${item.itemName}' received from '${item.studentName}'?",
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
              if (item.id != null && item.id!.isNotEmpty) {
                ref.read(itemsReceivedProvider.notifier).deleteItemReceived(item.id!);
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

class ItemReceivedFormDialog extends ConsumerStatefulWidget {
  final String title;
  final ItemReceived? item;
  final Function(ItemReceived) onSave;

  const ItemReceivedFormDialog({
    super.key,
    required this.title,
    this.item,
    required this.onSave,
  });

  @override
  ConsumerState<ItemReceivedFormDialog> createState() => _ItemReceivedFormDialogState();
}

class _ItemReceivedFormDialogState extends ConsumerState<ItemReceivedFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _itemSearchController;
  late final TextEditingController _studentSearchController;
  late DateTime _selectedDate;
  
  String? _selectedRequiredItemId;
  String? _selectedStudentId;
  String _itemSearchQuery = '';
  String _studentSearchQuery = '';
  bool _showItemDropdown = false;
  bool _showStudentDropdown = false;
  
  // For selected display
  String? _selectedItemDisplay;
  String? _selectedStudentDisplay;
  RequiredItem? _selectedRequiredItem; // Add this to store the full item object

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '',
    );
    _itemSearchController = TextEditingController();
    _studentSearchController = TextEditingController();
    _selectedDate = widget.item?.dateReceived ?? DateTime.now();
    _selectedRequiredItemId = widget.item?.requiredItemId;
    _selectedStudentId = widget.item?.studentId;
    
    // Set initial display values if editing
    if (widget.item != null) {
      _selectedItemDisplay = widget.item!.itemName != null 
          ? '${widget.item!.itemName} (${widget.item!.unit ?? 'Unknown unit'})'
          : null;
      _selectedStudentDisplay = widget.item!.studentName != null 
          ? '${widget.item!.studentName} (${widget.item!.admissionNumber ?? 'No admission number'})'
          : null;
      
      // For editing, we need to find the required item to get expected quantity
      if (widget.item!.expectedQuantity != null) {
        _selectedRequiredItem = RequiredItem(
          id: widget.item!.requiredItemId,
          itemName: widget.item!.itemName ?? '',
          expectedQuantity: widget.item!.expectedQuantity!,
          unit: widget.item!.unit ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _itemSearchController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requiredItemsAsync = ref.watch(requiredItemsForSelectionProvider);
    final studentsAsync = ref.watch(studentsForSelectionProvider);

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
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Required Item Search Field
                _buildItemSearchField(requiredItemsAsync, isDark),
                const SizedBox(height: 16),
                
                // Student Search Field
                _buildStudentSearchField(studentsAsync, isDark),
                const SizedBox(height: 16),
                
                // Quantity Field with validation
                _buildQuantityField(isDark),
                const SizedBox(height: 16),
                
                // Date Picker
                _buildDatePicker(isDark),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancel", style: GoogleFonts.underdog()),
        ),
        ElevatedButton(
          onPressed: _saveItemReceived,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: Text("Save", style: GoogleFonts.underdog(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildQuantityField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            labelText: "Quantity Received",
            labelStyle: GoogleFonts.underdog(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.numbers, color: AppColors.secondary),
            suffixText: _selectedRequiredItem?.unit,
            helperText: _selectedRequiredItem != null 
                ? "Expected: ${NumberFormat('#,##0.##').format(_selectedRequiredItem!.expectedQuantity)} ${_selectedRequiredItem!.unit}"
                : null,
            helperStyle: GoogleFonts.underdog(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
          style: GoogleFonts.underdog(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter quantity received';
            }
            
            final quantity = double.tryParse(value);
            if (quantity == null) {
              return 'Please enter a valid number';
            }
            
            if (quantity <= 0) {
              return 'Quantity must be greater than 0';
            }
            
            // Validate against expected quantity
            if (_selectedRequiredItem != null && quantity > _selectedRequiredItem!.expectedQuantity) {
              return 'Quantity cannot exceed expected amount (${NumberFormat('#,##0.##').format(_selectedRequiredItem!.expectedQuantity)} ${_selectedRequiredItem!.unit})';
            }
            
            return null;
          },
          onChanged: (value) {
            // Real-time validation feedback
            setState(() {
              // Trigger rebuild to update helper text color
            });
          },
        ),
        
        // Visual indicator for quantity status
        if (_selectedRequiredItem != null && _quantityController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildQuantityIndicator(),
          ),
      ],
    );
  }

  Widget _buildQuantityIndicator() {
    final enteredQuantity = double.tryParse(_quantityController.text);
    if (enteredQuantity == null || _selectedRequiredItem == null) {
      return const SizedBox.shrink();
    }

    final expectedQuantity = _selectedRequiredItem!.expectedQuantity;
    final percentage = (enteredQuantity / expectedQuantity) * 100;
    
    Color indicatorColor;
    String statusText;
    IconData statusIcon;
    
    if (enteredQuantity > expectedQuantity) {
      indicatorColor = AppColors.error;
      statusText = "Exceeds expected quantity by ${NumberFormat('#,##0.##').format(enteredQuantity - expectedQuantity)} ${_selectedRequiredItem!.unit}";
      statusIcon = Icons.error;
    } else if (enteredQuantity == expectedQuantity) {
      indicatorColor = AppColors.success;
      statusText = "Exact expected quantity";
      statusIcon = Icons.check_circle;
    } else {
      indicatorColor = AppColors.primary;
      statusText = "${NumberFormat('#,##0.#').format(percentage)}% of expected quantity";
      statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: indicatorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: GoogleFonts.underdog(
                color: indicatorColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSearchField(AsyncValue<List<RequiredItem>> requiredItemsAsync, bool isDark) {
    return requiredItemsAsync.when(
      data: (requiredItems) {
        final filteredItems = requiredItems.where((item) {
          return item.itemName.toLowerCase().contains(_itemSearchQuery.toLowerCase()) ||
                 item.unit.toLowerCase().contains(_itemSearchQuery.toLowerCase());
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _itemSearchController,
              decoration: InputDecoration(
                labelText: _selectedItemDisplay != null ? "Selected Item" : "Search for Required Item",
                labelStyle: GoogleFonts.underdog(),
                hintText: _selectedItemDisplay ?? "Type item name or unit...",
                hintStyle: GoogleFonts.underdog(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.inventory_2, color: AppColors.primary),
                suffixIcon: _selectedItemDisplay != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedRequiredItemId = null;
                            _selectedItemDisplay = null;
                            _selectedRequiredItem = null; // Clear the selected item
                            _itemSearchController.clear();
                            _itemSearchQuery = '';
                            _showItemDropdown = false;
                          });
                        },
                      )
                    : IconButton(
                        icon: Icon(_showItemDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                        onPressed: () {
                          setState(() {
                            _showItemDropdown = !_showItemDropdown;
                          });
                        },
                      ),
              ),
              style: GoogleFonts.underdog(),
              readOnly: _selectedItemDisplay != null,
              onChanged: (value) {
                setState(() {
                  _itemSearchQuery = value;
                  _showItemDropdown = value.isNotEmpty;
                });
              },
              onTap: () {
                if (_selectedItemDisplay == null) {
                  setState(() {
                    _showItemDropdown = true;
                  });
                }
              },
              validator: (value) {
                if (_selectedRequiredItemId == null) {
                  return 'Please select a required item';
                }
                return null;
              },
            ),
            
            if (_showItemDropdown && _selectedItemDisplay == null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: filteredItems.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No items found matching "$_itemSearchQuery"',
                          style: GoogleFonts.underdog(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.inventory_2,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            title: Text(
                              item.itemName,
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Expected: ${NumberFormat('#,##0.##').format(item.expectedQuantity)} ${item.unit}',
                              style: GoogleFonts.underdog(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedRequiredItemId = item.id;
                                _selectedRequiredItem = item; // Store the full item object
                                _selectedItemDisplay = '${item.itemName} (${item.unit})';
                                _itemSearchController.text = _selectedItemDisplay!;
                                _showItemDropdown = false;
                                _itemSearchQuery = '';
                              });
                            },
                          );
                        },
                      ),
              ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error loading required items',
          style: GoogleFonts.underdog(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildStudentSearchField(AsyncValue<List<Student>> studentsAsync, bool isDark) {
    return studentsAsync.when(
      data: (students) {
        // Filter students based on search query
        final filteredStudents = students.where((student) {
          return student.name.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
                 student.admissionNumber.toLowerCase().contains(_studentSearchQuery.toLowerCase());
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field for students
            TextFormField(
              controller: _studentSearchController,
              decoration: InputDecoration(
                labelText: _selectedStudentDisplay != null ? "Selected Student" : "Search for Student",
                labelStyle: GoogleFonts.underdog(),
                hintText: _selectedStudentDisplay ?? "Type student name or admission number...",
                hintStyle: GoogleFonts.underdog(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.person, color: AppColors.accent),
                suffixIcon: _selectedStudentDisplay != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedStudentId = null;
                            _selectedStudentDisplay = null;
                            _studentSearchController.clear();
                            _studentSearchQuery = '';
                            _showStudentDropdown = false;
                          });
                        },
                      )
                    : IconButton(
                        icon: Icon(_showStudentDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                        onPressed: () {
                          setState(() {
                            _showStudentDropdown = !_showStudentDropdown;
                          });
                        },
                      ),
              ),
              style: GoogleFonts.underdog(),
              readOnly: _selectedStudentDisplay != null,
              onChanged: (value) {
                setState(() {
                  _studentSearchQuery = value;
                  _showStudentDropdown = value.isNotEmpty;
                });
              },
              onTap: () {
                if (_selectedStudentDisplay == null) {
                  setState(() {
                    _showStudentDropdown = true;
                  });
                }
              },
              validator: (value) {
                if (_selectedStudentId == null) {
                  return 'Please select a student';
                }
                return null;
              },
            ),
            
            // Dropdown list for students
            if (_showStudentDropdown && _selectedStudentDisplay == null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: filteredStudents.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No students found matching "$_studentSearchQuery"',
                          style: GoogleFonts.underdog(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.accent.withOpacity(0.2),
                              radius: 16,
                              child: Text(
                                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                                style: GoogleFonts.underdog(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            title: Text(
                              student.name,
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Admission: ${student.admissionNumber}',
                              style: GoogleFonts.underdog(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedStudentId = student.id;
                                _selectedStudentDisplay = '${student.name} (${student.admissionNumber})';
                                _studentSearchController.text = _selectedStudentDisplay!;
                                _showStudentDropdown = false;
                                _studentSearchQuery = '';
                              });
                            },
                          );
                        },
                      ),
              ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error loading students',
          style: GoogleFonts.underdog(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (pickedTime != null) {
            setState(() {
              _selectedDate = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Date & Time Received",
                    style: GoogleFonts.underdog(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy h:mm a').format(_selectedDate),
                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _saveItemReceived() {
    if (_formKey.currentState!.validate()) {
      final item = ItemReceived(
        id: widget.item?.id,
        requiredItemId: _selectedRequiredItemId!,
        studentId: _selectedStudentId!,
        quantity: double.parse(_quantityController.text.trim()),
        dateReceived: _selectedDate,
      );

      widget.onSave(item);
      Navigator.of(context).pop();
    }
  }
}