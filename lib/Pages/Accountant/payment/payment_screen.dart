import 'package:finance_management_frontend/models/student_arrears.dart';
import 'package:finance_management_frontend/provider/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_colors.dart';
import '../../../provider/payment_provider.dart';
import '../../../models/student_fee.dart';
import '../../../models/payment.dart';
import '../../../widgets/side_nav_layout.dart';

class SimplePaymentScreen extends ConsumerStatefulWidget {
  final Student student;
  const SimplePaymentScreen({super.key, required this.student});

  @override
  ConsumerState<SimplePaymentScreen> createState() => _SimplePaymentScreenState();
}

class _SimplePaymentScreenState extends ConsumerState<SimplePaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  PaymentView _view = PaymentView.payment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).fetchStudentAvailableFees(widget.student.id);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentFeesAsync = ref.watch(paymentProvider);
    final paymentMethods = ref.watch(paymentMethodsProvider);

    return SideNavLayout(
      currentRoute: '',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumb(),
                const SizedBox(height: 18),
                _buildStudentHeader(isDark, studentFeesAsync),
                const SizedBox(height: 18),
                _buildViewButtons(),
                const SizedBox(height: 18),
                _buildContent(isDark, studentFeesAsync, paymentMethods),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.payments, size: 18, color: AppColors.primary),
        Text("Payments", style: GoogleFonts.underdog(fontSize: 13, color: AppColors.primary)),
        const Icon(Icons.chevron_right, size: 16),
        Text(widget.student.admissionNumber,
            style: GoogleFonts.underdog(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStudentHeader(bool isDark, AsyncValue<StudentFee?> studentFeesAsync) {
    final outstanding = studentFeesAsync.maybeWhen(
      data: (sf) => sf?.totalOutstanding ?? 0,
      orElse: () => 0.0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : '?',
              style: GoogleFonts.underdog(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.student.name,
                    style: GoogleFonts.underdog(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  "Admission: ${widget.student.admissionNumber}",
                  style: GoogleFonts.underdog(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: outstanding > 0 ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(outstanding > 0 ? "Outstanding" : "Paid Up",
                    style: GoogleFonts.underdog(
                        fontSize: 11, 
                        color: outstanding > 0 ? AppColors.error : AppColors.success, 
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: "Ksh").format(outstanding),
                  style: GoogleFonts.underdog(
                      color: outstanding > 0 ? AppColors.error : AppColors.success, 
                      fontWeight: FontWeight.w700, 
                      fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButtons() {
    Widget btn(PaymentView v, String label, IconData icon) {
      final active = _view == v;
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() => _view = v);
            if (v == PaymentView.arrears) {
              ref.refresh(studentArrearsProvider(widget.student.id));
            } else if (v == PaymentView.previous) {
              ref.refresh(studentPreviousPaymentsProvider(widget.student.id));
            }
          },
          icon: Icon(icon, size: 16),
          label: Text(label, style: GoogleFonts.underdog(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? AppColors.primary : AppColors.primary.withOpacity(0.20),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: active ? 2 : 0,
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(PaymentView.payment, "Make Payment", Icons.payments),
        const SizedBox(width: 10),
        btn(PaymentView.arrears, "Arrears", Icons.warning_amber_rounded),
        const SizedBox(width: 10),
        btn(PaymentView.previous, "History", Icons.history),
      ],
    );
  }

  Widget _buildContent(bool isDark, AsyncValue<StudentFee?> studentFeesAsync, List<String> paymentMethods) {
    switch (_view) {
      case PaymentView.arrears:
        return _buildArrearsView(isDark);
      case PaymentView.previous:
        return _buildHistoryView(isDark);
      case PaymentView.payment:
        return studentFeesAsync.when(
          data: (sf) => sf != null ? _buildSimplePaymentForm(sf, paymentMethods, isDark) : _noDataCard("No fees available"),
          loading: () => _loadingCard(),
          error: (e, _) => _errorCard(e.toString()),
        );
    }
  }

  Widget _buildSimplePaymentForm(StudentFee studentFee, List<String> paymentMethods, bool isDark) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return Column(
      children: [
        // Payment Form Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (isDark ? Colors.white10 : Colors.black12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Make Payment", style: GoogleFonts.underdog(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              
              // Amount and Payment Method Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Payment Amount",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: Icon(Icons.attach_money, color: AppColors.success),
                        suffixText: "Ksh",
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      items: paymentMethods
                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.underdog())))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPaymentMethod = v ?? 'Cash'),
                      decoration: InputDecoration(
                        labelText: "Payment Method",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: Icon(Icons.payment, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Quick Amount Buttons
              Text("Quick Amounts", style: GoogleFonts.underdog(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickAmountButton(studentFee.totalOutstanding, "Pay All Outstanding"),
                  if (studentFee.availableFees.isNotEmpty)
                    _quickAmountButton(studentFee.availableFees.first.outstandingAmount, "Pay Next Fee"),
                  _quickAmountButton(5000, "Ksh 5,000"),
                  _quickAmountButton(10000, "Ksh 10,000"),
                  _quickAmountButton(15000, "Ksh 15,000"),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Payment Preview
              if (amount > 0) _buildPaymentPreview(studentFee, amount, isDark),
              
              const SizedBox(height: 20),
              
              // Process Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: amount > 0 ? () => _processSimplePayment(studentFee, amount) : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text("Process Payment", style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Fees Summary Card
        _buildFeesSummaryCard(studentFee, isDark),
      ],
    );
  }

  Widget _quickAmountButton(double amount, String label) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _amountController.text = amount.toString();
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: GoogleFonts.underdog(fontSize: 12)),
    );
  }

  Widget _buildPaymentPreview(StudentFee studentFee, double amount, bool isDark) {
    // Auto-allocate the payment to fees based on priority (oldest overdue first)
    final allocations = _calculateAutoAllocation(studentFee, amount);
    final totalAllocated = allocations.fold(0.0, (sum, item) => sum + item['amount']);
    final remaining = amount - totalAllocated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Payment Preview", style: GoogleFonts.underdog(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          
          ...allocations.map((allocation) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "${allocation['feeType']} (${allocation['term']} ${allocation['year']})",
                    style: GoogleFonts.underdog(fontSize: 12),
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: "Ksh").format(allocation['amount']),
                  style: GoogleFonts.underdog(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )),
          
          if (remaining > 0) ...[
            const Divider(height: 16),
            Row(
              children: [
                Expanded(child: Text("Credit Balance", style: GoogleFonts.underdog(fontSize: 12, color: AppColors.success))),
                Text(
                  NumberFormat.currency(symbol: "Ksh").format(remaining),
                  style: GoogleFonts.underdog(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateAutoAllocation(StudentFee studentFee, double amount) {
    final allocations = <Map<String, dynamic>>[];
    double remainingAmount = amount;
    
    // Sort fees by priority: overdue first (oldest first), then current fees
    final sortedFees = List<AvailableFee>.from(studentFee.availableFees)
      ..sort((a, b) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
        if (a.year != b.year) return a.year.compareTo(b.year);
        final aTermNum = int.tryParse(a.term.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bTermNum = int.tryParse(b.term.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return aTermNum.compareTo(bTermNum);
      });
    
    // Allocate amount to fees in priority order
    for (final fee in sortedFees) {
      if (remainingAmount <= 0) break;
      
      final allocationAmount = remainingAmount >= fee.outstandingAmount 
          ? fee.outstandingAmount 
          : remainingAmount;
      
      if (allocationAmount > 0) {
        allocations.add({
          'feeId': fee.feeId,
          'feeType': fee.feeType,
          'term': fee.term,
          'year': fee.year,
          'amount': allocationAmount,
        });
        remainingAmount -= allocationAmount;
      }
    }
    
    return allocations;
  }

  Widget _buildFeesSummaryCard(StudentFee studentFee, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Outstanding Fees", style: GoogleFonts.underdog(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          
          ...studentFee.availableFees.where((fee) => fee.outstandingAmount > 0).map((fee) => 
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fee.isOverdue ? AppColors.error.withOpacity(0.05) : AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: fee.isOverdue ? AppColors.error.withOpacity(0.2) : AppColors.primary.withOpacity(0.2)
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fee.feeType, style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                        Text("${fee.term} ${fee.year}", style: GoogleFonts.underdog(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: "Ksh").format(fee.outstandingAmount),
                        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: fee.isOverdue ? AppColors.error : AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fee.isOverdue ? "Overdue" : "Current",
                          style: GoogleFonts.underdog(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processSimplePayment(StudentFee studentFee, double amount) async {
    // Auto-calculate allocations
    final autoAllocations = _calculateAutoAllocation(studentFee, amount);
    
    // Convert to FeeAllocation objects
    final feeAllocations = autoAllocations.map((allocation) {
      final fee = studentFee.availableFees.firstWhere((f) => f.feeId == allocation['feeId']);
      return fee.toFeeAllocation(allocation['amount'] as double);
    }).toList();

    final payment = Payment(
      studentId: studentFee.studentId,
      amount: amount,
      paymentDate: DateTime.now(),
      paymentMethod: _selectedPaymentMethod,
      feeAllocations: feeAllocations,
    );

    final success = await ref.read(paymentProvider.notifier).processPayment(payment);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Payment processed successfully!" : "Payment failed. Please try again.",
          style: GoogleFonts.underdog(),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
    
    if (success) {
      setState(() {
        _amountController.clear();
        _selectedPaymentMethod = 'Cash';
      });
    }
  }

  // Helper methods for other views (arrears, history)
  Widget _buildArrearsView(bool isDark) {
    final arrearsAsync = ref.watch(studentArrearsProvider(widget.student.id));
    return arrearsAsync.when(
      data: (arrears) => arrears != null ? _arrearsCard(arrears, isDark) : _noDataCard("No arrears data"),
      loading: _loadingCard,
      error: (e, _) => _errorCard(e.toString()),
    );
  }

  Widget _buildHistoryView(bool isDark) {
    final paymentsAsync = ref.watch(studentPreviousPaymentsProvider(widget.student.id));
    return paymentsAsync.when(
      data: (payments) => payments.isNotEmpty ? _historyCard(payments, isDark) : _noDataCard("No payment history"),
      loading: _loadingCard,
      error: (e, _) => _errorCard(e.toString()),
    );
  }

  Widget _arrearsCard(StudentArrears arrears, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Arrears Summary", style: GoogleFonts.underdog(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _infoRow("Enrollment", "${arrears.enrollmentTerm} ${arrears.enrollmentYear}"),
          _infoRow("Current Period", "${arrears.currentTerm} ${arrears.currentYear}"),
          _infoRow("Total Arrears", NumberFormat.currency(symbol: "Ksh").format(arrears.cumulativeArrears)),
          _infoRow("Status", arrears.arrearsStatus),
        ],
      ),
    );
  }

Widget _historyCard(List<Payment> payments, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Payment History (${payments.length})", style: GoogleFonts.underdog(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...payments.take(10).map((payment) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.yMMMd().add_jm().format(payment.paymentDate), 
                            style: GoogleFonts.underdog(fontWeight: FontWeight.w600)
                          ),
                          Text(
                            payment.paymentMethod, 
                            style: GoogleFonts.underdog(fontSize: 12, color: Colors.grey)
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: "Ksh").format(payment.amount),
                          style: GoogleFonts.underdog(fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                        if (payment.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(payment.status!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payment.status!,
                              style: GoogleFonts.underdog(fontSize: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Show terms if available
                if (payment.terms != null && payment.terms!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: payment.terms!.map((term) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          term,
                          style: GoogleFonts.underdog(fontSize: 10, color: AppColors.primary),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          )),
          // Show more button if there are more than 10 payments
          if (payments.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Show all payments in a dialog or navigate to detailed history
                    _showAllPayments(payments, isDark);
                  },
                  child: Text(
                    "View All ${payments.length} Payments",
                    style: GoogleFonts.underdog(color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

    Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  void _showAllPayments(List<Payment> payments, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Complete Payment History",
                    style: GoogleFonts.underdog(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.yMMMd().add_jm().format(payment.paymentDate),
                                      style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      payment.paymentMethod,
                                      style: GoogleFonts.underdog(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    NumberFormat.currency(symbol: "Ksh").format(payment.amount),
                                    style: GoogleFonts.underdog(fontWeight: FontWeight.w700, color: AppColors.success),
                                  ),
                                  if (payment.status != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(payment.status!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        payment.status!,
                                        style: GoogleFonts.underdog(fontSize: 10, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (payment.terms != null && payment.terms!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: payment.terms!.map((term) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    term,
                                    style: GoogleFonts.underdog(fontSize: 10, color: AppColors.primary),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.underdog(color: Colors.grey))),
          Text(value, style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _loadingCard() => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );

  Widget _noDataCard(String message) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(child: Text(message, style: GoogleFonts.underdog())),
  );

  Widget _errorCard(String error) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(child: Text("Error: $error", style: GoogleFonts.underdog(color: AppColors.error))),
  );
}

enum PaymentView { payment, arrears, previous }