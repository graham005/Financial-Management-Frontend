import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../provider/payment_provider.dart';
import '../../provider/student_provider.dart';
import '../../models/student_fee.dart';
import '../../models/payment.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final TextEditingController _studentSearchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  String _searchQuery = '';
  final Map<String, double> _feeAllocations = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).fetchStudents();
    });
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(studentProvider);
    final studentFeesAsync = ref.watch(paymentProvider);
    final paymentMethods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          "Student Payments",
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
            onPressed: () {
              ref.read(studentProvider.notifier).fetchStudents();
              ref.read(paymentProvider.notifier).clearStudentFees();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(isDark),
                const SizedBox(height: 24),

                // Student Search Section
                _buildStudentSearchSection(studentsAsync, isDark),
                const SizedBox(height: 24),

                // Student Fees Section
                studentFeesAsync.when(
                  data: (studentFee) => studentFee != null 
                      ? _buildStudentFeesSection(studentFee, paymentMethods, isDark)
                      : const SizedBox.shrink(),
                  loading: () => _buildLoadingWidget(),
                  error: (error, stack) => _buildErrorWidget(error, isDark),
                ),
              ],
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
            color: AppColors.primary.withOpacity(0.3),
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
                  "Student Payment Processing",
                  style: GoogleFonts.underdog(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Process payments for student fees with automatic allocation",
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.payment,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSearchSection(List<Student> students, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            "Select Student",
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _studentSearchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search student by name...",
              hintStyle: GoogleFonts.underdog(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            ),
            style: GoogleFonts.underdog(
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          students.isEmpty
              ? const Center(child: Text("No students available"))
              : _buildStudentsList(students, isDark),
        ],
      ),
    );
  }

  Widget _buildStudentsList(List<Student> students, bool isDark) {
    final filteredStudents = students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          _searchQuery.isEmpty ? "No students available" : "No students found",
          style: GoogleFonts.underdog(
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          final student = filteredStudents[index];
          
          return Card(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : 'S',
                  style: GoogleFonts.underdog(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(
                student.name,
                style: GoogleFonts.underdog(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
              ),
              subtitle: Text(
                "ID: ${student.id}",
                style: GoogleFonts.underdog(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  ref.read(paymentProvider.notifier).fetchStudentAvailableFees(student.id);
                  _studentSearchController.text = student.name;
                  setState(() {
                    _searchQuery = '';
                    _feeAllocations.clear();
                    _amountController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  "Select",
                  style: GoogleFonts.underdog(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentFeesSection(StudentFee studentFee, List<String> paymentMethods, bool isDark) {
    return Column(
      children: [
        // Student Info Card
        _buildStudentInfoCard(studentFee, isDark),
        const SizedBox(height: 16),

        // Available Fees
        _buildAvailableFeesCard(studentFee, isDark),
        const SizedBox(height: 16),

        // Payment Form
        _buildPaymentForm(studentFee, paymentMethods, isDark),
      ],
    );
  }

  Widget _buildStudentInfoCard(StudentFee studentFee, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              studentFee.studentName.substring(0, 1).toUpperCase(),
              style: GoogleFonts.underdog(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentFee.studentName,
                  style: GoogleFonts.underdog(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  ),
                ),
                Text(
                  "Student ID: ${studentFee.studentId}",
                  style: GoogleFonts.underdog(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "Total Outstanding",
                  style: GoogleFonts.underdog(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: "Ksh").format(studentFee.totalOutstanding),
                  style: GoogleFonts.underdog(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableFeesCard(StudentFee studentFee, bool isDark) {
    final oldestOverdue = studentFee.oldestOverdueFee;
    
    return Container(
      width: double.infinity,
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
                  "Available Fees (${studentFee.availableFees.length})",
                  style: GoogleFonts.underdog(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  ),
                ),
                const Spacer(),
                if (oldestOverdue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Oldest Overdue: ${oldestOverdue.term} ${oldestOverdue.year}",
                      style: GoogleFonts.underdog(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFFFE0B2),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    "Fee Type",
                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Term/Year",
                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Total Amount",
                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Outstanding",
                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Status",
                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Allocation",
                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              rows: studentFee.availableFees.map((fee) => _buildFeeRow(fee, oldestOverdue, isDark)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildFeeRow(AvailableFee fee, AvailableFee? oldestOverdue, bool isDark) {
    final isPayable = oldestOverdue == null || fee == oldestOverdue || !fee.isOverdue;
    
    return DataRow(
      color: MaterialStateProperty.all(
        fee.isOverdue ? AppColors.error.withOpacity(0.05) : null,
      ),
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fee.feeType,
              style: GoogleFonts.underdog(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            "${fee.term} ${fee.year}",
            style: GoogleFonts.underdog(),
          ),
        ),
        DataCell(
          Text(
            NumberFormat.currency(symbol: "Ksh").format(fee.totalAmount),
            style: GoogleFonts.underdog(),
          ),
        ),
        DataCell(
          Text(
            NumberFormat.currency(symbol: "Ksh").format(fee.outstandingAmount),
            style: GoogleFonts.underdog(
              color: fee.isOverdue ? AppColors.error : null,
              fontWeight: fee.isOverdue ? FontWeight.w600 : null,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: fee.isOverdue 
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              fee.isOverdue ? "Overdue" : "Current",
              style: GoogleFonts.underdog(
                fontSize: 12,
                color: fee.isOverdue ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: TextFormField(
              enabled: isPayable,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: isPayable ? "0.00" : "N/A",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              style: GoogleFonts.underdog(fontSize: 12),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                setState(() {
                  if (amount > 0) {
                    _feeAllocations[fee.feeId] = amount;
                  } else {
                    _feeAllocations.remove(fee.feeId);
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(StudentFee studentFee, List<String> paymentMethods, bool isDark) {
    final totalAllocation = _feeAllocations.values.fold(0.0, (sum, amount) => sum + amount);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            "Payment Details",
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Payment Amount",
                    labelStyle: GoogleFonts.underdog(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.money, color: AppColors.success),
                    suffixText: "KSH",
                  ),
                  style: GoogleFonts.underdog(),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: "Payment Method",
                    labelStyle: GoogleFonts.underdog(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.payment, color: AppColors.primary),
                  ),
                  items: paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(
                        method,
                        style: GoogleFonts.underdog(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value ?? 'Cash';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Allocation:",
                  style: GoogleFonts.underdog(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: "Ksh").format(totalAllocation),
                  style: GoogleFonts.underdog(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProcessPayment() ? () => _processPayment(studentFee) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Process Payment",
                style: GoogleFonts.underdog(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget(Object error, bool isDark) {
    return Container(
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
            "Failed to load student fees",
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
        ],
      ),
    );
  }

  bool _canProcessPayment() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final totalAllocation = _feeAllocations.values.fold(0.0, (sum, amount) => sum + amount);
    
    return amount > 0 && 
           totalAllocation > 0 && 
           amount >= totalAllocation &&
           _feeAllocations.isNotEmpty;
  }

  void _processPayment(StudentFee studentFee) async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    // Create fee allocations
    final allocations = <FeeAllocation>[];
    for (final feeId in _feeAllocations.keys) {
      final fee = studentFee.availableFees.firstWhere((f) => f.feeId == feeId);
      final allocationAmount = _feeAllocations[feeId]!;
      allocations.add(fee.toFeeAllocation(allocationAmount));
    }
    
    final payment = Payment(
      studentId: studentFee.studentId,
      amount: amount,
      paymentDate: DateTime.now(),
      paymentMethod: _selectedPaymentMethod,
      feeAllocations: allocations,
    );
    
    final success = await ref.read(paymentProvider.notifier).processPayment(payment);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Payment processed successfully!",
            style: GoogleFonts.underdog(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Clear form
      setState(() {
        _amountController.clear();
        _feeAllocations.clear();
        _selectedPaymentMethod = 'Cash';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to process payment. Please try again.",
            style: GoogleFonts.underdog(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}