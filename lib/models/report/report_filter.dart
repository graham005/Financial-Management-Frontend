class ReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? term;
  final int? year;
  final String? gradeId;
  final String? studentId;
  final String? paymentMethod;
  final String? feeType;
  final String format; // PDF, Excel, or JSON

  ReportFilter({
    this.startDate,
    this.endDate,
    this.term,
    this.year,
    this.gradeId,
    this.studentId,
    this.paymentMethod,
    this.feeType,
    this.format = 'JSON',
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (startDate != null) params['StartDate'] = startDate!.toIso8601String();
    if (endDate != null) params['EndDate'] = endDate!.toIso8601String();
    if (term != null && term!.isNotEmpty) params['Term'] = term;
    if (year != null) params['Year'] = year;
    if (gradeId != null && gradeId!.isNotEmpty) params['GradeId'] = gradeId;
    if (studentId != null && studentId!.isNotEmpty) params['StudentId'] = studentId;
    if (paymentMethod != null && paymentMethod!.isNotEmpty) params['PaymentMethod'] = paymentMethod;
    if (feeType != null && feeType!.isNotEmpty) params['FeeType'] = feeType;
    if (format.isNotEmpty) params['Format'] = format;
    return params;
  }

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? term,
    int? year,
    String? gradeId,
    String? studentId,
    String? paymentMethod,
    String? feeType,
    String? format,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      term: term ?? this.term,
      year: year ?? this.year,
      gradeId: gradeId ?? this.gradeId,
      studentId: studentId ?? this.studentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      feeType: feeType ?? this.feeType,
      format: format ?? this.format,
    );
  }
}