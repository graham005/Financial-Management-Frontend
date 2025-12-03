import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../provider/item_ledger_provider.dart';
import '/../models/student_requirement.dart';
import '/../models/requirement_status.dart';
import '/../utils/app_colors.dart';

class StudentRequirementDetailsScreen extends ConsumerWidget {
  final String studentRequirementId;

  const StudentRequirementDetailsScreen({
    super.key,
    required this.studentRequirementId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentRequirementAsync = ref.watch(studentRequirementDetailsProvider(studentRequirementId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // was AppColors.lightBackground
      appBar: AppBar(
        title: const Text('Requirement Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _recordTransaction(context, studentRequirementId),
            icon: const Icon(Icons.add_circle),
            tooltip: 'Record Transaction',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/requirement-transaction-history',
                arguments: studentRequirementId,
              );
            },
            icon: const Icon(Icons.history),
            tooltip: 'Transaction History',
          ),
        ],
      ),
      body: studentRequirementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(studentRequirementDetailsProvider(studentRequirementId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (requirement) => Column(
          children: [
            _buildHeaderSection(requirement, theme),
            _buildSummarySection(requirement, theme),
            Expanded(child: _buildItemsStatusList(requirement.items, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(StudentRequirement requirement, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardColor, // was Colors.white
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${requirement.term} ${requirement.academicYear}',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Student ID: ${requirement.studentId}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(requirement.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  requirement.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(requirement.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(StudentRequirement requirement, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // was Colors.white
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1), // theme-aware shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Value',
                  'KES ${requirement.totalValue.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  AppColors.primary,
                  theme,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Outstanding',
                  'KES ${requirement.outstandingValue.toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.orange,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${requirement.completionPercentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: requirement.completionPercentage / 100,
                backgroundColor: theme.colorScheme.surfaceVariant, // was Colors.grey[300]
                valueColor: AlwaysStoppedAnimation<Color>(
                  requirement.completionPercentage >= 100
                      ? Colors.green
                      : requirement.completionPercentage >= 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsStatusList(List<RequirementStatus> items, ThemeData theme) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items found',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemStatusCard(items[index], theme);
      },
    );
  }

  Widget _buildItemStatusCard(RequirementStatus status, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    status.itemName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (status.isFullyFulfilled)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildItemInfo(
                    'Required',
                    '${status.requiredQuantity} ${status.unit}',
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildItemInfo(
                    'Received',
                    '${status.receivedQuantity} ${status.unit}',
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildItemInfo(
                    'Outstanding',
                    '${status.outstandingQuantity} ${status.unit}',
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: ${status.fulfillmentPercentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: status.fulfillmentPercentage / 100,
                        backgroundColor: theme.colorScheme.surfaceVariant, // was Colors.grey[300]
                        valueColor: AlwaysStoppedAnimation<Color>(
                          status.isFullyFulfilled
                              ? Colors.green
                              : status.fulfillmentPercentage >= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Outstanding Value',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'KES ${status.outstandingValue.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInfo(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _recordTransaction(BuildContext context, String studentRequirementId) async {
    final result = await Navigator.pushNamed(
      context,
      '/record-transaction',
      arguments: studentRequirementId,
    );

    if (result == true) {
      // Force reload so outstanding/received values update
      // ignore: use_build_context_synchronously
      final container = ProviderScope.containerOf(context);
      container.refresh(studentRequirementDetailsProvider(studentRequirementId));
      // Optional feedback
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction recorded. Data refreshed')),
      );
    }
  }
}