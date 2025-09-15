import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../provider/item_ledger_provider.dart';
import '/../provider/student_provider.dart';
import '/../models/student_requirement.dart';
import '/../utils/app_colors.dart';

class StudentRequirementsScreen extends ConsumerStatefulWidget {
  const StudentRequirementsScreen({super.key});

  @override
  ConsumerState<StudentRequirementsScreen> createState() => _StudentRequirementsScreenState();
}

class _StudentRequirementsScreenState extends ConsumerState<StudentRequirementsScreen> {
  String? _selectedStudentId;
  String? _selectedTerm;
  int? _selectedYear;
  String? _selectedStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load both student requirements and requirement lists
      _loadStudentRequirements();
      _loadRequirementLists();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStudentRequirements() {
    ref.read(studentRequirementProvider.notifier).loadStudentRequirements(
      studentId: _selectedStudentId,
      term: _selectedTerm,
      academicYear: _selectedYear,
      status: _selectedStatus,
    );
  }

  // Add method to load requirement lists
  void _loadRequirementLists() {
    ref.read(requirementListProvider.notifier).loadRequirementLists();
  }

  // Add debug dialog to show all requirement lists
  void _showRequirementListsDebug() {
    showDialog(
      context: context,
      builder: (context) => _RequirementListsDebugDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentRequirementProvider);
    final studentsAsync = ref.watch(studentProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Student Requirements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Add debug button
          IconButton(
            onPressed: () => _showRequirementListsDebug(),
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug: Show Requirement Lists',
          ),
          IconButton(
            onPressed: () => _showAssignRequirementDialog(),
            icon: const Icon(Icons.assignment_add),
            tooltip: 'Assign Requirement',
          ),
          IconButton(
            onPressed: () => _showBulkAssignDialog(),
            icon: const Icon(Icons.assignment_ind),
            tooltip: 'Bulk Assign',
          ),
          // Add refresh button
          IconButton(
            onPressed: () {
              _loadStudentRequirements();
              _loadRequirementLists();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(studentsAsync),
          Expanded(child: _buildStudentRequirementsView(state)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(AsyncValue<List<Student>> studentsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: studentsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Error: $error'),
                  data: (students) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: _selectedStudentId,
                    items: students
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedStudentId = value);
                      _loadStudentRequirements();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Term',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTerm,
                  items: const [
                    DropdownMenuItem(value: 'Term 1', child: Text('Term 1')),
                    DropdownMenuItem(value: 'Term 2', child: Text('Term 2')),
                    DropdownMenuItem(value: 'Term 3', child: Text('Term 3')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTerm = value);
                    _loadStudentRequirements();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedYear?.toString(),
                  items: const [
                    DropdownMenuItem(value: '2023', child: Text('2023')),
                    DropdownMenuItem(value: '2024', child: Text('2024')),
                    DropdownMenuItem(value: '2025', child: Text('2025')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedYear = value != null ? int.tryParse(value) : null);
                    _loadStudentRequirements();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                    DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
                    DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadStudentRequirements();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedStudentId = null;
                    _selectedTerm = null;
                    _selectedYear = null;
                    _selectedStatus = null;
                  });
                  _loadStudentRequirements();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRequirementsView(StudentRequirementState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudentRequirements,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.requirements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No student requirements found'),
            const Text('Assign requirements to students to get started'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _showAssignRequirementDialog,
                  child: const Text('Assign to Student'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _showBulkAssignDialog,
                  child: const Text('Bulk Assign'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.requirements.length,
      itemBuilder: (context, index) {
        final requirement = state.requirements[index];
        return _buildStudentRequirementCard(requirement);
      },
    );
  }

  Widget _buildStudentRequirementCard(StudentRequirement requirement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewRequirementDetails(requirement.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requirement.studentName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('${requirement.term} ${requirement.academicYear}'),
                      ],
                    ),
                  ),
                  _buildStatusChip(requirement.status),
                ],
              ),
              const SizedBox(height: 12),
              _buildProgressSection(requirement),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Total Value',
                      '₦${requirement.totalValue.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Outstanding',
                      '₦${requirement.outstandingValue.toStringAsFixed(2)}',
                      Icons.pending,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => _recordTransaction(requirement.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Record'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'partial':
        color = Colors.orange;
        break;
      case 'pending':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressSection(StudentRequirement requirement) {
    final completionPercentage = requirement.completionPercentage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Completion Progress'),
            Text('${completionPercentage.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: completionPercentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            completionPercentage >= 100
                ? Colors.green
                : completionPercentage >= 50
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAssignRequirementDialog() {
    showDialog(
      context: context,
      builder: (context) => _AssignRequirementDialog(
        onAssigned: () {
          _loadStudentRequirements();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Requirement assigned successfully')),
          );
        },
      ),
    );
  }

  void _showBulkAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => _BulkAssignDialog(
        onAssigned: () {
          _loadStudentRequirements();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Requirements assigned successfully')),
          );
        },
      ),
    );
  }

  void _viewRequirementDetails(String requirementId) {
    Navigator.pushNamed(
      context,
      '/student-requirement-details',
      arguments: requirementId,
    );
  }

  void _recordTransaction(String requirementId) async {
    final result = await Navigator.pushNamed(
      context,
      '/record-transaction',
      arguments: requirementId,
    );
    if (result == true && mounted) {
      // Refresh the list so cards reflect new outstanding/received
      await ref.read(studentRequirementProvider.notifier).loadStudentRequirements(
        studentId: _selectedStudentId,
        term: _selectedTerm,
        academicYear: _selectedYear,
        status: _selectedStatus,
      );
    }
  }
}

// Single Assignment Dialog
class _AssignRequirementDialog extends ConsumerStatefulWidget {
  final VoidCallback onAssigned;

  const _AssignRequirementDialog({required this.onAssigned});

  @override
  ConsumerState<_AssignRequirementDialog> createState() => _AssignRequirementDialogState();
}

class _AssignRequirementDialogState extends ConsumerState<_AssignRequirementDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentId;
  String? _selectedRequirementListId;
  List<String> _selectedItemIds = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentProvider);
    final requirementListsState = ref.watch(requirementListProvider);
    final selectedRequirementListAsync = _selectedRequirementListId != null
        ? ref.watch(requirementListDetailsProvider(_selectedRequirementListId!))
        : null;

    return AlertDialog(
      title: const Text('Assign Requirement to Student'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Selection
                studentsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Error loading students: $error'),
                  data: (students) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Student *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: _selectedStudentId,
                    items: students.map((student) => DropdownMenuItem(
                      value: student.id,
                      child: Text(student.displayName),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedStudentId = value),
                    validator: (value) => value == null ? 'Please select a student' : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Requirement List Selection - Fixed to handle loading and error states
                if (requirementListsState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (requirementListsState.error != null)
                  Column(
                    children: [
                      Text('Error loading requirement lists: ${requirementListsState.error}'),
                      ElevatedButton(
                        onPressed: () => ref.read(requirementListProvider.notifier).loadRequirementLists(),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Requirement List *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list_alt),
                    ),
                    value: _selectedRequirementListId,
                    items: requirementListsState.lists
                        .where((list) => list.status == 'Active')
                        .map((list) => DropdownMenuItem(
                              value: list.id,
                              child: Text('${list.term} ${list.academicYear}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRequirementListId = value;
                        _selectedItemIds.clear();
                      });
                    },
                    validator: (value) => value == null ? 'Please select a requirement list' : null,
                  ),
                
                const SizedBox(height: 16),
                
                // Items Selection
                if (selectedRequirementListAsync != null)
                  selectedRequirementListAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Text('Error loading items: $error'),
                    data: (requirementList) => _buildItemsSelection(requirementList),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _assignRequirement,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildItemsSelection(requirementList) {
    final items = requirementList.items ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedItemIds.length == items.length) {
                    _selectedItemIds.clear();
                  } else {
                    _selectedItemIds = items.map((item) => item.id).toList();
                  }
                });
              },
              child: Text(_selectedItemIds.length == items.length ? 'Deselect All' : 'Select All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = _selectedItemIds.contains(item.id);
              
              return CheckboxListTile(
                title: Text(item.itemName),
                subtitle: Text('${item.requiredQuantity} ${item.unit} - ₦${item.unitPrice.toStringAsFixed(2)} each'),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedItemIds.add(item.id);
                    } else {
                      _selectedItemIds.remove(item.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        if (_selectedItemIds.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one item',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _assignRequirement() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(studentRequirementProvider.notifier).assignRequirement(
        studentId: _selectedStudentId!,
        requirementListId: _selectedRequirementListId!,
        selectedItemIds: _selectedItemIds,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Bulk Assignment Dialog
class _BulkAssignDialog extends ConsumerStatefulWidget {
  final VoidCallback onAssigned;

  const _BulkAssignDialog({required this.onAssigned});

  @override
  ConsumerState<_BulkAssignDialog> createState() => _BulkAssignDialogState();
}

class _BulkAssignDialogState extends ConsumerState<_BulkAssignDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  List<String> _selectedStudentIds = [];
  String? _selectedRequirementListId;
  List<String> _selectedItemIds = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentProvider);
    final requirementListsState = ref.watch(requirementListProvider);
    final selectedRequirementListAsync = _selectedRequirementListId != null
        ? ref.watch(requirementListDetailsProvider(_selectedRequirementListId!))
        : null;

    return AlertDialog(
      title: const Text('Bulk Assign Requirements'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Requirement List Selection - Fixed to handle loading and error states
              if (requirementListsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (requirementListsState.error != null)
                Column(
                  children: [
                    Text('Error loading requirement lists: ${requirementListsState.error}'),
                    ElevatedButton(
                      onPressed: () => ref.read(requirementListProvider.notifier).loadRequirementLists(),
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Requirement List *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.list_alt),
                  ),
                  value: _selectedRequirementListId,
                  items: requirementListsState.lists
                      .where((list) => list.status == 'Active')
                      .map((list) => DropdownMenuItem(
                            value: list.id,
                            child: Text('${list.term} ${list.academicYear}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRequirementListId = value;
                      _selectedItemIds.clear();
                    });
                  },
                  validator: (value) => value == null ? 'Please select a requirement list' : null,
                ),
              
              const SizedBox(height: 16),
              
              // Items Selection
              if (selectedRequirementListAsync != null)
                selectedRequirementListAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Error loading items: $error'),
                  data: (requirementList) => _buildItemsSelection(requirementList),
                ),
              
              const SizedBox(height: 16),
              
              // Student Search and Selection
              Expanded(
                child: studentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                  data: (students) => _buildStudentSelection(students),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _bulkAssignRequirements,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  'Assign to ${_selectedStudentIds.length} students',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildItemsSelection(requirementList) {
    final items = requirementList.items ?? [];
    
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Select Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedItemIds.length == items.length) {
                      _selectedItemIds.clear();
                    } else {
                      _selectedItemIds = items.map((item) => item.id).toList();
                    }
                  });
                },
                child: Text(_selectedItemIds.length == items.length ? 'Deselect All' : 'Select All'),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = _selectedItemIds.contains(item.id);
                  
                  return CheckboxListTile(
                    dense: true,
                    title: Text(item.itemName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${item.requiredQuantity} ${item.unit} - ₦${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedItemIds.add(item.id);
                        } else {
                          _selectedItemIds.remove(item.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelection(List<Student> allStudents) {
    final filteredStudents = _searchQuery.isEmpty
        ? allStudents
        : allStudents.where((student) {
            final query = _searchQuery.toLowerCase();
            return student.fullName.toLowerCase().contains(query) ||
                   student.admissionNumber.toLowerCase().contains(query) ||
                   student.gradeName.toLowerCase().contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextFormField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search Students',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        
        const SizedBox(height: 8),
        
        // Select all button
        Row(
          children: [
            Text(
              'Students (${_selectedStudentIds.length}/${filteredStudents.length} selected):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedStudentIds.length == filteredStudents.length) {
                    _selectedStudentIds.clear();
                  } else {
                    _selectedStudentIds = filteredStudents.map((s) => s.id).toList();
                  }
                });
              },
              child: Text(
                _selectedStudentIds.length == filteredStudents.length ? 'Deselect All' : 'Select All',
              ),
            ),
          ],
        ),
        
        // Students list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final isSelected = _selectedStudentIds.contains(student.id);
                
                return CheckboxListTile(
                  title: Text(student.fullName),
                  subtitle: Text('${student.admissionNumber} - ${student.gradeName}'),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedStudentIds.add(student.id);
                      } else {
                        _selectedStudentIds.remove(student.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _bulkAssignRequirements() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(studentRequirementProvider.notifier).bulkAssignStudents(
        studentIds: _selectedStudentIds,
        requirementListId: _selectedRequirementListId!,
        selectedItemIds: _selectedItemIds,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Debug Dialog to show all requirement lists
class _RequirementListsDebugDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirementListsState = ref.watch(requirementListProvider);

    return AlertDialog(
      title: const Text('Debug: Requirement Lists Data'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // State Information
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider State:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Is Loading: ${requirementListsState.isLoading}'),
                      Text('Error: ${requirementListsState.error ?? "None"}'),
                      Text('Lists Count: ${requirementListsState.lists.length}'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Loading State
              if (requirementListsState.isLoading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Loading requirement lists...'),
                      ],
                    ),
                  ),
                ),
              
              // Error State
              if (requirementListsState.error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          requirementListsState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(requirementListProvider.notifier).loadRequirementLists(),
                          child: const Text('Retry Loading'),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Requirement Lists Data
              if (requirementListsState.lists.isEmpty && !requirementListsState.isLoading)
                Card(
                  color: Colors.orange.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No Requirement Lists Found',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('The provider loaded successfully but returned no requirement lists.'),
                        Text('This could mean:'),
                        Text('• No requirement lists exist in the database'),
                        Text('• All lists are archived/inactive'),
                        Text('• API filters are excluding all results'),
                      ],
                    ),
                  ),
                ),
              
              // Display actual requirement lists
              ...requirementListsState.lists.asMap().entries.map((entry) {
                final index = entry.key;
                final list = entry.value;
                
                return Card(
                  color: Colors.green.shade50,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Requirement List Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requirement List #${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text('ID: ${list.id}'),
                              Text('Term: ${list.term}'),
                              Text('Academic Year: ${list.academicYear}'),
                              Text('Status: ${list.status}'),
                              Text('Created At: ${list.createdAt}'),
                              Text('Created By: ${list.createdBy}'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Items
                        Text(
                          'Items (${list.items?.length ?? 0}):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        
                        if (list.items == null || list.items!.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'No items in this requirement list',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ...list.items!.asMap().entries.map((itemEntry) {
                            final itemIndex = itemEntry.key;
                            final item = itemEntry.value;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Item #${itemIndex + 1}: ${item.itemName}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('ID: ${item.id}'),
                                  Text('Required Quantity: ${item.requiredQuantity} ${item.unit}'),
                                  Text('Unit Price: ₦${item.unitPrice.toStringAsFixed(2)}'),
                                  if (item.description != null && item.description!.isNotEmpty)
                                    Text('Description: ${item.description}'),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              }),
              
              // Refresh Button
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(requirementListProvider.notifier).loadRequirementLists(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Copy debug info to clipboard
            final debugInfo = '''
Provider State Debug Info:
- Is Loading: ${requirementListsState.isLoading}
- Error: ${requirementListsState.error ?? "None"}
- Lists Count: ${requirementListsState.lists.length}

Requirement Lists:
${requirementListsState.lists.asMap().entries.map((entry) {
              final index = entry.key;
              final list = entry.value;
              
              return '''
- Requirement List #${index + 1}:
  ID: ${list.id}
  Term: ${list.term}
  Academic Year: ${list.academicYear}
  Status: ${list.status}
  Created At: ${list.createdAt}
  Created By: ${list.createdBy}
  Items Count: ${list.items?.length ?? 0}
  ''';
            }).join()}
            ''';

            // TODO: Implement clipboard copy functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Debug info copied to clipboard')),
            );
          },
          child: const Text('Copy Debug Info'),
        ),
      ],
    );
  }
}