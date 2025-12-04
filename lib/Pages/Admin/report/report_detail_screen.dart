import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_colors.dart';
import '../../../provider/receipt_provider.dart';
import '../../../provider/grade_provider.dart';
import '../../../provider/student_provider.dart';
import '../../../models/report/report_filter.dart';
import '../../../widgets/date_range_picker_widget.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final ReportType reportType;

  const ReportDetailScreen({
    super.key,
    required this.reportType,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedTerm;
  int? _selectedYear;
  String? _selectedGradeId;
  String? _selectedStudentId;
  String? _selectedPaymentMethod;
  String? _selectedFeeType;
  bool _isDownloading = false; // Track download state

  @override
  void initState() {
    super.initState();
    // Set default filters
    _selectedYear = DateTime.now().year;
    _selectedTerm = 'Term 1';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  void _applyFilters() {
    final filter = ReportFilter(
      startDate: _startDate,
      endDate: _endDate,
      term: _selectedTerm,
      year: _selectedYear,
      gradeId: _selectedGradeId,
      studentId: _selectedStudentId,
      paymentMethod: _selectedPaymentMethod,
      feeType: _selectedFeeType,
      format: 'JSON', // Default format for preview
    );
    
    ref.read(reportFilterProvider.notifier).state = filter;
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedTerm = 'Term 1';
      _selectedYear = DateTime.now().year;
      _selectedGradeId = null;
      _selectedStudentId = null;
      _selectedPaymentMethod = null;
      _selectedFeeType = null;
    });
    _applyFilters();
  }

  Future<void> _downloadReport(String format) async {
    // Validate student selection for student statement reports
    if (widget.reportType == ReportType.studentStatement && _selectedStudentId == null) {
      _showSnackBar(
        'Please select a student before exporting',
        AppColors.error,
        icon: Icons.error_outline,
      );
      return;
    }

    // Set downloading state
    setState(() => _isDownloading = true);

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Downloading ${format.toUpperCase()}...',
                    style: GoogleFonts.underdog(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This may take a few moments',
                    style: GoogleFonts.underdog(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha:0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    try {
      // Create filter with the selected format
      final filter = ReportFilter(
        startDate: _startDate,
        endDate: _endDate,
        term: _selectedTerm,
        year: _selectedYear,
        gradeId: _selectedGradeId,
        studentId: _selectedStudentId,
        paymentMethod: _selectedPaymentMethod,
        feeType: _selectedFeeType,
        format: format, // PDF or Excel
      );

      // Call the download provider
      final success = await ref.read(reportDownloadProvider.notifier).downloadReport(
        reportType: widget.reportType.endpoint,
        filter: filter,
      );

      if (mounted) {
        setState(() => _isDownloading = false);

        // Dismiss loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (success) {
          _showSnackBar(
            'Report downloaded successfully',
            AppColors.success,
            icon: Icons.check_circle,
            subtitle: 'File saved to Downloads folder and opened',
            duration: const Duration(seconds: 4),
          );
        } else {
          _showSnackBar(
            'Download Failed',
            AppColors.error,
            icon: Icons.error_outline,
            subtitle: 'Please check your internet connection and try again',
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _downloadReport(format),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        _showSnackBar(
          'Unexpected Error',
          AppColors.error,
          icon: Icons.error_outline,
          subtitle: e.toString().length > 60
              ? '${e.toString().substring(0, 60)}...'
              : e.toString(),
          duration: const Duration(seconds: 6),
        );
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.reportType.displayName,
          style: GoogleFonts.underdog(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter Button
          IconButton(
            onPressed: _showFilterDialog,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, size: 24),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filters',
          ),
          // Export Menu
          PopupMenuButton<String>(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.file_download_outlined, size: 24),
            tooltip: 'Export Report',
            enabled: !_isDownloading,
            onSelected: _downloadReport,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 45),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'PDF',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export as PDF',
                          style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Portable document format',
                          style: GoogleFonts.underdog(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'Excel',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export as Excel',
                          style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Spreadsheet format',
                          style: GoogleFonts.underdog(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Active Filters Chip Bar
          if (_hasActiveFilters()) _buildActiveFiltersBar(isDark),
          
          // Report Content
          Expanded(
            child: _buildReportPreview(isDark),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _startDate != null ||
           _endDate != null ||
           (_selectedTerm != null && _selectedTerm != 'Term 1') ||
           (_selectedYear != null && _selectedYear != DateTime.now().year) ||
           _selectedGradeId != null ||
           _selectedStudentId != null ||
           _selectedPaymentMethod != null ||
           _selectedFeeType != null;
  }

  Widget _buildActiveFiltersBar(bool isDark) {
    final List<Widget> chips = [];

    if (_startDate != null || _endDate != null) {
      String dateText = '';
      if (_startDate != null && _endDate != null) {
        dateText = '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}';
      } else if (_startDate != null) {
        dateText = 'From ${DateFormat('dd MMM yyyy').format(_startDate!)}';
      } else if (_endDate != null) {
        dateText = 'Until ${DateFormat('dd MMM yyyy').format(_endDate!)}';
      }
      chips.add(_buildFilterChip(dateText, () {
        setState(() {
          _startDate = null;
          _endDate = null;
        });
        _applyFilters();
      }));
    }

    if (_selectedTerm != null && _selectedTerm != 'Term 1') {
      chips.add(_buildFilterChip(_selectedTerm!, () {
        setState(() => _selectedTerm = 'Term 1');
        _applyFilters();
      }));
    }

    if (_selectedYear != null && _selectedYear != DateTime.now().year) {
      chips.add(_buildFilterChip(_selectedYear.toString(), () {
        setState(() => _selectedYear = DateTime.now().year);
        _applyFilters();
      }));
    }

    if (_selectedGradeId != null) {
      final grades = ref.read(gradeProvider).valueOrNull;
      final grade = grades?.firstWhere((g) => g.id == _selectedGradeId);
      if (grade != null) {
        chips.add(_buildFilterChip(grade.name, () {
          setState(() => _selectedGradeId = null);
          _applyFilters();
        }));
      }
    }

    if (_selectedStudentId != null) {
      final students = ref.read(studentProvider).valueOrNull;
      final student = students?.firstWhere((s) => s.id == _selectedStudentId);
      if (student != null) {
        chips.add(_buildFilterChip(student.name, () {
          setState(() => _selectedStudentId = null);
          _applyFilters();
        }));
      }
    }

    if (_selectedPaymentMethod != null) {
      chips.add(_buildFilterChip(_selectedPaymentMethod!, () {
        setState(() => _selectedPaymentMethod = null);
        _applyFilters();
      }));
    }

    if (_selectedFeeType != null) {
      chips.add(_buildFilterChip(_selectedFeeType!, () {
        setState(() => _selectedFeeType = null);
        _applyFilters();
      }));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            'Active Filters:',
            style: GoogleFonts.underdog(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: Text('Clear All', style: GoogleFonts.underdog(fontSize: 12, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: GoogleFonts.underdog(fontSize: 12, fontWeight: FontWeight.w600)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppColors.primary.withValues(alpha:0.12),
        side: BorderSide(color: AppColors.primary.withValues(alpha:0.3), width: 1.5),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        deleteIconColor: AppColors.primary,
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradesAsync = ref.watch(gradeProvider);
    final studentsAsync = ref.watch(studentProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.tune, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Filter Report',
                  style: GoogleFonts.underdog(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),

          // Filters Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  if (_shouldShowDateRange()) ...[
                    Text(
                      'Date Range',
                      style: GoogleFonts.underdog(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DateRangePickerWidget(
                      startDate: _startDate,
                      endDate: _endDate,
                      onDateRangeSelected: (start, end) {
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Term & Year Row
                  if (_shouldShowTerm()) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Term',
                                style: GoogleFonts.underdog(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedTerm,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                ),
                                items: ['All', 'Term 1', 'Term 2', 'Term 3']
                                    .map((term) => DropdownMenuItem(
                                          value: term == 'All' ? null : term,
                                          child: Text(term, style: GoogleFonts.underdog()),
                                        ))
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedTerm = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Year',
                                style: GoogleFonts.underdog(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedYear,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Years'),
                                  ),
                                  ...List.generate(5, (i) => DateTime.now().year - i)
                                      .map((year) => DropdownMenuItem(
                                            value: year,
                                            child: Text(year.toString()),
                                          )),
                                ],
                                onChanged: (value) => setState(() => _selectedYear = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Grade Filter
                  if (_shouldShowGrade()) ...[
                    Text(
                      'Grade',
                      style: GoogleFonts.underdog(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    gradesAsync.when(
                      data: (grades) => DropdownButtonFormField<String>(
                        value: _selectedGradeId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Grades'),
                          ),
                          ...grades.map((grade) => DropdownMenuItem(
                                value: grade.id,
                                child: Text(grade.name, style: GoogleFonts.underdog()),
                              )),
                        ],
                        onChanged: (value) => setState(() => _selectedGradeId = value),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => Text(
                        'Failed to load grades',
                        style: GoogleFonts.underdog(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Student Filter
                  if (_shouldShowStudent()) ...[
                    Text(
                      'Student',
                      style: GoogleFonts.underdog(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    studentsAsync.when(
                      data: (students) => DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select Student'),
                          ),
                          ...students.map((student) => DropdownMenuItem(
                                value: student.id,
                                child: Text(
                                  '${student.name} (${student.admissionNumber})',
                                  style: GoogleFonts.underdog(),
                                ),
                              )),
                        ],
                        onChanged: (value) => setState(() => _selectedStudentId = value),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => Text(
                        'Failed to load students',
                        style: GoogleFonts.underdog(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Payment Method & Fee Type Row
                  if (_shouldShowPaymentMethod() || _shouldShowFeeType())
                    Row(
                      children: [
                        if (_shouldShowPaymentMethod())
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Method',
                                  style: GoogleFonts.underdog(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedPaymentMethod,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                  ),
                                  items: ['All', 'Cash', 'M-Pesa', 'Bank Transfer', 'Cheque']
                                      .map((method) => DropdownMenuItem(
                                            value: method == 'All' ? null : method,
                                            child: Text(method, style: GoogleFonts.underdog()),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                                ),
                              ],
                            ),
                          ),
                        if (_shouldShowPaymentMethod() && _shouldShowFeeType())
                          const SizedBox(width: 16),
                        if (_shouldShowFeeType())
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fee Type',
                                  style: GoogleFonts.underdog(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedFeeType,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                  ),
                                  items: ['All', 'Tuition', 'Transport', 'Lunch', 'Remedial', 'Other']
                                      .map((type) => DropdownMenuItem(
                                            value: type == 'All' ? null : type,
                                            child: Text(type, style: GoogleFonts.underdog()),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedFeeType = value),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              border: Border(
                top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _resetFilters();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear_all),
                    label: Text('Reset', style: GoogleFonts.underdog()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: Text('Apply Filters', style: GoogleFonts.underdog()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportPreview(bool isDark) {
    // Route to appropriate report preview based on type
    switch (widget.reportType) {
      case ReportType.dailyCollections:
        return _buildDailyCollectionsPreview(isDark);
      case ReportType.revenueSummary:
        return _buildRevenueSummaryPreview(isDark);
      case ReportType.outstandingFees:
        return _buildOutstandingFeesPreview(isDark);
      case ReportType.collectionRate:
        return _buildCollectionRatePreview(isDark);
      case ReportType.paymentHistory:
        return _buildPaymentHistoryPreview(isDark);
      case ReportType.itemTransactions:
        return _buildItemTransactionsPreview(isDark);
      case ReportType.studentStatement:
        return _buildStudentStatementPreview(isDark);
      case ReportType.summary:
        return _buildSummaryPreview(isDark);
    }
  }

  // Helper methods to determine which filters to show
  bool _shouldShowDateRange() {
    return widget.reportType == ReportType.dailyCollections ||
           widget.reportType == ReportType.paymentHistory;
  }

  bool _shouldShowTerm() {
    return widget.reportType != ReportType.paymentHistory &&
           widget.reportType != ReportType.studentStatement;
  }

  bool _shouldShowGrade() {
    return widget.reportType != ReportType.studentStatement;
  }

  bool _shouldShowStudent() {
    return widget.reportType == ReportType.studentStatement;
  }

  bool _shouldShowPaymentMethod() {
    return widget.reportType == ReportType.dailyCollections ||
           widget.reportType == ReportType.paymentHistory;
  }

  bool _shouldShowFeeType() {
    return widget.reportType == ReportType.dailyCollections ||
           widget.reportType == ReportType.paymentHistory;
  }

  // Daily Collections Preview
  Widget _buildDailyCollectionsPreview(bool isDark) {
    final reportAsync = ref.watch(dailyCollectionsProvider);

    return reportAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading report data...',
              style: GoogleFonts.underdog(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load report',
                style: GoogleFonts.underdog(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.underdog(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(dailyCollectionsProvider),
                icon: const Icon(Icons.refresh),
                label: Text('Retry', style: GoogleFonts.underdog()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards in Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildSummaryMetric(
                  'Total Collected',
                  NumberFormat.currency(symbol: 'KES ').format(report.totalCollected),
                  Icons.attach_money,
                  Colors.green,
                  isDark,
                ),
                _buildSummaryMetric(
                  'Transactions',
                  report.transactionCount.toString(),
                  Icons.receipt,
                  Colors.blue,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Payment Method Breakdown
            _buildSectionHeader('By Payment Method', Icons.payment),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Payment Method', 'Amount', 'Count'],
              rows: report.byPaymentMethod.map((pm) => [
                pm.paymentMethod,
                NumberFormat.currency(symbol: 'KES ').format(pm.amount),
                pm.count.toString(),
              ]).toList(),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Fee Type Breakdown
            _buildSectionHeader('By Fee Type', Icons.category),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Fee Type', 'Amount', 'Count'],
              rows: report.byFeeType.map((ft) => [
                ft.feeType,
                NumberFormat.currency(symbol: 'KES ').format(ft.amount),
                ft.count.toString(),
              ]).toList(),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Transactions List
            _buildSectionHeader('Recent Transactions', Icons.history),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Date', 'Student', 'Amount', 'Method', 'Term'],
              rows: report.transactions.take(10).map((txn) => [
                DateFormat('dd/MM HH:mm').format(txn.paymentDate),
                '${txn.studentName}\n${txn.admissionNumber}',
                NumberFormat.currency(symbol: 'KES ').format(txn.amount),
                txn.paymentMethod,
                '${txn.term} ${txn.year}',
              ]).toList(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.underdog(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // Revenue Summary Preview
  Widget _buildRevenueSummaryPreview(bool isDark) {
    final reportAsync = ref.watch(revenueSummaryProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Total Revenue',
                        style: GoogleFonts.underdog(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha:0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    NumberFormat.currency(symbol: 'KES ').format(report.totalRevenue),
                    style: GoogleFonts.underdog(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${report.term} ${report.year}',
                    style: GoogleFonts.underdog(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha:0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Revenue by Fee Type
            _buildSectionHeader('Revenue by Fee Type', Icons.category),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Fee Type', 'Amount', 'Percentage'],
              rows: report.byFeeType.map((ft) => [
                ft.feeType,
                NumberFormat.currency(symbol: 'KES ').format(ft.amount),
                '${ft.percentage.toStringAsFixed(1)}%',
              ]).toList(),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Revenue by Grade
            _buildSectionHeader('Revenue by Grade', Icons.school),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Grade', 'Amount', 'Students', 'Avg/Student'],
              rows: report.byGrade.map((gr) => [
                gr.gradeName,
                NumberFormat.currency(symbol: 'KES ').format(gr.amount),
                gr.studentCount.toString(),
                NumberFormat.currency(symbol: 'KES ').format(gr.averagePerStudent),
              ]).toList(),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Monthly Breakdown
            _buildSectionHeader('Monthly Breakdown', Icons.calendar_month),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Month', 'Amount'],
              rows: report.monthlyBreakdown.map((mb) => [
                mb.monthName,
                NumberFormat.currency(symbol: 'KES ').format(mb.amount),
              ]).toList(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // Outstanding Fees Preview
  Widget _buildOutstandingFeesPreview(bool isDark) {
    final reportAsync = ref.watch(outstandingFeesProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildSummaryMetric(
                  'Total Outstanding',
                  NumberFormat.currency(symbol: 'KES ').format(report.totalOutstanding),
                  Icons.warning_amber,
                  Colors.orange,
                  isDark,
                ),
                _buildSummaryMetric(
                  'Students with Arrears',
                  report.studentsWithArrears.toString(),
                  Icons.people,
                  Colors.red,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Students with Arrears
            _buildSectionHeader('Students with Outstanding Fees', Icons.person_off),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Admission No', 'Name', 'Grade', 'Outstanding', 'Oldest Unpaid'],
              rows: report.students.map((s) => [
                s.admissionNumber,
                s.studentName,
                s.grade,
                NumberFormat.currency(symbol: 'KES ').format(s.outstandingAmount),
                '${s.oldestUnpaidTerm} ${s.oldestUnpaidYear}',
              ]).toList(),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // By Grade
            _buildSectionHeader('Outstanding by Grade', Icons.school),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Grade', 'Students', 'Total Outstanding', 'Avg Arrears'],
              rows: report.byGrade.map((gr) => [
                gr.gradeName,
                gr.studentsWithArrears.toString(),
                NumberFormat.currency(symbol: 'KES ').format(gr.totalOutstanding),
                NumberFormat.currency(symbol: 'KES ').format(gr.averageArrears),
              ]).toList(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // Collection Rate Preview
  Widget _buildCollectionRatePreview(bool isDark) {
    final reportAsync = ref.watch(collectionRateProvider);
    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Collection Rate Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.percent, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Collection Rate',
                        style: GoogleFonts.underdog(
                          color: Colors.white.withValues(alpha:0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${report.collectionRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.underdog(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expected vs Collected Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildSummaryMetric(
                  'Expected Fees',
                  NumberFormat.currency(symbol: 'KES ').format(report.expectedFees),
                  Icons.trending_up,
                  Colors.blue,
                  isDark,
                ),
                _buildSummaryMetric(
                  'Collected Fees',
                  NumberFormat.currency(symbol: 'KES ').format(report.collectedFees),
                  Icons.check_circle,
                  Colors.green,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Collection Rate by Grade
            _buildSectionHeader('Collection Rate by Grade', Icons.school),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Grade', 'Students', 'Expected', 'Collected', 'Rate'],
              rows: report.byGrade.map((gr) => [
                gr.gradeName,
                gr.studentCount.toString(),
                NumberFormat.currency(symbol: 'KES ').format(gr.expectedFees),
                NumberFormat.currency(symbol: 'KES ').format(gr.collectedFees),
                '${gr.collectionRate.toStringAsFixed(1)}%',
              ]).toList(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // Payment History Preview
  Widget _buildPaymentHistoryPreview(bool isDark) {
    final reportAsync = ref.watch(paymentHistoryProvider);
    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildSummaryMetric(
                  'Total Amount',
                  NumberFormat.currency(symbol: 'KES ').format(report.totalAmount),
                  Icons.attach_money,
                  Colors.green,
                  isDark,
                ),
                _buildSummaryMetric(
                  'Total Payments',
                  report.totalPayments.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Range Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha:0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Period: ${DateFormat('dd MMM yyyy').format(report.startDate)} - ${DateFormat('dd MMM yyyy').format(report.endDate)}',
                    style: GoogleFonts.underdog(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Transactions
            _buildSectionHeader('Payment Transactions', Icons.list_alt),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Date', 'Receipt No', 'Student', 'Amount', 'Method', 'Fee Type', 'Term'],
              rows: report.payments.map((p) => [
                DateFormat('dd/MM HH:mm').format(p.paymentDate),
                p.receiptNumber,
                '${p.studentName}\n${p.admissionNumber}',
                NumberFormat.currency(symbol: 'KES ').format(p.amount),
                p.paymentMethod,
                p.feeType,
                '${p.term} ${p.year}',
              ]).toList(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // Item Transactions Preview
  Widget _buildItemTransactionsPreview(bool isDark) {
    final reportAsync = ref.watch(itemTransactionsProvider);
    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Fulfillment Summary
            _buildSectionHeader('Item Fulfillment Summary', Icons.inventory),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Item', 'Required', 'Received', 'Money', 'Fulfillment', 'Unit'],
              rows: report.items.map((item) => [
                item.itemName,
                item.requiredQuantity.toString(),
                item.receivedQuantity.toString(),
                NumberFormat.currency(symbol: 'KES ').format(item.moneyContributed),
                '${item.fulfillmentRate.toStringAsFixed(1)}%',
                item.unit,
              ]).toList(),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Student Item Status
            _buildSectionHeader('Student Item Status', Icons.person),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Student', 'Grade', 'Status', 'Items Value', 'Money Contributed'],
              rows: report.students.map((s) => [
                '${s.studentName}\n${s.admissionNumber}',
                s.grade,
                s.status,
                NumberFormat.currency(symbol: 'KES ').format(s.itemsValue),
                NumberFormat.currency(symbol: 'KES ').format(s.moneyContributed),
              ]).toList(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // Student Statement Preview
  Widget _buildStudentStatementPreview(bool isDark) {
    if (_selectedStudentId == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha:0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search,
                size: 80,
                color: AppColors.primary.withValues(alpha:0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Select a Student',
                style: GoogleFonts.underdog(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please use the filter button above to select a student\nand view their financial statement',
                style: GoogleFonts.underdog(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list),
                label: Text('Open Filters', style: GoogleFonts.underdog()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final reportAsync = ref.watch(studentStatementProvider(_selectedStudentId!));
    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Text(
                          report.studentName[0].toUpperCase(),
                          style: GoogleFonts.underdog(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.studentName,
                              style: GoogleFonts.underdog(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${report.admissionNumber} • ${report.grade}',
                              style: GoogleFonts.underdog(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha:0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Financial Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatementMetric(
                          'Total Fees',
                          NumberFormat.currency(symbol: 'KES ').format(report.totalFeesCharged),
                          Icons.account_balance_wallet,
                        ),
                      ),
                      Expanded(
                        child: _buildStatementMetric(
                          'Total Paid',
                          NumberFormat.currency(symbol: 'KES ').format(report.totalPaid),
                          Icons.check_circle,
                        ),
                      ),
                      Expanded(
                        child: _buildStatementMetric(
                          'Balance',
                          NumberFormat.currency(symbol: 'KES ').format(report.currentBalance),
                          report.currentBalance > 0 ? Icons.warning_amber : Icons.verified,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Fee Summary by Term
            _buildSectionHeader('Fee Summary by Term', Icons.calendar_today),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Term', 'Year', 'Fees Charged', 'Amount Paid', 'Outstanding'],
              rows: report.byTerm.map((t) => [
                t.term,
                t.year.toString(),
                NumberFormat.currency(symbol: 'KES ').format(t.feesCharged),
                NumberFormat.currency(symbol: 'KES ').format(t.amountPaid),
                NumberFormat.currency(symbol: 'KES ').format(t.outstanding),
              ]).toList(),
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Payment History
            _buildSectionHeader('Payment History', Icons.history),
            const SizedBox(height: 16),
            _buildDataTable(
              columns: ['Date', 'Receipt No', 'Amount', 'Method', 'Description'],
              rows: report.paymentHistory.map((p) => [
                DateFormat('dd MMM yyyy HH:mm').format(p.paymentDate),
                p.receiptNumber,
                NumberFormat.currency(symbol: 'KES ').format(p.amount),
                p.paymentMethod,
                p.description,
              ]).toList(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha:0.8), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.underdog(
                fontSize: 12,
                color: Colors.white.withValues(alpha:0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.underdog(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Summary Preview
  Widget _buildSummaryPreview(bool isDark) {
    final reportAsync = ref.watch(reportSummaryProvider);
    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (summary) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary Dashboard',
              style: GoogleFonts.underdog(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryMetric(
                  'Today\'s Collections',
                  NumberFormat.currency(symbol: 'KES ').format(summary.dailyCollections.totalCollected),
                  Icons.today,
                  Colors.green,
                  isDark,
                ),
                _buildSummaryMetric(
                  'Total Revenue',
                  NumberFormat.currency(symbol: 'KES ').format(summary.revenue.totalRevenue),
                  Icons.attach_money,
                  Colors.blue,
                  isDark,
                ),
                _buildSummaryMetric(
                  'Outstanding Fees',
                  NumberFormat.currency(symbol: 'KES ').format(summary.outstanding.totalOutstanding),
                  Icons.warning_amber,
                  Colors.orange,
                  isDark,
                ),
                _buildSummaryMetric(
                  'Collection Rate',
                  '${summary.collectionRate.collectionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.purple,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Reusable summary metric widget
  Widget _buildSummaryMetric(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha:0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.underdog(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.underdog(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable data table widget
  Widget _buildDataTable({
    required List<String> columns,
    required List<List<String>> rows,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha:0.1)),
          columns: columns
              .map((col) => DataColumn(
                    label: Text(
                      col,
                      style: GoogleFonts.underdog(fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: row
                        .map((cell) => DataCell(
                              Text(cell, style: GoogleFonts.underdog(fontSize: 12)),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // Helper method for consistent snackbars
  void _showSnackBar(
    String title,
    Color backgroundColor, {
    IconData? icon,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.underdog(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.underdog(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha:0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
        action: action,
      ),
    );
  }
}