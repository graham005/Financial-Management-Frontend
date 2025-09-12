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
  String? _selectedYear;
  String? _selectedStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentRequirements();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentRequirementProvider);
    final students = ref.watch(studentProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Student Requirements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAssignRequirementDialog(),
            icon: const Icon(Icons.assignment_add),
            tooltip: 'Assign Requirement',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(students),
          Expanded(child: _buildStudentRequirementsView(state)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(studentsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Student',
                    hintText: 'Enter student name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // Implement debounced search
                    setState(() => _selectedStudentId = value.isEmpty ? null : value);
                    _loadStudentRequirements();
                  },
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
                  items: ['Term 1', 'Term 2', 'Term 3']
                      .map((term) => DropdownMenuItem(value: term, child: Text(term)))
                      .toList(),
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
                  value: _selectedYear,
                  items: ['2023', '2024', '2025']
                      .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedYear = value);
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
                  items: ['PENDING', 'PARTIAL', 'COMPLETED']
                      .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
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
                    _searchController.clear();
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
            ElevatedButton(
              onPressed: _showAssignRequirementDialog,
              child: const Text('Assign Requirement'),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${requirement.term} ${requirement.academicYear}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
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
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () => _recordTransaction(requirement.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Record',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
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
    final studentIdController = TextEditingController();
    final requirementListIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Requirement'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID *',
                    hintText: 'Enter student ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Student ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final requirementLists = ref.watch(requirementListProvider);
                    
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Requirement List *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.list_alt),
                      ),
                      items: requirementLists.lists
                          .where((list) => list.status == 'ACTIVE')
                          .map((list) => DropdownMenuItem(
                                value: list.id,
                                child: Text('${list.term} ${list.academicYear}'),
                              ))
                          .toList(),
                      onChanged: (value) => requirementListIdController.text = value ?? '',
                      validator: (value) => value == null ? 'Please select a requirement list' : null,
                    );
                  },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await ref.read(studentRequirementProvider.notifier).assignRequirement(
                  studentId: studentIdController.text.trim(),
                  requirementListId: requirementListIdController.text,
                );
                
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadStudentRequirements();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Requirement assigned successfully')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
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

  void _recordTransaction(String requirementId) {
    Navigator.pushNamed(
      context,
      '/record-transaction',
      arguments: requirementId,
    );
  }
}