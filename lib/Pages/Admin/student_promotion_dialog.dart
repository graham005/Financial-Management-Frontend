import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../provider/promotion_provider.dart';
import '../../models/student_promotion.dart';

class StudentPromotionDialog extends ConsumerStatefulWidget {
  final VoidCallback onPromotionComplete;

  const StudentPromotionDialog({
    super.key,
    required this.onPromotionComplete,
  });

  @override
  ConsumerState<StudentPromotionDialog> createState() => _StudentPromotionDialogState();
}

class _StudentPromotionDialogState extends ConsumerState<StudentPromotionDialog> {
  int _currentStep = 0;
  final Set<String> _selectedStudentIds = {};
  bool _isPromoting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promotionPreviewAsync = ref.watch(promotionPreviewProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Promotion',
                          style: GoogleFonts.underdog(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentStep == 0 ? 'Select students to promote' : 'Review and confirm',
                          style: GoogleFonts.underdog(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isPromoting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: promotionPreviewAsync.when(
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                      const SizedBox(height: 20),
                      Text(
                        'Loading promotion preview...',
                        style: GoogleFonts.underdog(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 56, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to Load Preview',
                          style: GoogleFonts.underdog(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error.toString(),
                          style: GoogleFonts.underdog(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(promotionPreviewProvider),
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
                data: (preview) => _currentStep == 0
                    ? _buildSelectionStep(preview, isDark)
                    : _buildConfirmationStep(preview, isDark),
              ),
            ),

            // Action Buttons
            if (!_isPromoting)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.grey[50],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _currentStep = 0),
                            icon: const Icon(Icons.arrow_back, size: 20),
                            label: Text('Back', style: GoogleFonts.underdog(fontSize: 15)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _selectedStudentIds.isEmpty
                              ? null
                              : _currentStep == 0
                                  ? () => setState(() => _currentStep = 1)
                                  : _promoteStudents,
                          icon: Icon(
                            _currentStep == 0 ? Icons.arrow_forward : Icons.check_circle,
                            size: 20,
                          ),
                          label: Text(
                            _currentStep == 0
                                ? 'Next (${_selectedStudentIds.length} selected)'
                                : 'Confirm Promotion',
                            style: GoogleFonts.underdog(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepCircle(0, 'Select'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 0 ? AppColors.primary : Colors.grey[300],
            ),
          ),
          _buildStepCircle(1, 'Confirm'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.underdog(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.underdog(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.primary : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionStep(PromotionPreview preview, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Year ${preview.academicYear} • ${preview.term}',
                        style: GoogleFonts.underdog(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${preview.totalStudents} students eligible for promotion',
                        style: GoogleFonts.underdog(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Promotion Groups
          if (preview.promotionGroups.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No students eligible for promotion',
                      style: GoogleFonts.underdog(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...preview.promotionGroups.map((group) => _buildPromotionGroupCard(group, isDark)),
        ],
      ),
    );
  }

  Widget _buildPromotionGroupCard(PromotionGroup group, bool isDark) {
    final allStudentsSelected = group.students.every((s) => _selectedStudentIds.contains(s.studentId));
    group.students.any((s) => _selectedStudentIds.contains(s.studentId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: group.isGraduation
              ? Colors.amber.withOpacity(0.5)
              : isDark
                  ? Colors.white12
                  : Colors.black12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: group.isGraduation
                  ? Colors.amber.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: group.isGraduation
                        ? Colors.amber.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    group.isGraduation ? Icons.celebration : Icons.arrow_upward,
                    color: group.isGraduation ? Colors.amber[700] : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.currentGradeName,
                        style: GoogleFonts.underdog(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            group.isGraduation
                                ? 'Graduation'
                                : group.nextGradeName ?? 'Unknown',
                            style: GoogleFonts.underdog(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${group.students.length} students',
                      style: GoogleFonts.underdog(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Checkbox(
                      value: allStudentsSelected,
                      tristate: true,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedStudentIds.addAll(group.students.map((s) => s.studentId));
                          } else {
                            for (var student in group.students) {
                              _selectedStudentIds.remove(student.studentId);
                            }
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Students List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.students.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.lightOnSurface : AppColors.darkOnSurface,
            ),
            itemBuilder: (context, index) {
              final student = group.students[index];
              final isSelected = _selectedStudentIds.contains(student.studentId);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudentIds.add(student.studentId);
                    } else {
                      _selectedStudentIds.remove(student.studentId);
                    }
                  });
                },
                title: Text(
                  student.name,
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Admission No: ${student.admissionNumber}',
                  style: GoogleFonts.underdog(fontSize: 12),
                ),
                secondary: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                    style: GoogleFonts.underdog(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(PromotionPreview preview, bool isDark) {
    final selectedStudents = <PromotionStudent>[];
    final promotionsByGrade = <String, List<PromotionStudent>>{};

    for (var group in preview.promotionGroups) {
      for (var student in group.students) {
        if (_selectedStudentIds.contains(student.studentId)) {
          selectedStudents.add(student);
          final key = group.isGraduation
              ? 'Graduation from ${group.currentGradeName}'
              : '${group.currentGradeName} → ${group.nextGradeName}';
          promotionsByGrade.putIfAbsent(key, () => []).add(student);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.1),
                  AppColors.success.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: AppColors.success, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to Promote',
                        style: GoogleFonts.underdog(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedStudentIds.length} students will be promoted',
                        style: GoogleFonts.underdog(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Promotion Details
          Text(
            'Promotion Summary',
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...promotionsByGrade.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.underdog(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.value.length} student${entry.value.length > 1 ? 's' : ''}',
                            style: GoogleFonts.underdog(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((student) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                          style: GoogleFonts.underdog(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: GoogleFonts.underdog(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        student.admissionNumber,
                        style: GoogleFonts.underdog(fontSize: 11),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Warning Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This action cannot be undone. Students will be moved to their new grades immediately.',
                    style: GoogleFonts.underdog(
                      fontSize: 13,
                      color: Colors.orange[900],
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

  Future<void> _promoteStudents() async {
    setState(() => _isPromoting = true);

    try {
      final success = await ref.read(promotionNotifierProvider.notifier).promoteStudents(
            _selectedStudentIds.toList(),
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          widget.onPromotionComplete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_selectedStudentIds.length} student${_selectedStudentIds.length > 1 ? 's' : ''} promoted successfully!',
                      style: GoogleFonts.underdog(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to promote students. Please try again.',
                style: GoogleFonts.underdog(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.underdog(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPromoting = false);
      }
    }
  }
}