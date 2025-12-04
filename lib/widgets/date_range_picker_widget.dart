import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class DateRangePickerWidget extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeSelected;

  const DateRangePickerWidget({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _getDateRangeText(),
                style: GoogleFonts.underdog(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (startDate != null || endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear dates',
                  onPressed: () => onDateRangeSelected(null, null),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  context,
                  label: 'Start Date',
                  date: startDate,
                  onTap: () => _selectStartDate(context),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  context,
                  label: 'End Date',
                  date: endDate,
                  onTap: () => _selectEndDate(context),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip('Today', () {
                final now = DateTime.now();
                onDateRangeSelected(now, now);
              }),
              _buildQuickFilterChip('This Week', () {
                final now = DateTime.now();
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                onDateRangeSelected(weekStart, now);
              }),
              _buildQuickFilterChip('This Month', () {
                final now = DateTime.now();
                final monthStart = DateTime(now.year, now.month, 1);
                onDateRangeSelected(monthStart, now);
              }),
              _buildQuickFilterChip('Last 30 Days', () {
                final now = DateTime.now();
                final thirtyDaysAgo = now.subtract(const Duration(days: 30));
                onDateRangeSelected(thirtyDaysAgo, now);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: date != null ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.underdog(
                fontSize: 10,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Select',
              style: GoogleFonts.underdog(
                fontSize: 13,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                color: date != null ? AppColors.primary : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: GoogleFonts.underdog(fontSize: 11),
        ),
        backgroundColor: AppColors.primary.withValues(alpha:0.1),
        side: BorderSide(color: AppColors.primary.withValues(alpha:0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  String _getDateRangeText() {
    if (startDate != null && endDate != null) {
      if (startDate == endDate) {
        return DateFormat('dd MMM yyyy').format(startDate!);
      }
      return '${DateFormat('dd MMM').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}';
    } else if (startDate != null) {
      return 'From ${DateFormat('dd MMM yyyy').format(startDate!)}';
    } else if (endDate != null) {
      return 'Until ${DateFormat('dd MMM yyyy').format(endDate!)}';
    }
    return 'Select date range';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // If end date is before new start date, clear it
      if (endDate != null && picked.isAfter(endDate!)) {
        onDateRangeSelected(picked, null);
      } else {
        onDateRangeSelected(picked, endDate);
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeSelected(startDate, picked);
    }
  }
}