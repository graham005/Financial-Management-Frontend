import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../provider/item_ledger_provider.dart';
import '/../models/requirement_list.dart';
import '/../utils/app_colors.dart';

class RequirementListsScreen extends ConsumerStatefulWidget {
  const RequirementListsScreen({super.key});

  @override
  ConsumerState<RequirementListsScreen> createState() => _RequirementListsScreenState();
}

class _RequirementListsScreenState extends ConsumerState<RequirementListsScreen> {
  String? _selectedTerm;
  int? _selectedYear;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequirementLists();
    });
  }

  void _loadRequirementLists() {
    ref.read(requirementListProvider.notifier).loadRequirementLists(
      term: _selectedTerm,
      academicYear: _selectedYear,
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requirementListProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Requirement Lists'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: _buildRequirementListsView(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRequirementListDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
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
                _loadRequirementLists();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                border: OutlineInputBorder(),
              ),
              value: _selectedYear?.toString(),
              items: ['2023', '2024', '2025']
                  .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedYear = value != null ? int.tryParse(value) : null);
                _loadRequirementLists();
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
              items: ['Active', 'Archived']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _loadRequirementLists();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementListsView(RequirementListState state) {
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
              onPressed: _loadRequirementLists,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.lists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No requirement lists found'),
            Text('Create a new requirement list to get started'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.lists.length,
      itemBuilder: (context, index) {
        final requirementList = state.lists[index];
        return _buildRequirementListCard(requirementList);
      },
    );
  }

  Widget _buildRequirementListCard(RequirementList requirementList) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          '${requirementList.term} ${requirementList.academicYear}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items: ${requirementList.itemCount}'),
            Text('Status: ${requirementList.status}'),
            Text('Created: ${requirementList.createdAt.toString().split(' ')[0]}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _viewRequirementList(requirementList);
                break;
              case 'archive':
                _archiveRequirementList(requirementList.id);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            if (requirementList.status == 'Active')
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
          ],
        ),
        onTap: () => _viewRequirementList(requirementList),
      ),
    );
  }

  void _showCreateRequirementListDialog() {
    final termController = TextEditingController();
    final yearController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Requirement List'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Term',
                  border: OutlineInputBorder(),
                ),
                items: ['Term 1', 'Term 2', 'Term 3']
                    .map((term) => DropdownMenuItem(value: term, child: Text(term)))
                    .toList(),
                onChanged: (value) => termController.text = value ?? '',
                validator: (value) => value == null ? 'Please select a term' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: yearController,
                decoration: const InputDecoration(
                  labelText: 'Academic Year',
                  hintText: 'e.g., 2024',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Academic year is required';
                  final year = int.tryParse(value);
                  if (year == null || year < 2020 || year > 2050) {
                    return 'Enter a valid year';
                  }
                  return null;
                },
              ),
            ],
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
                final success = await ref.read(requirementListProvider.notifier).createRequirementList(
                  term: termController.text,
                  academicYear: int.tryParse(yearController.text) ?? 0,
                  createdBy: 'Current User', // Replace with actual user
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Requirement list created successfully')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewRequirementList(RequirementList requirementList) {
    ref.read(selectedRequirementListProvider.notifier).state = requirementList;
    Navigator.pushNamed(context, '/requirement-list-details', arguments: requirementList.id);
  }

  void _archiveRequirementList(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Requirement List'),
        content: const Text('Are you sure you want to archive this requirement list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Archive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(requirementListProvider.notifier).archiveRequirementList(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requirement list archived successfully')),
        );
      }
    }
  }
}